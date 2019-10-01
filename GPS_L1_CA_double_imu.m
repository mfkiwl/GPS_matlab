% GPS˫�����źŴ������
% ��GPS_L1_CA_double.m�����ϸ�
% ����������֤����ϵ����˲���
% �������ź����������²ɼ�����ֹ��С��Χ�ƶ���
% ����IMU���ݣ���IMUʱ������������Ϣ����
% ���ջ�ʱ�ӿ�����ͨ�������˲�������ʱ�����
% ֻ����λ�������������̬���㣬��λ�������ģ����
% ��*�ĳ���α�ʾ���Ե������У���#�ĳ���α�ʾ��Ҫ�޸�
% ��Ч����δ��ǿ���жϣ�ֻҪ����2״̬���ã���λ�ת��inverseFlag��־
% 0726������֤ͨ��

clear
clc

%% IMU���� (#)
imu_data = IMU_parse();
close gcf
close gcf
close gcf

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
file_path_A = [file_path(1:end-5),'1.dat'];
file_path_B = [file_path(1:end-5),'2.dat'];
plot_gnss_file(file_path_A); %��ʾǰ0.1s����
plot_gnss_file(file_path_B);
drawnow

%% ��ʱ��ʼ (#)
tic

%% ������־�ļ� (#)
fclose('all'); %�ر�֮ǰ�򿪵������ļ�
result_path = fileread('.\temp\resultPath.txt'); %�洢�����·��
logID_A = fopen([result_path,'\logA.txt'], 'w'); %������־�ļ���ʱ��˳�����־��
logID_B = fopen([result_path,'\logB.txt'], 'w');

%% ����ʱ��
msToProcess = 60*5*1000; %������ʱ��
sample_offset = 0*4e6; %����ǰ���ٸ�������
sampleFreq = 4e6; %���ջ�����Ƶ��

%% �ο�λ��
p0 = [45.730952, 126.624970, 212]; %2A¥��
circ_limit = 1000; %��λ����ֵ��Χ
circ_half = circ_limit/2;

%% ���ݻ��� (#)
buffBlkNum = 40;                     %�������ݻ����������Ҫ��֤����ʱ�洢ǡ�ô�ͷ��ʼ��
buffBlkSize = 4000;                  %һ����Ĳ���������1ms��
buffSize = buffBlkSize * buffBlkNum; %�������ݻ����С
buff_A = zeros(2,buffSize);          %�������ݻ��棬��һ��I���ڶ���Q
buff_B = zeros(2,buffSize);
buffBlkPoint = 0;                    %���ݸ����ڼ���棬��0��ʼ
buffHead = 0;                        %�������ݵ���ţ�buffBlkSize�ı���

%% ��ȡ�ļ�ʱ�� (#)
tf = sscanf(file_path((end-22):(end-8)), '%4d%02d%02d_%02d%02d%02d')'; %�����ļ���ʼ����ʱ�䣨����ʱ�����飩
[tw, ts] = gps_time(tf); %tw��GPS������ts��GPS��������
ta = [ts,0,0] + sample2dt(sample_offset, sampleFreq); %��ʼ�����ջ�ʱ�䣬[s,ms,us]
ta = time_carry(round(ta,2)); %ȡ��

%% ���������ȡ��ǰ���ܼ��������ǣ�*��
svList = gps_constellation(tf, p0); %��������Ϊ�˿�����
svN = length(svList);

%% Ϊÿ�ſ��ܼ��������Ƿ������ͨ�� (#)
channels_A = repmat(GPS_L1_CA_channel_struct(), svN,1);
channels_B = repmat(GPS_L1_CA_channel_struct(), svN,1);
for k=1:svN
    channels_A(k).PRN = svList(k);
    channels_A(k).state = 0; %״̬δ����
    channels_B(k).PRN = svList(k);
    channels_B(k).state = 0; %״̬δ����
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
    channels_A(k).ephemeris = ephemeris(:,PRN); %Ϊͨ����������ֵ
    channels_B(k).ephemeris = ephemeris(:,PRN);
    if ~isnan(ephemeris(1,PRN)) %�������ĳ�����ǵ���������ӡ��־
        fprintf(logID_A, '%2d: Load ephemeris.\r\n', PRN);
        fprintf(logID_B, '%2d: Load ephemeris.\r\n', PRN);
    end
end

%% �������ٽ���洢�ռ� (#)
% ������msToProcess�У�ÿ����һ�����һ�ν�������ɾ���������
trackResults_A = repmat(trackResult_struct(msToProcess), svN,1);
trackResults_B = repmat(trackResult_struct(msToProcess), svN,1);
for k=1:svN
    trackResults_A(k).PRN = svList(k);
    trackResults_B(k).PRN = svList(k);
end

%% ���ջ�״̬
receiverState = 0; %���ջ�״̬��0��ʾδ��ʼ����ʱ�仹���ԣ�1��ʾʱ���Ѿ�У��
deltaFreq = 0; %ʱ�Ӳ���Ϊ�ٷֱȣ������1e-9������1500e6Hz�Ĳ����1.5Hz
dtpos = 10; %��λʱ������ms
imu_index = find(imu_data(:,1)>(ta(1)+ta(2)/1e3+ta(3)/1e6), 1); %���ڵ�ǰ���ջ�ʱ���imuʱ������
tp = sec2smu(imu_data(imu_index,1)); %ȡ��ʱ�䣬��Ϊ��һ��λʱ���
pos = NaN(1,8); %��λ�������������ʱ���õ�
chSign = zeros(svN,1); %˫����ͨ�����ţ�ͬ��Ϊ0������Ϊ0.5

%% �������ջ�����洢�ռ�
% ����msToProcess/dtpos�У�ÿ��ʱ������һ�Σ������ݽ��ջ�״̬ɾ���������
nRow = msToProcess/dtpos + 1000; %�����һЩ����ΪIMU����Ƶ�ʿ��ܱȱ�ƵĿ�
no = 1; %ָ��ǰ�洢��
output_ta     = zeros(nRow,2);     %��һ��Ϊʱ�䣨s�����ڶ���Ϊ���ջ�״̬
output_pos    = zeros(nRow,8);     %��λ��[λ�á��ٶȡ��Ӳ��Ƶ��]
output_sv_A   = zeros(svN,8,nRow); %������Ϣ(����A)��[λ�á�α�ࡢ�ٶȡ�α����]
output_sv_B   = zeros(svN,8,nRow); %������Ϣ(����B)��[λ�á�α�ࡢ�ٶȡ�α����]
output_df     = zeros(nRow,1);     %�����õ���Ƶ��˲������Ƶ�
output_dphase = NaN(nRow,svN);     %δ��������λ��

%% ���ļ������������� (#)
% �ļ�A
fileID_A = fopen(file_path_A, 'r');
fseek(fileID_A, round(sample_offset*4), 'bof');
if int64(ftell(fileID_A))~=int64(sample_offset*4)
    error('Sample offset error!');
end
% �ļ�B
fileID_B = fopen(file_path_B, 'r');
fseek(fileID_B, round(sample_offset*4), 'bof');
if int64(ftell(fileID_B))~=int64(sample_offset*4)
    error('Sample offset error!');
end
% ������
f = waitbar(0, ['0s/',num2str(msToProcess/1000),'s']);

%% �źŴ���
for t=1:msToProcess %�����ϵ�ʱ�䣬�Բ�����������
    %% ���½����� (#)
    if mod(t,1000)==0 %1s����
        waitbar(t/msToProcess, f, [num2str(t/1000),'s/',num2str(msToProcess/1000),'s']);
    end
    
    %% ������ (#)
    buff_A(:,buffBlkPoint*buffBlkSize+(1:buffBlkSize)) = double(fread(fileID_A, [2,buffBlkSize], 'int16')); %����A
    buff_B(:,buffBlkPoint*buffBlkSize+(1:buffBlkSize)) = double(fread(fileID_B, [2,buffBlkSize], 'int16')); %����B
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
            %====����A
            if channels_A(k).state==0 %���ͨ��δ��������Լ���
                [acqResult, peakRatio] = GPS_L1_CA_acq_one(svList(k), buff_A(:,(end-2*8000+1):end)); %2ms���ݲ���
                if ~isempty(acqResult) %�ɹ�����
                    channels_A(k) = GPS_L1_CA_channel_init(channels_A(k), acqResult, t*buffBlkSize, sampleFreq); %����ͨ��
                    fprintf(logID_A, '%2d: Acquired at %ds, peakRatio=%.2f\r\n', svList(k), t/1000, peakRatio); %��ӡ������־
                end
            end
            %====����B
            if channels_B(k).state==0 %���ͨ��δ��������Լ���
                [acqResult, peakRatio] = GPS_L1_CA_acq_one(svList(k), buff_B(:,(end-2*8000+1):end)); %2ms���ݲ���
                if ~isempty(acqResult) %�ɹ�����
                    channels_B(k) = GPS_L1_CA_channel_init(channels_B(k), acqResult, t*buffBlkSize, sampleFreq); %����ͨ��
                    fprintf(logID_B, '%2d: Acquired at %ds, peakRatio=%.2f\r\n', svList(k), t/1000, peakRatio); %��ӡ������־
                end
            end
        end
    end
    
    %% ���� (#)
    for k=1:svN
        bitStartFlag_A = 0;
        bitStartFlag_B = 0;
        %====����A
        if channels_A(k).state~=0 %���ͨ��������и���
            while 1
                % �ж��Ƿ��������ĸ�������
                if mod(buffHead-channels_A(k).trackDataHead,buffSize)>(buffSize/2)
                    break
                end
                % ����ٽ����ͨ��������
                n = trackResults_A(k).n;
                trackResults_A(k).dataIndex(n,:)    = channels_A(k).dataIndex;
                trackResults_A(k).ts0(n,:)          = channels_A(k).ts0;
                trackResults_A(k).remCodePhase(n,:) = channels_A(k).remCodePhase;
                trackResults_A(k).codeFreq(n,:)     = channels_A(k).codeFreq;
                trackResults_A(k).remCarrPhase(n,:) = channels_A(k).remCarrPhase;
                trackResults_A(k).carrFreq(n,:)     = channels_A(k).carrFreq;
                % ��������
                trackDataHead = channels_A(k).trackDataHead;
                trackDataTail = channels_A(k).trackDataTail;
                if trackDataHead>trackDataTail
                    [channels_A(k), I_Q, disc, bitStartFlag] = ...
                        GPS_L1_CA_track(channels_A(k), sampleFreq_real, buffSize, buff_A(:,trackDataTail:trackDataHead), logID_A);
                else
                    [channels_A(k), I_Q, disc, bitStartFlag] = ...
                        GPS_L1_CA_track(channels_A(k), sampleFreq_real, buffSize, [buff_A(:,trackDataTail:end),buff_A(:,1:trackDataHead)], logID_A);
                end
                % ��¼���ؿ�ʼ��־
                bitStartFlag_A = bitStartFlag;
                I_P_A = I_Q(1);
                % ����ٽ�������ٽ����
                trackResults_A(k).I_Q(n,:)          = I_Q;
                trackResults_A(k).disc(n,:)         = disc;
                trackResults_A(k).bitStartFlag(n,:) = bitStartFlag;
                trackResults_A(k).CN0(n,1)          = channels_A(k).CN0;
                trackResults_A(k).CN0(n,2)          = channels_A(k).CN0i;
                trackResults_A(k).carrAcc(n,:)      = channels_A(k).carrAcc;
                trackResults_A(k).strength(n,:)     = channels_A(k).strength;
                trackResults_A(k).n                 = n + 1;
            end
        end
        %====����B
        if channels_B(k).state~=0 %���ͨ��������и���
            while 1
                % �ж��Ƿ��������ĸ�������
                if mod(buffHead-channels_B(k).trackDataHead,buffSize)>(buffSize/2)
                    break
                end
                % ����ٽ����ͨ��������
                n = trackResults_B(k).n;
                trackResults_B(k).dataIndex(n,:)    = channels_B(k).dataIndex;
                trackResults_B(k).ts0(n,:)          = channels_B(k).ts0;
                trackResults_B(k).remCodePhase(n,:) = channels_B(k).remCodePhase;
                trackResults_B(k).codeFreq(n,:)     = channels_B(k).codeFreq;
                trackResults_B(k).remCarrPhase(n,:) = channels_B(k).remCarrPhase;
                trackResults_B(k).carrFreq(n,:)     = channels_B(k).carrFreq;
                % ��������
                trackDataHead = channels_B(k).trackDataHead;
                trackDataTail = channels_B(k).trackDataTail;
                if trackDataHead>trackDataTail
                    [channels_B(k), I_Q, disc, bitStartFlag] = ...
                        GPS_L1_CA_track(channels_B(k), sampleFreq_real, buffSize, buff_B(:,trackDataTail:trackDataHead), logID_B);
                else
                    [channels_B(k), I_Q, disc, bitStartFlag] = ...
                        GPS_L1_CA_track(channels_B(k), sampleFreq_real, buffSize, [buff_B(:,trackDataTail:end),buff_B(:,1:trackDataHead)], logID_B);
                end
                % ��¼���ؿ�ʼ��־
                bitStartFlag_B = bitStartFlag;
                I_P_B = I_Q(1);
                % ����ٽ�������ٽ����
                trackResults_B(k).I_Q(n,:)          = I_Q;
                trackResults_B(k).disc(n,:)         = disc;
                trackResults_B(k).bitStartFlag(n,:) = bitStartFlag;
                trackResults_B(k).CN0(n,1)          = channels_B(k).CN0;
                trackResults_B(k).CN0(n,2)          = channels_B(k).CN0i;
                trackResults_B(k).carrAcc(n,:)      = channels_B(k).carrAcc;
                trackResults_B(k).strength(n,:)     = channels_B(k).strength;
                trackResults_B(k).n                 = n + 1;
            end
        end
        %----�ж�ͨ������
        if bitStartFlag_A~=0 && bitStartFlag_B~=0
            if I_P_A*I_P_B>=0
                chSign(k) = 0;
            else
                chSign(k) = 0.5;
            end
        end
    end %end for k=1:svN
    
    %% ����Ƿ񵽴ﶨλʱ��
    dtp = (ta(1)-tp(1)) + (ta(2)-tp(2))/1e3 + (ta(3)-tp(3))/1e6; %��ǰ����ʱ���붨λʱ��֮�>=0ʱ��ʾ��ǰ����ʱ���Ѿ�����򳬹���λʱ��
    
    %% ��λʱ���ѵ���
    if dtp>=0
        %% 1.��������λ�á��ٶȣ�����α�ࡢα����
        sv_A = NaN(svN,8); %����A
        sv_B = NaN(svN,8); %����B
        dphase = NaN(svN,1); %��λ�circ
        for k=1:svN
            if channels_A(k).state==2 % && channels_A(k).CN0>35
                dn = mod(buffHead-channels_A(k).trackDataTail+1, buffSize) - 1; %trackDataTailǡ�ó�ǰbuffHeadһ��ʱ��dn=-1
                dtc = dn / sampleFreq_real; %��ǰ����ʱ������ٵ��ʱ���
                dt = dtc - dtp; %��λ�㵽���ٵ��ʱ���
                carrFreq = channels_A(k).carrFreq + 1575.42e6*deltaFreq; %��������ز�Ƶ��
                codeFreq = (carrFreq/1575.42e6+1)*1.023e6; %ͨ���ز�Ƶ�ʼ������Ƶ��
                codePhase = channels_A(k).remCodePhase + dt*codeFreq; %��λ������λ
                ts0 = [floor(channels_A(k).ts0/1e3), mod(channels_A(k).ts0,1e3), 0] + [0, floor(codePhase/1023), mod(codePhase/1023,1)*1e3]; %��λ����뷢��ʱ��
                [sv_A(k,:),~] = sv_ecef(channels_A(k).ephemeris, tp, ts0); %����������������[λ�á�α�ࡢ�ٶ�]
                sv_A(k,8) = -carrFreq/1575.42e6*299792458;%�ز�Ƶ��ת��Ϊ�ٶ�
                sv_A(k,8) = sv_A(k,8) + channels_A(k).ephemeris(9)*299792458; %��������Ƶ������ӿ���α����ƫС
                phase_A = channels_A(k).remCarrPhase + channels_A(k).carrNco*dt;
                % ������ӳ�У��
                if ~isnan(ion(1)) %���ڵ�������
                    if receiverState==1 && ~isnan(pos(1)) %�ж�λ��Ϣ��ʵ��������һ��λʱ��
                        p_ecef = lla2ecef(pos(1:3)); %���ջ�λ��
                        Cen = dcmecef2ned(pos(1),pos(2));
                        rps = sv_A(k,1:3) - p_ecef; %���ջ�ָ�����ߵ�ʸ����ecef
                        rps = rps * Cen'; %����ϵ
                        rpsu = rps / norm(rps); %��λʸ��
                        ele = -asind(rpsu(3)); %���Ǹ߶Ƚǣ�deg
                        azi = atan2d(rpsu(2),rpsu(1)); %���Ƿ�λ�ǣ�deg���ӱ�˳ʱ��Ϊ��
                        tiono = Klobuchar_iono(ion, ele, azi, pos(1), pos(2), tp(1)+tp(2)/1e3+tp(3)/1e6); %����������ʱ
                        sv_A(k,4) = sv_A(k,4) - tiono*299792458; %����α��
                    end
                end
            end
            if channels_B(k).state==2 % && channels_B(k).CN0>35
                dn = mod(buffHead-channels_B(k).trackDataTail+1, buffSize) - 1; %trackDataTailǡ�ó�ǰbuffHeadһ��ʱ��dn=-1
                dtc = dn / sampleFreq_real; %��ǰ����ʱ������ٵ��ʱ���
                dt = dtc - dtp; %��λ�㵽���ٵ��ʱ���
                carrFreq = channels_B(k).carrFreq + 1575.42e6*deltaFreq; %��������ز�Ƶ��
                codeFreq = (carrFreq/1575.42e6+1)*1.023e6; %ͨ���ز�Ƶ�ʼ������Ƶ��
                codePhase = channels_B(k).remCodePhase + dt*codeFreq; %��λ������λ
                ts0 = [floor(channels_B(k).ts0/1e3), mod(channels_B(k).ts0,1e3), 0] + [0, floor(codePhase/1023), mod(codePhase/1023,1)*1e3]; %��λ����뷢��ʱ��
                [sv_B(k,:),~] = sv_ecef(channels_B(k).ephemeris, tp, ts0); %����������������[λ�á�α�ࡢ�ٶ�]
                sv_B(k,8) = -carrFreq/1575.42e6*299792458;%�ز�Ƶ��ת��Ϊ�ٶ�
                sv_B(k,8) = sv_B(k,8) + channels_B(k).ephemeris(9)*299792458; %��������Ƶ������ӿ���α����ƫС
                phase_B = channels_B(k).remCarrPhase + channels_B(k).carrNco*dt;
                % ������λ��
                if channels_A(k).state==2 % && channels_A(k).strength==2 && channels_B(k).strength==2
%                     dphase(k) = mod((channels_A(k).carrCirc+phase_A)-(channels_B(k).carrCirc+phase_B)+chSign(k)+circ_half,circ_limit) - circ_half;
                    if channels_A(k).inverseFlag*channels_B(k).inverseFlag==1 %����������λ��ת��ͬ
                        dphase(k) = mod((channels_A(k).carrCirc+phase_A)-(channels_B(k).carrCirc+phase_B)    +circ_half,circ_limit) - circ_half;
                    else %����������λ��ת��ͬ
                        dphase(k) = mod((channels_A(k).carrCirc+phase_A)-(channels_B(k).carrCirc+phase_B)+0.5+circ_half,circ_limit) - circ_half;
                    end
                end
            end
        end
        
        %% 2.��λ
        % ֻʹ��A����
        pos = pos_solve(sv_A(~isnan(sv_A(:,1)),:)); %��ȡ�ɼ����Ƕ�λ���������4�����Ƿ���8��NaN
        
        %% 3.ʱ�ӷ�������
%         if receiverState==1 && ~isnan(pos(7))
%             deltaFreq = deltaFreq + 10*pos(8)*dtpos/1000; %��Ƶ���ۼ�
%             ta = ta - sec2smu(10*pos(7)*dtpos/1000); %ʱ�����������Բ��ý�λ�����´θ���ʱ��λ��
%         end
        
        %% 4.�洢���
        output_ta(no,1)     = tp(1) + tp(2)/1e3 + tp(3)/1e6;
        output_ta(no,2)     = receiverState;
        output_pos(no,:)    = pos;
        output_sv_A(:,:,no) = sv_A;
        output_sv_B(:,:,no) = sv_B;
        output_df(no)       = deltaFreq;
        output_dphase(no,:) = dphase';
        
        %% 5.����ʼ��
        if receiverState==0 && ~isnan(pos(7))
            if abs(pos(7))>0.1e-3 %�Ӳ����0.1ms���������ջ�ʱ��
                ta = ta - sec2smu(pos(7)); %ʱ������
                ta = time_carry(ta);
                imu_index = find(imu_data(:,1)>(ta(1)+ta(2)/1e3+ta(3)/1e6), 1);
            else %�Ӳ�С��0.1ms����ʼ������
                receiverState = 1;
            end
        end
        
        %% 6.�����´ζ�λʱ��
        imu_index = imu_index + 1; %imu����������1��ָ����һ��
        tp = sec2smu(imu_data(imu_index,1));
        no = no + 1; %ָ����һ�洢λ��
    end
    
end

%% �ر��ļ����رս����� (#)
fclose(fileID_A);
fclose(fileID_B);
fclose(logID_A);
fclose(logID_B);
close(f);

%% ɾ���հ�����
for k=1:svN
    trackResults_A(k) = trackResult_clean(trackResults_A(k));
    trackResults_B(k) = trackResult_clean(trackResults_B(k));
end
output_ta(no:end,:)         = [];
output_pos(no:end,:)        = [];
output_sv_A(:,:,no:end)     = [];
output_sv_B(:,:,no:end)     = [];
output_df(no:end,:)         = [];
output_dphase(no:end,:)     = [];
% ɾ�����ջ�δ��ʼ��ʱ������
index = find(output_ta(:,2)==0);
output_ta(index,:)          = [];
output_pos(index,:)         = [];
output_sv_A(:,:,index)      = [];
output_sv_B(:,:,index)      = [];
output_df(index,:)          = [];
output_dphase(index,:)      = [];

%% ��ӡͨ����־��*��
clc
disp('<--------antenna A-------->')
print_log([result_path,'\logA.txt'], svList);
disp('<--------antenna B-------->')
print_log([result_path,'\logB.txt'], svList);

%% �������� (#)
% ÿ�������궼�ᱣ�棬���������Զ����
for k=1:svN
    PRN = channels_A(k).PRN;
    if isnan(ephemeris(1,PRN)) %�����ļ���û��
        if ~isnan(channels_A(k).ephemeris(1))
            ephemeris(:,PRN) = channels_A(k).ephemeris; %��������
        elseif ~isnan(channels_B(k).ephemeris(1))
            ephemeris(:,PRN) = channels_B(k).ephemeris; %��������
        end
    end
end
save(ephemeris_file, 'ephemeris', 'ion');

%% �����ٽ����*��
plot_track_double(sampleFreq, msToProcess, svList, trackResults_A, trackResults_B);

%% ����λ�*��
plot_svdata(output_dphase, svList, '��λ�δ��ģ���ȣ�');

%% ���������*��
keepVariables = { ...
'sampleFreq'; 'msToProcess';
'p0'; 'tf'; 'svList'; 'svN'; %Ϊ�˻�����ͼ
'channels_A'; 'trackResults_A'; %A���߸�����Ϣ
'channels_B'; 'trackResults_B'; %B���߸�����Ϣ
'output_sv_A'; 'output_sv_B'; %������Ϣ
'ephemeris'; 'ion'; %����
'imu_data'; %IMU����
'output_ta'; 'output_pos'; 'output_dphase'; 'output_df';
'file';
};
clearvars('-except', keepVariables{:})

%% ������ (#)
% ��ʱ������
t0 = clock;
time_str = sprintf('%4d%02d%02d_%02d%02d%02d', t0(1),t0(2),t0(3),t0(4),t0(5),floor(t0(6)));
result_path = fileread('.\temp\resultPath.txt');
save([result_path,'\',time_str,'__double_imu__',file(1:end-8),'.mat'])

%% ��ʱ���� (#)
toc