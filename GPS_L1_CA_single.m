% ������GPS���ݴ������
% ����˫����ǰ������45s�����ߣ��������Ƿ���ȷ��������Ԥ������
% ��������ȷ�ᵼ����ķ���ʱ�䲻��ȷ��Ӱ�춨λ
% ��*�ĳ���ο��Ե�������
% ʱ�ӡ�Ƶ�ʷ�������׼ȷGPSʱ�����ж�λ
% ���ջ���ʼ����ʱ�����׼��
% ����һ��һֱ�ɼ������ǣ��õ���������������ע�͵���ͼָ��
% ʹ�öԻ���ѡ�������ļ�
% ��*�ĳ���α�ʾ���Ե������У���#�ĳ���α�ʾ��Ҫ�޸�

clear
clc

%% ѡ���ļ� (#)
default_path = fileread('.\temp\dataPath.txt'); %�����ļ�����Ĭ��·��
[file, path] = uigetfile([default_path,'\*.dat'], 'ѡ��GPS�����ļ�'); %�ļ�ѡ��Ի�������Ϊ.dat�ļ�
if file==0
    disp('Invalid file!');
    return
end
if strcmp(file(1:4),'B210')==0
    error('File error!');
end
file_path = [path, file];
plot_gnss_file(file_path); %��ʾǰ0.1s����
drawnow

%% ��ʱ��ʼ (#)
% 4������10s���ݺ�ʱԼ16s
tic

%% ������־�ļ� (#)
fclose('all'); %�ر�֮ǰ�򿪵������ļ�
result_path = fileread('.\temp\resultPath.txt'); %�洢�����·��
logID = fopen([result_path,'\log.txt'], 'w'); %������־�ļ���ʱ��˳�����־��

%% ����ʱ��
msToProcess = 300*1*1000; %������ʱ��
sample_offset = 0*4e6; %����ǰ���ٸ�������
sampleFreq = 4e6; %���ջ�����Ƶ��

%% �ο�λ��
p0 = [45.730952, 126.624970, 212]; %2A¥��

%% ���ݻ��� (#)
buffBlkNum = 40;                     %�������ݻ����������Ҫ��֤����ʱ�洢ǡ�ô�ͷ��ʼ��
buffBlkSize = 4000;                  %һ����Ĳ���������1ms��
buffSize = buffBlkSize * buffBlkNum; %�������ݻ����С
buff = zeros(2,buffSize);            %�������ݻ��棬��һ��I���ڶ���Q
buffBlkPoint = 0;                    %���ݸ����ڼ���棬��0��ʼ
buffHead = 0;                        %�������ݵ���ţ�buffBlkSize�ı���

%% ��ȡ�ļ�ʱ�� (#)
tf = sscanf(file_path((end-22):(end-8)), '%4d%02d%02d_%02d%02d%02d')'; %�����ļ���ʼ����ʱ�䣨����ʱ�����飩
[tw, ts] = gps_time(tf); %tw��GPS������ts��GPS��������
ta = [ts,0,0] + sample2dt(sample_offset, sampleFreq); %��ʼ�����ջ�ʱ�䣬[s,ms,us]
ta = time_carry(round(ta,2)); %ȡ��

%% ���������ȡ��ǰ���ܼ��������ǣ�*��
% svList = [6;12;17;19];
% svList = 24;
svList = gps_constellation(tf, p0); %��������Ϊ�˿�����
svN = length(svList);

%% Ϊÿ�ſ��ܼ��������Ƿ������ͨ�� (#)
channels = repmat(GPS_L1_CA_channel_struct(), svN,1); %ֻ�����˳���������Ϣ��Ϊ��
for k=1:svN
    channels(k).PRN = svList(k); %ÿ��ͨ�������Ǻ�
    channels(k).state = 0; %״̬δ����
end

%% Ԥ������ (#)
ephemeris_file = ['.\temp\ephemeris\',file_path((end-22):(end-8)),'.mat'];
if exist(ephemeris_file, 'file')
    load(ephemeris_file); %�������ڣ����������ļ�������������Ϊephemeris������Ϊ�У���������������Ϊion
else
    ephemeris = NaN(26,32); %���������ڣ����ÿյ�����
    ion = NaN(1,8); %�յĵ�������
end
for k=1:svN
    PRN = svList(k);
    channels(k).ephemeris = ephemeris(:,PRN); %Ϊͨ����������ֵ
    if ~isnan(ephemeris(1,PRN)) %�������ĳ�����ǵ���������ӡ��־
        fprintf(logID, '%2d: Load ephemeris.\r\n', PRN); %�᷵���ֽ���
    end
end

%% �������ٽ���洢�ռ� (#)
% ������msToProcess�У�ÿ����һ�����һ�ν�������ɾ���������
trackResults = repmat(trackResult_struct(msToProcess), svN,1);
for k=1:svN
    trackResults(k).PRN = svList(k);
end

%% ���ջ�״̬
receiverState = 0; %���ջ�״̬��0��ʾδ��ʼ����ʱ�仹���ԣ�1��ʾʱ���Ѿ�У��
deltaFreq = 0; %ʱ�Ӳ���Ϊ�ٷֱȣ������1e-9������1500e6Hz�Ĳ����1.5Hz
dtpos = 10; %��λʱ������ms
tp = [ta(1),0,0]; %tpΪ�´ζ�λʱ��
tp(2) = (floor(ta(2)/dtpos)+1) * dtpos; %�ӵ��¸���Ŀ��ʱ��
tp = time_carry(tp); %��λ
pos = NaN(1,8); %��λ�������������ʱ���õ�

%% �������ջ�����洢�ռ�
% ����msToProcess/dtpos�У�ÿ��ʱ������һ�Σ������ݽ��ջ�״̬ɾ���������
nRow = msToProcess/dtpos;
no = 1; %ָ��ǰ�洢��
output_ta  = zeros(nRow,2); %��һ��Ϊʱ�䣨s�����ڶ���Ϊ���ջ�״̬
output_pos = zeros(nRow,8); %��λ��[λ�á��ٶȡ��Ӳ��Ƶ��]
output_sv  = zeros(svN,8,nRow); %������Ϣ��[λ�á�α�ࡢ�ٶȡ�α����]
output_df  = zeros(nRow,1); %�����õ���Ƶ��˲������Ƶ�

%% ���ļ������������� (#)
fileID = fopen(file_path, 'r');
fseek(fileID, round(sample_offset*4), 'bof'); %��ȡ�����ܳ����ļ�ָ���Ʋ���ȥ
if int64(ftell(fileID))~=int64(sample_offset*4)
    error('Sample offset error!');
end
f = waitbar(0, ['0s/',num2str(msToProcess/1000),'s']);

%% �źŴ���
for t=1:msToProcess %�����ϵ�ʱ�䣬�Բ�����������
    %% ���½����� (#)
    if mod(t,1000)==0 %1s����
        waitbar(t/msToProcess, f, [num2str(t/1000),'s/',num2str(msToProcess/1000),'s']);
    end
    
    %% �����ݣ�ÿ10s������1.2s��(#)
    buff(:,buffBlkPoint*buffBlkSize+(1:buffBlkSize)) = double(fread(fileID, [2,buffBlkSize], 'int16')); %ȡ���ݣ������������������
    buffBlkPoint = buffBlkPoint + 1;
    buffHead = buffBlkPoint * buffBlkSize;
    if buffBlkPoint==buffBlkNum
        buffBlkPoint = 0; %�����ͷ��ʼ
    end
    
	%% ���½��ջ�ʱ��
    % ��ǰ���һ�������Ľ��ջ�ʱ��
    sampleFreq_real = sampleFreq * (1+deltaFreq); %��ʵ�Ĳ���Ƶ��
    ta = time_carry(ta + sample2dt(buffBlkSize, sampleFreq_real));
    
    %% ���� (#)
    % ÿ1s�Ĳ���������һ��
    if mod(t,1000)==0
        for k=1:svN %�������п��ܼ���������
            if channels(k).state==0 %���ͨ��δ��������Լ���
                [acqResult, peakRatio] = GPS_L1_CA_acq_one(svList(k), buff(:,(end-2*8000+1):end)); %2ms���ݲ���
                if ~isempty(acqResult) %�ɹ�����
                    channels(k) = GPS_L1_CA_channel_init(channels(k), acqResult, t*buffBlkSize, sampleFreq); %����ͨ��
                    fprintf(logID, '%2d: Acquired at %ds, peakRatio=%.2f\r\n', svList(k), t/1000, peakRatio); %��ӡ������־
                end
            end
        end
    end
    
    %% ���� (#)
    for k=1:svN %��k��ͨ��
        if channels(k).state~=0 %���ͨ��������и���
            while 1
                % �ж��Ƿ��������ĸ�������
                if mod(buffHead-channels(k).trackDataHead,buffSize)>(buffSize/2)
                    break
                end
                % ����ٽ����ͨ��������
                n = trackResults(k).n;
                trackResults(k).dataIndex(n,:)    = channels(k).dataIndex;
                trackResults(k).ts0(n,:)          = channels(k).ts0;
                trackResults(k).remCodePhase(n,:) = channels(k).remCodePhase;
                trackResults(k).codeFreq(n,:)     = channels(k).codeFreq;
                trackResults(k).remCarrPhase(n,:) = channels(k).remCarrPhase;
                trackResults(k).carrFreq(n,:)     = channels(k).carrFreq;
                % ��������
                trackDataHead = channels(k).trackDataHead;
                trackDataTail = channels(k).trackDataTail;
                if trackDataHead>trackDataTail
                    [channels(k), I_Q, disc, bitStartFlag] = ...
                        GPS_L1_CA_track(channels(k), sampleFreq_real, buffSize, buff(:,trackDataTail:trackDataHead), logID); %����Ƶ���е���Ӱ��
                else
                    [channels(k), I_Q, disc, bitStartFlag] = ...
                        GPS_L1_CA_track(channels(k), sampleFreq_real, buffSize, [buff(:,trackDataTail:end),buff(:,1:trackDataHead)], logID);
                end
                % ����ٽ�������ٽ����
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
    
    %% ����Ƿ񵽴ﶨλʱ��
    dtp = (ta(1)-tp(1)) + (ta(2)-tp(2))/1e3 + (ta(3)-tp(3))/1e6; %��ǰ����ʱ���붨λʱ��֮�>=0ʱ��ʾ��ǰ����ʱ���Ѿ�����򳬹���λʱ��
    
    %% ��λʱ���ѵ���
    if dtp>=0
        %% 1.��������λ�á��ٶȣ�����α�ࡢα����
        sv = NaN(svN,8);
        for k=1:svN
            if channels(k).state==2 && channels(k).CN0>35 %��һ��ǿ�Ȳ���
                dn = mod(buffHead-channels(k).trackDataTail+1, buffSize) - 1; %trackDataTailǡ�ó�ǰbuffHeadһ��ʱ��dn=-1
                dtc = dn / sampleFreq_real; %��ǰ����ʱ������ٵ��ʱ���
                dt = dtc - dtp; %��λ�㵽���ٵ��ʱ���
                carrFreq = channels(k).carrFreq + 1575.42e6*deltaFreq; %��������ز�Ƶ��
                codeFreq = (carrFreq/1575.42e6+1)*1.023e6; %ͨ���ز�Ƶ�ʼ������Ƶ��
                codePhase = channels(k).remCodePhase + dt*codeFreq; %��λ������λ
                ts0 = [floor(channels(k).ts0/1e3), mod(channels(k).ts0,1e3), 0] + [0, floor(codePhase/1023), mod(codePhase/1023,1)*1e3]; %��λ����뷢��ʱ��
                [sv(k,:),~] = sv_ecef(channels(k).ephemeris, tp, ts0); %����������������[λ�á�α�ࡢ�ٶ�]
                sv(k,8) = -carrFreq/1575.42e6*299792458;%�ز�Ƶ��ת��Ϊ�ٶ�
                sv(k,8) = sv(k,8) + channels(k).ephemeris(9)*299792458; %��������Ƶ������ӿ���α����ƫС
                % ������ӳ�У��
                if ~isnan(ion(1)) %���ڵ�������
                    if receiverState==1 && ~isnan(pos(1)) %�ж�λ��Ϣ��ʵ��������һ��λʱ��
                        p_ecef = lla2ecef(pos(1:3)); %���ջ�λ��
                        Cen = dcmecef2ned(pos(1),pos(2));
                        rps = sv(k,1:3) - p_ecef; %���ջ�ָ�����ߵ�ʸ����ecef
                        rps = rps * Cen'; %����ϵ
                        rpsu = rps / norm(rps); %��λʸ��
                        ele = -asind(rpsu(3)); %���Ǹ߶Ƚǣ�deg
                        azi = atan2d(rpsu(2),rpsu(1)); %���Ƿ�λ�ǣ�deg���ӱ�˳ʱ��Ϊ��
                        tiono = Klobuchar_iono(ion, ele, azi, pos(1), pos(2), tp(1)+tp(2)/1e3+tp(3)/1e6); %����������ʱ
                        sv(k,4) = sv(k,4) - tiono*299792458; %����α��
                    end
                end
            end
        end
        
        %% 2.��λ
        pos = pos_solve(sv(~isnan(sv(:,1)),:)); %��ȡ�ɼ����Ƕ�λ���������4�����Ƿ���8��NaN
        
        %% 3.ʱ�ӷ�������
        if receiverState==1 && ~isnan(pos(7)) %���ջ�����ɳ�ʼ�����ӲΪNaN
            % Ҫ��֤��Ƶ����������Ƶ��Ҫ���ڻ�·����
            deltaFreq = deltaFreq + 10*pos(8)*dtpos/1000; %��Ƶ���ۼ�
            ta = ta - sec2smu(10*pos(7)*dtpos/1000); %ʱ�����������Բ��ý�λ�����´θ���ʱ��λ��
        end
        
        %% 4.�洢���
        output_ta(no,1)   = tp(1) + tp(2)/1e3 + tp(3)/1e6; %ʱ�����s
        output_ta(no,2)   = receiverState; %���ջ�״̬
        output_pos(no,:)  = pos;
        output_sv(:,:,no) = sv;
        output_df(no)     = deltaFreq;
        
        %% 5.����ʼ��
        if receiverState==0 && ~isnan(pos(7))
            if abs(pos(7))>0.1e-3 %�Ӳ����0.1ms���������ջ�ʱ��
                ta = ta - sec2smu(pos(7)); %ʱ������
                ta = time_carry(ta);
                tp(1) = ta(1); %�����´ζ�λʱ��
                tp(2) = (floor(ta(2)/dtpos)+1) * dtpos;
                tp = time_carry(tp);
            else %�Ӳ�С��0.1ms����ʼ������
                receiverState = 1;
            end
        end
        
        %% 6.�����´ζ�λʱ��
        tp = time_carry(tp + [0,dtpos,0]);
        no = no + 1; %ָ����һ�洢λ��
    end
    
end

%% �ر��ļ����رս����� (#)
fclose(fileID);
fclose(logID);
close(f);

%% ɾ���հ����� (#)
for k=1:svN
    trackResults(k) = trackResult_clean(trackResults(k));
end
output_ta(no:end,:)   = [];
output_pos(no:end,:)  = [];
output_sv(:,:,no:end) = [];
output_df(no:end,:)   = [];
% ɾ�����ջ�δ��ʼ��ʱ������
index = find(output_ta(:,2)==0);
output_ta(index,:)    = [];
output_pos(index,:)   = [];
output_sv(:,:,index)  = [];
output_df(index,:)    = [];

%% ��ӡͨ����־��*��
clc
print_log([result_path,'\log.txt'], svList);

%% �������� (#)
% ÿ�������궼�ᱣ�棬���������Զ����
for k=1:svN
    PRN = channels(k).PRN;
    if ~isnan(channels(k).ephemeris(1)) && isnan(ephemeris(1,PRN)) %ͨ���������������������ļ���û��
        ephemeris(:,PRN) = channels(k).ephemeris; %��������
    end
end
save(ephemeris_file, 'ephemeris', 'ion');

%% ��ͼ��*��
for k=1:svN
    if trackResults(k).n==1 %����û���ٵ�ͨ��
        continue
    end
    
    % ����������
    screenSize = get(0,'ScreenSize'); %��ȡ��Ļ�ߴ�
    if screenSize(3)==1920 %������Ļ�ߴ����û�ͼ��Χ
        figure('Position', [390, 280, 1140, 670]);
    elseif screenSize(3)==1368 %SURFACE
        figure('Position', [114, 100, 1140, 670]);
    elseif screenSize(3)==1440 %С��Ļ
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
    
    % ��ͼ
    plot(ax1, trackResults(k).I_Q(1001:end,1),trackResults(k).I_Q(1001:end,4), 'LineStyle','none', 'Marker','.') %I/Qͼ
    plot(ax2, trackResults(k).dataIndex/sampleFreq, trackResults(k).I_Q(:,1)) %I_Pͼ
    index = find(trackResults(k).CN0(:,1)~=0);
    plot(ax3, trackResults(k).dataIndex(index)/sampleFreq, trackResults(k).CN0(index,1), 'LineWidth',2) %����ȣ�ֻ����Ϊ0��
    plot(ax4, trackResults(k).dataIndex/sampleFreq, trackResults(k).carrFreq, 'LineWidth',1.5) %�ز�Ƶ��
    plot(ax5, trackResults(k).dataIndex/sampleFreq, trackResults(k).carrAcc) %���߷�����ٶ�
    
%     index = find(trackResults(k).bitStartFlag==double('H')); %Ѱ��֡ͷ�׶Σ���ɫ��
%     plot(ax2, trackResults(k).dataIndex(index)/sampleFreq, trackResults(k).I_Q(index,1), 'LineStyle','none', 'Marker','.', 'Color','m')
%     index = find(trackResults(k).bitStartFlag==double('C')); %У��֡ͷ�׶Σ���ɫ��
%     plot(ax2, trackResults(k).dataIndex(index)/sampleFreq, trackResults(k).I_Q(index,1), 'LineStyle','none', 'Marker','.', 'Color','b')
%     index = find(trackResults(k).bitStartFlag==double('E')); %���������׶Σ���ɫ��
%     plot(ax2, trackResults(k).dataIndex(index)/sampleFreq, trackResults(k).I_Q(index,1), 'LineStyle','none', 'Marker','.', 'Color','r')
    
    % ����������
    set(ax2, 'XLim',[0,msToProcess/1000])
    set(ax3, 'XLim',[0,msToProcess/1000])
    set(ax3, 'YLim',[30,60]) %�������ʾ��Χ��Ϊ�˺ÿ�
    set(ax4, 'XLim',[0,msToProcess/1000])
    set(ax5, 'XLim',[0,msToProcess/1000])
end

clearvars k screenSize ax1 ax2 ax3 ax4 ax5 index

%% ���������*��
keepVariables = { ...
'sampleFreq'; 'msToProcess';
'p0'; 'tf'; 'svList'; 'svN'; %Ϊ�˻�����ͼ
'channels'; 'trackResults'; %���߸�����Ϣ
'ephemeris'; 'ion'; %����
'output_ta'; 'output_pos'; 'output_sv'; 'output_df'; 
'file';
};
clearvars('-except', keepVariables{:})

%% ������ (#)
% ��ʱ������
t0 = clock;
time_str = sprintf('%4d%02d%02d_%02d%02d%02d', t0(1),t0(2),t0(3),t0(4),t0(5),floor(t0(6)));
result_path = fileread('.\temp\resultPath.txt');
save([result_path,'\',time_str,'__single__',file(1:end-8),'.mat'])

%% ��ʱ���� (#)
toc