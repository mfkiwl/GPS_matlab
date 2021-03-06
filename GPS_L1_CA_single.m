% 单天线GPS数据处理程序
% 运行双天线前先运行45s单天线，看星历是否正确，还可以预置星历
% 星历不正确会导致码的发射时间不正确，影响定位
% 标*的程序段可以单独运行
% 时钟、频率反馈，在准确GPS时间点进行定位
% 接收机初始化后时间才是准的
% 处理一颗一直可见的卫星，得到电离层参数，可以注释掉画图指令
% 使用对话框选择数据文件
% 标*的程序段表示可以单独运行，标#的程序段表示不要修改

clear
clc

%% 选择文件 (#)
default_path = fileread('.\temp\dataPath.txt'); %数据文件所在默认路径
[file, path] = uigetfile([default_path,'\*.dat'], '选择GPS数据文件'); %文件选择对话框，限制为.dat文件
if file==0
    disp('Invalid file!');
    return
end
if strcmp(file(1:4),'B210')==0
    error('File error!');
end
file_path = [path, file];
plot_gnss_file(file_path); %显示前0.1s数据
drawnow

%% 计时开始 (#)
% 4颗卫星10s数据耗时约16s
tic

%% 创建日志文件 (#)
fclose('all'); %关闭之前打开的所有文件
result_path = fileread('.\temp\resultPath.txt'); %存储结果的路径
logID = fopen([result_path,'\log.txt'], 'w'); %创建日志文件（时间顺序的日志）

%% 运行时间
msToProcess = 30*1*1000; %处理总时间
sample_offset = 0*4e6; %抛弃前多少个采样点
sampleFreq = 4e6; %接收机采样频率

%% 参考位置
p0 = [45.730952, 126.624970, 212]; %2A楼顶

%% 数据缓存 (#)
buffBlkNum = 40;                     %采样数据缓存块数量（要保证捕获时存储恰好从头开始）
buffBlkSize = 4000;                  %一个块的采样点数（1ms）
buffSize = buffBlkSize * buffBlkNum; %采样数据缓存大小
buff = zeros(2,buffSize);            %采样数据缓存，第一行I，第二行Q
buffBlkPoint = 0;                    %数据该往第几块存，从0开始
buffHead = 0;                        %最新数据的序号，buffBlkSize的倍数

%% 获取文件时间 (#)
tf = sscanf(file_path((end-22):(end-8)), '%4d%02d%02d_%02d%02d%02d')'; %数据文件开始采样时间（日期时间数组）
[tw, ts] = gps_time(tf); %tw：GPS周数，ts：GPS周内秒数
ta = [ts,0,0] + sample2dt(sample_offset, sampleFreq); %初始化接收机时间，[s,ms,us]
ta = time_carry(round(ta,2)); %取整

%% 根据历书获取当前可能见到的卫星（*）
% svList = [6;12;17;19];
% svList = 24;
svList = gps_constellation(tf, p0); %列向量，为了看方便
svN = length(svList);

%% 为每颗可能见到的卫星分配跟踪通道 (#)
channels = repmat(GPS_L1_CA_channel_struct(), svN,1); %只分配了场，所有信息都为空
for k=1:svN
    channels(k).PRN = svList(k); %每个通道的卫星号
    channels(k).state = 0; %状态未激活
end

%% 预置星历 (#)
ephemeris_file = ['.\temp\ephemeris\',file_path((end-22):(end-8)),'.mat'];
if exist(ephemeris_file, 'file')
    load(ephemeris_file); %星历存在，加载星历文件，星历变量名为ephemeris，星历为列；电离层参数变量名为ion
else
    ephemeris = NaN(26,32); %星历不存在，设置空的星历
    ion = NaN(1,8); %空的电离层参数
end
for k=1:svN
    PRN = svList(k);
    channels(k).ephemeris = ephemeris(:,PRN); %为通道的星历赋值
    if ~isnan(ephemeris(1,PRN)) %如果存在某颗卫星的星历，打印日志
        fprintf(logID, '%2d: Load ephemeris.\r\n', PRN); %会返回字节数
    end
end

%% 创建跟踪结果存储空间 (#)
% 分配了msToProcess行，每跟踪一次输出一次结果，最后删除多余的行
trackResults = repmat(trackResult_struct(msToProcess), svN,1);
for k=1:svN
    trackResults(k).PRN = svList(k);
end

%% 接收机状态
receiverState = 0; %接收机状态，0表示未初始化，时间还不对，1表示时间已经校正
deltaFreq = 0; %时钟差，理解为百分比，如果差1e-9，生成1500e6Hz的波会差1.5Hz
dtpos = 10; %定位时间间隔，ms
tp = [ta(1),0,0]; %tp为下次定位时间
tp(2) = (floor(ta(2)/dtpos)+1) * dtpos; %加到下个整目标时间
tp = time_carry(tp); %进位
pos = NaN(1,8); %定位结果，计算电离层时会用到

%% 创建接收机输出存储空间
% 分配msToProcess/dtpos行，每到时间点输出一次，最后根据接收机状态删除多余的行
nRow = msToProcess/dtpos;
no = 1; %指向当前存储行
output_ta  = zeros(nRow,2); %第一列为时间（s），第二列为接收机状态
output_pos = zeros(nRow,8); %定位，[位置、速度、钟差、钟频差]
output_sv  = zeros(svN,8,nRow); %卫星信息，[位置、伪距、速度、伪距率]
output_df  = zeros(nRow,1); %修正用的钟频差（滤波后的钟频差）

%% 打开文件，创建进度条 (#)
fileID = fopen(file_path, 'r');
fseek(fileID, round(sample_offset*4), 'bof'); %不取整可能出现文件指针移不过去
if int64(ftell(fileID))~=int64(sample_offset*4)
    error('Sample offset error!');
end
f = waitbar(0, ['0s/',num2str(msToProcess/1000),'s']);

%% 信号处理
for t=1:msToProcess %名义上的时间，以采样点数计算
    %% 更新进度条 (#)
    if mod(t,1000)==0 %1s步进
        waitbar(t/msToProcess, f, [num2str(t/1000),'s/',num2str(msToProcess/1000),'s']);
    end
    
    %% 读数据（每10s数据用1.2s）(#)
    buff(:,buffBlkPoint*buffBlkSize+(1:buffBlkSize)) = double(fread(fileID, [2,buffBlkSize], 'int16')); %取数据，行向量，往缓存里放
    buffBlkPoint = buffBlkPoint + 1;
    buffHead = buffBlkPoint * buffBlkSize;
    if buffBlkPoint==buffBlkNum
        buffBlkPoint = 0; %缓存从头开始
    end
    
	%% 更新接收机时间
    % 当前最后一个采样的接收机时间
    sampleFreq_real = sampleFreq * (1+deltaFreq); %真实的采样频率
    ta = time_carry(ta + sample2dt(buffBlkSize, sampleFreq_real));
    
    %% 捕获 (#)
    % 每1s的采样点搜索一次
    if mod(t,1000)==0
        for k=1:svN %搜索所有可能见到的卫星
            if channels(k).state==0 %如果通道未激活，捕获尝试激活
                [acqResult, peakRatio] = GPS_L1_CA_acq_one(svList(k), buff(:,(end-2*8000+1):end)); %2ms数据捕获
                if ~isempty(acqResult) %成功捕获
                    channels(k) = GPS_L1_CA_channel_init(channels(k), acqResult, t*buffBlkSize, sampleFreq); %激活通道
                    fprintf(logID, '%2d: Acquired at %ds, peakRatio=%.2f\r\n', svList(k), t/1000, peakRatio); %打印捕获日志
                end
            end
        end
    end
    
    %% 跟踪 (#)
    for k=1:svN %第k个通道
        if channels(k).state~=0 %如果通道激活，进行跟踪
            while 1
                % 判断是否有完整的跟踪数据
                if mod(buffHead-channels(k).trackDataHead,buffSize)>(buffSize/2)
                    break
                end
                % 存跟踪结果（通道参数）
                n = trackResults(k).n;
                trackResults(k).dataIndex(n,:)    = channels(k).dataIndex;
                trackResults(k).ts0(n,:)          = channels(k).ts0;
                trackResults(k).remCodePhase(n,:) = channels(k).remCodePhase;
                trackResults(k).codeFreq(n,:)     = channels(k).codeFreq;
                trackResults(k).remCarrPhase(n,:) = channels(k).remCarrPhase;
                trackResults(k).carrFreq(n,:)     = channels(k).carrFreq;
                % 基带处理
                trackDataHead = channels(k).trackDataHead;
                trackDataTail = channels(k).trackDataTail;
                if trackDataHead>trackDataTail
                    [channels(k), I_Q, disc, bitStartFlag] = ...
                        GPS_L1_CA_track(channels(k), sampleFreq_real, buffSize, buff(:,trackDataTail:trackDataHead), logID); %采样频率有点误差不影响
                else
                    [channels(k), I_Q, disc, bitStartFlag] = ...
                        GPS_L1_CA_track(channels(k), sampleFreq_real, buffSize, [buff(:,trackDataTail:end),buff(:,1:trackDataHead)], logID);
                end
                % 存跟踪结果（跟踪结果）
                trackResults(k).I_Q(n,:)          = I_Q;
                trackResults(k).disc(n,:)         = disc;
                trackResults(k).bitStartFlag(n,:) = bitStartFlag;
                trackResults(k).CN0(n,1)          = channels(k).CN0;
                trackResults(k).CN0(n,2)          = channels(k).CN0i;
                trackResults(k).carrAcc(n,:)      = channels(k).carrAcc;
                trackResults(k).strength(n,:)     = channels(k).strength;
                trackResults(k).n                 = n + 1;
            end
        end
    end
    
    %% 检查是否到达定位时间
    dtp = (ta(1)-tp(1)) + (ta(2)-tp(2))/1e3 + (ta(3)-tp(3))/1e6; %当前采样时间与定位时间之差，>=0时表示当前采样时间已经到达或超过定位时间
    
    %% 定位时间已到达
    if dtp>=0
        %% 1.计算卫星位置、速度，测量伪距、伪距率
        sv = NaN(svN,8);
        for k=1:svN
            if channels(k).state==2 && channels(k).CN0>35 %有一定强度才算
                dn = mod(buffHead-channels(k).trackDataTail+1, buffSize) - 1; %trackDataTail恰好超前buffHead一个时，dn=-1
                dtc = dn / sampleFreq_real; %当前采样时间与跟踪点的时间差
                dt = dtc - dtp; %定位点到跟踪点的时间差
                carrFreq = channels(k).carrFreq + 1575.42e6*deltaFreq; %修正后的载波频率
                codeFreq = (carrFreq/1575.42e6+1)*1.023e6; %通过载波频率计算的码频率
                codePhase = channels(k).remCodePhase + dt*codeFreq; %定位点码相位
                ts0 = [floor(channels(k).ts0/1e3), mod(channels(k).ts0,1e3), 0] + [0, floor(codePhase/1023), mod(codePhase/1023,1)*1e3]; %定位点的码发射时间
                [sv(k,:),~] = sv_ecef(channels(k).ephemeris, tp, ts0); %根据星历计算卫星[位置、伪距、速度]
                sv(k,8) = -carrFreq/1575.42e6*299792458;%载波频率转化为速度
                sv(k,8) = sv(k,8) + channels(k).ephemeris(9)*299792458; %修卫星钟频差，卫星钟快测的伪距率偏小
                % 电离层延迟校正
                if ~isnan(ion(1)) %存在电离层参数
                    if receiverState==1 && ~isnan(pos(1)) %有定位信息，实际上是上一定位时刻
                        p_ecef = lla2ecef(pos(1:3)); %接收机位置
                        Cen = dcmecef2ned(pos(1),pos(2));
                        rps = sv(k,1:3) - p_ecef; %接收机指向天线的矢量，ecef
                        rps = rps * Cen'; %地理系
                        rpsu = rps / norm(rps); %单位矢量
                        ele = -asind(rpsu(3)); %卫星高度角，deg
                        azi = atan2d(rpsu(2),rpsu(1)); %卫星方位角，deg，从北顺时针为正
                        tiono = Klobuchar_iono(ion, ele, azi, pos(1), pos(2), tp(1)+tp(2)/1e3+tp(3)/1e6); %计算电离层延时
                        sv(k,4) = sv(k,4) - tiono*299792458; %修正伪距
                    end
                end
            end
        end
        
        %% 2.定位
        pos = pos_solve(sv(~isnan(sv(:,1)),:)); %提取可见卫星定位，如果不够4颗卫星返回8个NaN
        
        %% 3.时钟反馈修正
        if receiverState==1 && ~isnan(pos(7)) %接收机已完成初始化且钟差不为NaN
            % 要保证高频修正，采样频率要大于环路带宽
            deltaFreq = deltaFreq + 10*pos(8)*dtpos/1000; %钟频差累加
            ta = ta - sec2smu(10*pos(7)*dtpos/1000); %时钟修正（可以不用进位，在下次更新时进位）
        end
        
        %% 4.存储输出
        output_ta(no,1)   = tp(1) + tp(2)/1e3 + tp(3)/1e6; %时间戳，s
        output_ta(no,2)   = receiverState; %接收机状态
        output_pos(no,:)  = pos;
        output_sv(:,:,no) = sv;
        output_df(no)     = deltaFreq;
        
        %% 5.检查初始化
        if receiverState==0 && ~isnan(pos(7))
            if abs(pos(7))>0.1e-3 %钟差大于0.1ms，修正接收机时间
                ta = ta - sec2smu(pos(7)); %时钟修正
                ta = time_carry(ta);
                tp(1) = ta(1); %更新下次定位时间
                tp(2) = (floor(ta(2)/dtpos)+1) * dtpos;
                tp = time_carry(tp);
            else %钟差小于0.1ms，初始化结束
                receiverState = 1;
            end
        end
        
        %% 6.更新下次定位时间
        tp = time_carry(tp + [0,dtpos,0]);
        no = no + 1; %指向下一存储位置
    end
    
end

%% 关闭文件，关闭进度条 (#)
fclose(fileID);
fclose(logID);
close(f);

%% 删除空白数据 (#)
for k=1:svN
    trackResults(k) = trackResult_clean(trackResults(k));
end
output_ta(no:end,:)   = [];
output_pos(no:end,:)  = [];
output_sv(:,:,no:end) = [];
output_df(no:end,:)   = [];
% 删除接收机未初始化时的数据
index = find(output_ta(:,2)==0);
output_ta(index,:)    = [];
output_pos(index,:)   = [];
output_sv(:,:,index)  = [];
output_df(index,:)    = [];

%% 打印通道日志（*）
clc
print_log([result_path,'\log.txt'], svList);

%% 保存星历 (#)
% 每次运行完都会保存，有新星历自动添加
for k=1:svN
    PRN = channels(k).PRN;
    if ~isnan(channels(k).ephemeris(1)) && isnan(ephemeris(1,PRN)) %通道内有星历，并且星历文件中没有
        ephemeris(:,PRN) = channels(k).ephemeris; %插入星历
    end
end
save(ephemeris_file, 'ephemeris', 'ion');

%% 画图（*）
for k=1:svN
    if trackResults(k).n==1 %不画没跟踪的通道
        continue
    end
    
    % 建立坐标轴
    screenSize = get(0,'ScreenSize'); %获取屏幕尺寸
    if screenSize(3)==1920 %根据屏幕尺寸设置画图范围
        figure('Position', [390, 280, 1140, 670]);
    elseif screenSize(3)==1368 %SURFACE
        figure('Position', [114, 100, 1140, 670]);
    elseif screenSize(3)==1440 %小屏幕
        figure('Position', [150, 100, 1140, 670]);
    elseif screenSize(3)==1600 %T430
        figure('Position', [230, 100, 1140, 670]);
    else
        error('Screen size error!')
    end
    ax1 = axes('Position', [0.08, 0.4, 0.38, 0.53]);
    hold(ax1,'on');
    axis(ax1, 'equal');
    title(['PRN = ',num2str(svList(k))])
    ax2 = axes('Position', [0.53, 0.7 , 0.42, 0.25]);
    hold(ax2,'on');
    ax3 = axes('Position', [0.53, 0.38, 0.42, 0.25]);
    hold(ax3,'on');
    grid(ax3,'on');
    ax4 = axes('Position', [0.53, 0.06, 0.42, 0.25]);
    hold(ax4,'on');
    grid(ax4,'on');
    ax5 = axes('Position', [0.05, 0.06, 0.42, 0.25]);
    hold(ax5,'on');
    grid(ax5,'on');
    
    % 画图
    plot(ax1, trackResults(k).I_Q(1001:end,1),trackResults(k).I_Q(1001:end,4), 'LineStyle','none', 'Marker','.') %I/Q图
    plot(ax2, trackResults(k).dataIndex/sampleFreq, trackResults(k).I_Q(:,1)) %I_P图
    index = find(trackResults(k).CN0(:,1)~=0);
    plot(ax3, trackResults(k).dataIndex(index)/sampleFreq, trackResults(k).CN0(index,1), 'LineWidth',2) %载噪比，只画不为0的
    plot(ax4, trackResults(k).dataIndex/sampleFreq, trackResults(k).carrFreq, 'LineWidth',1.5) %载波频率
    plot(ax5, trackResults(k).dataIndex/sampleFreq, trackResults(k).carrAcc) %视线方向加速度
    
%     index = find(trackResults(k).bitStartFlag==double('H')); %寻找帧头阶段（粉色）
%     plot(ax2, trackResults(k).dataIndex(index)/sampleFreq, trackResults(k).I_Q(index,1), 'LineStyle','none', 'Marker','.', 'Color','m')
%     index = find(trackResults(k).bitStartFlag==double('C')); %校验帧头阶段（蓝色）
%     plot(ax2, trackResults(k).dataIndex(index)/sampleFreq, trackResults(k).I_Q(index,1), 'LineStyle','none', 'Marker','.', 'Color','b')
%     index = find(trackResults(k).bitStartFlag==double('E')); %解析星历阶段（红色）
%     plot(ax2, trackResults(k).dataIndex(index)/sampleFreq, trackResults(k).I_Q(index,1), 'LineStyle','none', 'Marker','.', 'Color','r')
    
    % 调整坐标轴
    set(ax2, 'XLim',[0,msToProcess/1000])
    set(ax3, 'XLim',[0,msToProcess/1000])
    set(ax3, 'YLim',[30,60]) %载噪比显示范围，为了好看
    set(ax4, 'XLim',[0,msToProcess/1000])
    set(ax5, 'XLim',[0,msToProcess/1000])
end

clearvars k screenSize ax1 ax2 ax3 ax4 ax5 index

%% 清除变量（*）
keepVariables = { ...
'sampleFreq'; 'msToProcess';
'p0'; 'tf'; 'svList'; 'svN'; %为了画星座图
'channels'; 'trackResults'; %天线跟踪信息
'ephemeris'; 'ion'; %星历
'output_ta'; 'output_pos'; 'output_sv'; 'output_df'; 
'file';
};
clearvars('-except', keepVariables{:})

%% 保存结果 (#)
% 以时间命名
t0 = clock;
time_str = sprintf('%4d%02d%02d_%02d%02d%02d', t0(1),t0(2),t0(3),t0(4),t0(5),floor(t0(6)));
result_path = fileread('.\temp\resultPath.txt');
save([result_path,'\',time_str,'__single__',file(1:end-8),'.mat'])

%% 计时结束 (#)
toc