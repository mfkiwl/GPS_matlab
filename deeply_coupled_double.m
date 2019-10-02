% ˫����GPS/INS����ϳ���

clear
clc

%% ����IMU����
imu_data = IMU_parse();
close gcf
close gcf
close gcf

%% ѡ���ļ�
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

%% ��ʱ��ʼ
tic

%% ������־�ļ�
fclose('all'); %�ر�֮ǰ�򿪵������ļ�
result_path = fileread('.\temp\resultPath.txt'); %�洢�����·��
logID_A = fopen([result_path,'\logA.txt'], 'w'); %������־�ļ���ʱ��˳�����־��
logID_B = fopen([result_path,'\logB.txt'], 'w');

%% ����ʱ�� (!)
msToProcess = 60*10*1000; %������ʱ��
sample_offset = 0*4e6; %����ǰ���ٸ�������
sampleFreq = 4e6; %���ջ�����Ƶ��

%% Ԥ����� (!)
p0 = [45.730952, 126.624970, 212]; %�ο�λ��
bl = 1.30; %���߳���
br = 0.02; %���߳��ȷ�Χ
tr = [-5,5]; %��ʼ�����Ƿ�Χ��deg
circ_limit = 1000; %��λ����ֵ��Χ
circ_half = circ_limit/2;

%% �˲������� (!)
lat = p0(1);
dt0 = 0.01;
a = 6371000; %����뾶
para.P = diag([[1,1,1]*1 /180*pi, ...     %��ʼ��̬��rad
               [1,1,1]*1, ...             %��ʼ�ٶ���m/s
               [1/a,secd(lat)/a,1]*5, ... %��ʼλ����[rad,rad,m]
               2e-8 *3e8, ...             %��ʼ�Ӳ���룬m
               3e-9 *3e8, ...             %��ʼ��Ƶ���ٶȣ�m/s
               [1,1,1]*0.2 /180*pi, ...   %��ʼ��������ƫ��rad/s
               [1,1,1]*2e-3 *9.8])^2;     %��ʼ���ٶȼ���ƫ��m/s^2
para.Q = diag([[1,1,1]*0.15 /180*pi, ...
               ... %��̬һ��Ԥ�ⲻȷ���ȣ�rad/s��ȡ������������׼�
               [1,1,1]*4e-3 *9.8, ...
               ... %�ٶ�һ��Ԥ�ⲻȷ���ȣ�m/s/s����Ϊ������ƫ��ȡ���ٶȼ�������׼���������
               [1/a,secd(lat)/a,1]*4e-3 *9.8 *(dt0/1), ...
               ... %λ��һ��Ԥ�ⲻȷ���ȣ�m/s��ȡ�ٶȲ�ȷ���ȵĻ��ֻ����֣�
               0.01e-9 *3e8 *(dt0/1), ...
               ... %�Ӳ����һ��Ԥ�ⲻȷ���ȣ�m/s��ȡ��Ƶ���ٶ�Ư�ƵĻ��ֻ����֣�
               0.01e-9 *3e8, ...
               ... %��Ƶ���ٶ�Ư�ƣ�m/s/s����������þ���͹������߾��ĵ��ڣ�
               [1,1,1]*0.01 /180*pi, ...
               ... %��������ƫƯ�ƣ�rad/s/s������ݹ������߾��ĵ��ڣ�
               [1,1,1]*0.05e-3 *9.8])^2 * dt0^2;
                   %���ٶȼ���ƫƯ�ƣ�rad/s/s������ݹ������߾��ĵ��ڣ�����㣩

%% ���ݻ���
buffBlkNum = 40;                     %�������ݻ����������Ҫ��֤����ʱ�洢ǡ�ô�ͷ��ʼ��
buffBlkSize = 4000;                  %һ����Ĳ���������1ms��
buffSize = buffBlkSize * buffBlkNum; %�������ݻ����С
buff_A = zeros(2,buffSize);          %�������ݻ��棬��һ��I���ڶ���Q
buff_B = zeros(2,buffSize);
buffBlkPoint = 0;                    %���ݸ����ڼ���棬��0��ʼ
buffHead = 0;                        %�������ݵ���ţ�buffBlkSize�ı���

%% ��ȡ�ļ�ʱ��
tf = sscanf(file_path((end-22):(end-8)), '%4d%02d%02d_%02d%02d%02d')'; %�����ļ���ʼ����ʱ�䣨����ʱ�����飩
[tw, ts] = gps_time(tf); %tw��GPS������ts��GPS��������
ta = [ts,0,0] + sample2dt(sample_offset, sampleFreq); %��ʼ�����ջ�ʱ�䣬[s,ms,us]
ta = time_carry(round(ta,2)); %ȡ��

%% ���������ȡ��ǰ���ܼ���������
svList = gps_constellation(tf, p0); %��������Ϊ�˿�����
svN = length(svList); %ͨ������

%% Ϊÿ�ſ��ܼ��������Ƿ������ͨ��
channels_A = repmat(GPS_L1_CA_channel_struct(), svN,1);
channels_B = repmat(GPS_L1_CA_channel_struct(), svN,1);
for k=1:svN
    channels_A(k).PRN = svList(k);
    channels_A(k).state = 0; %״̬δ����
    channels_B(k).PRN = svList(k);
    channels_B(k).state = 0; %״̬δ����
end

%% Ԥ������
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

%% �������ٽ���洢�ռ�
% ������msToProcess�У�ÿ����һ�����һ�ν�������ɾ���������
trackResults_A = repmat(trackResult_struct(msToProcess), svN,1);
trackResults_B = repmat(trackResult_struct(msToProcess), svN,1);
for k=1:svN
    trackResults_A(k).PRN = svList(k);
    trackResults_B(k).PRN = svList(k);
end

%% ���ջ�״̬
lamda = 299792458 / 1575.42e6; %����
code_length = 299792458 / 1.023e6; %�볤
receiverState = 0; %���ջ�״̬��0��ʾδ��ʼ����ʱ�仹���ԣ�1��ʾʱ���Ѿ�У����2��ʾ�����˲�������
deltaFreq = 0; %ʱ�Ӳ���Ϊ�ٷֱȣ������1e-9������1500e6Hz�Ĳ����1.5Hz
deltaPath = 0; %������·����
dtpos = 10; %��λʱ������ms
imu_index = find(imu_data(:,1)>(ta(1)+ta(2)/1e3+ta(3)/1e6), 1); %���ڵ�ǰ���ջ�ʱ���imuʱ������
tp = sec2smu(imu_data(imu_index,1)); %ȡ��ʱ�䣬��Ϊ��һ��λʱ���
chSign = zeros(svN,1); %˫����ͨ�����ţ�ͬ��Ϊ0������Ϊ0.5
track_index0 = ones(svN,1); %�洢��һ��λʱ�̸��������������������������ֵ
dphase_mask = NaN(svN,1); %����ʶ����Щͨ���Ѿ����������ģ����ȷ����NaNΪδȷ����0Ϊ��ȷ��
lla = NaN(1,3); %���ջ�λ��
ele = NaN(svN,1); %���Ǹ߶Ƚǣ�deg
azi = NaN(svN,1); %���Ƿ�λ�ǣ�deg
rhodot0 = NaN(svN,1); %������һ��λʱ��α���ʣ�������α���ʵļ��ٶ�

%% �������ջ�����洢�ռ�
nRow = msToProcess/dtpos + 1000; %�����һЩ����ΪIMU����Ƶ�ʿ��ܱȱ�ƵĿ�
no = 1; %ָ��ǰ�洢��
%----���ջ������
output_ta        = NaN(nRow,2);     %��һ��Ϊʱ�䣨s�����ڶ���Ϊ���ջ�״̬
output_pos       = NaN(nRow,8);     %��λ��[λ�á��ٶȡ��Ӳ��Ƶ��]
output_sv_A      = NaN(svN,8,nRow); %������Ϣ(����A)��[λ�á�α�ࡢ�ٶȡ�α����]
output_sv_B      = NaN(svN,8,nRow); %������Ϣ(����B)��[λ�á�α�ࡢ�ٶȡ�α����]
output_df        = NaN(nRow,1);     %�����õ���Ƶ��
output_dp        = NaN(nRow,1);     %�����õ�·����
output_dphase    = NaN(nRow,svN);   %��λ��
output_Rx        = NaN(nRow,4);     %���߲���
%----�����˲��������
output_filter    = NaN(nRow,9);     %�˲������������[λ�á��ٶȡ���̬]
output_bias      = NaN(nRow,6);     %IMU��ƫ����
output_imu       = NaN(nRow,3);     %���������������Ϊ�˻�ͼ������������ƫ���Ƶ�׼��׼
output_P         = NaN(nRow,size(para.P,1));    %�˲���P��
output_svn       = NaN(nRow,3);     %�˲�������������[α��������α������������λ������]

%% ���ļ�������������
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
    %----------���½�����--------------------------------------------------%
    if mod(t,1000)==0 %1s����
        waitbar(t/msToProcess, f, [num2str(t/1000),'s/',num2str(msToProcess/1000),'s']);
    end
    
    %----------������------------------------------------------------------%
    buff_A(:,buffBlkPoint*buffBlkSize+(1:buffBlkSize)) = double(fread(fileID_A, [2,buffBlkSize], 'int16')); %����A
    buff_B(:,buffBlkPoint*buffBlkSize+(1:buffBlkSize)) = double(fread(fileID_B, [2,buffBlkSize], 'int16')); %����B
    buffBlkPoint = buffBlkPoint + 1;
    buffHead = buffBlkPoint * buffBlkSize;
    if buffBlkPoint==buffBlkNum
        buffBlkPoint = 0; %�����ͷ��ʼ
    end
    
    %----------���½��ջ�ʱ��----------------------------------------------%
    % ��ǰ���һ�������Ľ��ջ�ʱ��
    sampleFreq_real = sampleFreq * (1+deltaFreq); %��ʵ�Ĳ���Ƶ��
    ta = time_carry(ta + sample2dt(buffBlkSize, sampleFreq_real));
    
    %----------����--------------------------------------------------------%
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
        end %end for k=1:svN
    end %end if mod(t,1000)==0
    
    %----------����--------------------------------------------------------%
    for k=1:svN
        % ��¼�����ߵı��ؿ�ʼ��־�����ٵ����ؿ�ʼ����ǰ��һ�Σ�
        % δ����/���Ǳ��ؿ�ʼʱ����־Ϊ0����⵽���ؿ�ʼ����־��0
        % ��Ϊ��������ýϽ�����ͬʱ���ٵ�һ����
        % �������ߵı��ر�־����Ϊ0ʱ�����ݵ�ǰI·���ݵķ����ж��������Ƿ����180����λ��ת
        % ���ź�ʧ��ʱ�������Ǵ�ģ���ʱ�жϽ�������壬��Ӱ�죬��Ϊ���źŲ��������λ�����
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
                        GPS_L1_CA_track_deep(channels_A(k), sampleFreq_real, buffSize, buff_A(:,trackDataTail:trackDataHead), logID_A);
                else
                    [channels_A(k), I_Q, disc, bitStartFlag] = ...
                        GPS_L1_CA_track_deep(channels_A(k), sampleFreq_real, buffSize, [buff_A(:,trackDataTail:end),buff_A(:,1:trackDataHead)], logID_A);
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
                trackResults_A(k).strength (n,:)    = channels_A(k).strength;
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
                        GPS_L1_CA_track_deep(channels_B(k), sampleFreq_real, buffSize, buff_B(:,trackDataTail:trackDataHead), logID_B);
                else
                    [channels_B(k), I_Q, disc, bitStartFlag] = ...
                        GPS_L1_CA_track_deep(channels_B(k), sampleFreq_real, buffSize, [buff_B(:,trackDataTail:end),buff_B(:,1:trackDataHead)], logID_B);
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
        % �����������ٵ�ͨ�����ı�ͨ�����ţ���Ϊͨ�����ſ���������
        % ����ǿ�ź�״̬֮ǰ�ķ����ж�һ������ȷ��
        if isnan(dphase_mask(k))
            if bitStartFlag_A~=0 && bitStartFlag_B~=0
                if I_P_A*I_P_B>=0
                    chSign(k) = 0;
                else
                    chSign(k) = 0.5;
                end
            end
        end
    end %end for k=1:svN
    
    %----------��λ-------------------------------------------------------%
    dtp = (ta(1)-tp(1)) + (ta(2)-tp(2))/1e3 + (ta(3)-tp(3))/1e6; %��ǰ����ʱ���붨λʱ��֮�>=0ʱ��ʾ��ǰ����ʱ���Ѿ�����򳬹���λʱ��
    if dtp>=0
        
        % 1.��������λ�á��ٶȣ�����α�ࡢα���ʡ���λ������˲����õ�����
        sv_A = NaN(svN,8); %������Ϣ��[λ�á�α�ࡢ�ٶȡ�α����]
        sv_B = NaN(svN,8);
        dphase = NaN(svN,1); %��λ�circ
        rho_m         = NaN(svN,1); %�����˲�����α�����⣬m
        rhodot_m      = NaN(svN,1); %�����˲�����α�������⣬m/s
        sigma_rho_A   = NaN(svN,1); %α�������׼��
        sigma_phase_A = NaN(svN,1); %A�����ز���λ��׼��
        sigma_phase_B = NaN(svN,1); %B�����ز���λ��׼��
        for k=1:svN
            %====����A
            if channels_A(k).state==2
                dn = mod(buffHead-channels_A(k).trackDataTail+1, buffSize) - 1; %trackDataTailǡ�ó�ǰbuffHeadһ��ʱ��dn=-1
                dtc = dn / sampleFreq_real; %��ǰ����ʱ������ٵ��ʱ���
                dt = dtc - dtp; %��λ�㵽���ٵ��ʱ���
                carrFreq = channels_A(k).carrFreq + 1575.42e6*deltaFreq; %��������ز�Ƶ��
                codeFreq = (carrFreq/1575.42e6+1)*1.023e6; %ͨ���ز�Ƶ�ʼ������Ƶ��
                codePhase = channels_A(k).remCodePhase + dt*codeFreq; %��λ������λ
                ts0 = [floor(channels_A(k).ts0/1e3), mod(channels_A(k).ts0,1e3), 0] + [0, floor(codePhase/1023), mod(codePhase/1023,1)*1e3]; %��λ����뷢��ʱ��
                [sv_A(k,:),~] = sv_ecef(channels_A(k).ephemeris, tp, ts0); %����������������[λ�á�α�ࡢ�ٶ�]
                sv_A(k,8) = -carrFreq*lamda; %�ز�Ƶ��ת��Ϊ�ٶ�
                sv_A(k,8) = sv_A(k,8) + channels_A(k).ephemeris(9)*299792458; %��������Ƶ������ӿ���α����ƫС
                phase_A = channels_A(k).remCarrPhase + channels_A(k).carrNco*dt;
                % ������ӳ�У��
                if ~isnan(ion(1)) %���ڵ�������
                    if ~isnan(ele(k)) && ~isnan(lla(1))
                        tiono = Klobuchar_iono(ion, ele(k), azi(k), lla(1), lla(2), tp(1)+tp(2)/1e3+tp(3)/1e6); %����������ʱ
                        sv_A(k,4) = sv_A(k,4) - tiono*299792458; %����α��
                    end
                end
                %---------------------------------------------------------%
                if channels_A(k).strength==2 %ǿ�ź�ʱ��α��������
                    rhodot_m(k) = sv_A(k,8);
                    sigma_phase_A(k) = sqrt(channels_A(k).carrStd.D0);
                end
                if channels_A(k).CN0>35 %ƽ������ȴ���35ʱ��α������
                    % ����������¼���������������ľ�ֵ
                    % �����볬ǰ�����α��ƫ�̣��������Ϊ��ֵ����Ϊ��б�ʣ�������α���Ǽ����������ֵ
                    rho_m(k) = sv_A(k,4) - mean(trackResults_A(k).disc(track_index0(k):(trackResults_A(k).n-1),1))*code_length;
                    sigma_rho_A(k) = sqrt(channels_A(k).codeStd.D0)/3.2 * code_length;
                end
                %---------------------------------------------------------%
            end
            track_index0(k) = trackResults_A(k).n; %���¸�������
            %====����B
            if channels_B(k).state==2
                dn = mod(buffHead-channels_B(k).trackDataTail+1, buffSize) - 1; %trackDataTailǡ�ó�ǰbuffHeadһ��ʱ��dn=-1
                dtc = dn / sampleFreq_real; %��ǰ����ʱ������ٵ��ʱ���
                dt = dtc - dtp; %��λ�㵽���ٵ��ʱ���
                carrFreq = channels_B(k).carrFreq + 1575.42e6*deltaFreq; %��������ز�Ƶ��
                codeFreq = (carrFreq/1575.42e6+1)*1.023e6; %ͨ���ز�Ƶ�ʼ������Ƶ��
                codePhase = channels_B(k).remCodePhase + dt*codeFreq; %��λ������λ
                ts0 = [floor(channels_B(k).ts0/1e3), mod(channels_B(k).ts0,1e3), 0] + [0, floor(codePhase/1023), mod(codePhase/1023,1)*1e3]; %��λ����뷢��ʱ��
                [sv_B(k,:),~] = sv_ecef(channels_B(k).ephemeris, tp, ts0); %����������������[λ�á�α�ࡢ�ٶ�]
                sv_B(k,8) = -carrFreq*lamda; %�ز�Ƶ��ת��Ϊ�ٶ�
                sv_B(k,8) = sv_B(k,8) + channels_B(k).ephemeris(9)*299792458; %��������Ƶ������ӿ���α����ƫС
                phase_B = channels_B(k).remCarrPhase + channels_B(k).carrNco*dt;
                %---------------------------------------------------------%
                if channels_A(k).state==2 && channels_A(k).strength==2 && channels_B(k).strength==2 %A��B��Ϊǿ�ź�ʱ������λ��
                    dphase(k) = mod((channels_A(k).carrCirc+phase_A)-(channels_B(k).carrCirc+phase_B)+chSign(k)+circ_half,circ_limit) - circ_half;
                    dphase(k) = dphase(k) - deltaPath; %·��������
                    sigma_phase_B(k) = sqrt(channels_B(k).carrStd.D0);
                end
                %---------------------------------------------------------%
            end
        end
        dphase_m = dphase + dphase_mask; %ȷ����ģ���ȵ���λ��
        
        % 2.ֱ�Ӷ�λ
%         pos = pos_solve(sv_A(~isnan(sv_A(:,1)),:)); %��ȡ�ɼ����Ƕ�λ���������4�����Ƿ���8��NaN
        pos = pos_solve(sv_A(~isnan(rho_m),:)); %��ȡ�ź���һ��ǿ�ȵ����ǽ��ж�λ
        lla = pos(1:3); %���ջ�λ��
        
        % a.ȡ�������߽������ǵĲ���
        rs = NaN(svN,3);
        vs = NaN(svN,3);
        index = find(~isnan(sv_B(:,1)));
        rs(index,:) = sv_B(index,1:3);
        vs(index,:) = sv_B(index,5:7);
        index = find(~isnan(sv_A(:,1))); %��AΪ��
        rs(index,:) = sv_A(index,1:3);
        vs(index,:) = sv_A(index,5:7);
        
        % 3.���µ����˲���
        if receiverState==2
            %----����������
            sigma_rhodot_A = sigma_phase_A*6 * lamda; %25H���������Ƶ��������������λ������6��������õ���
            sigma_dphase = sqrt(sigma_phase_A.^2+sigma_phase_B.^2)/4.5; %25Hz���������ʵ����λ������������λ������1/4.5��������õ���
            sigma_dphase = sigma_dphase + 0.04*(90-ele)/90; %��λ������һ����߶Ƚ���صĻ�ֵ
            %----���µ����˲���
            [NF, rho, rhodot] = NF.update(imu_data(imu_index,2:7), sv_A, [rho_m,rhodot_m,dphase_m], [sigma_rho_A,sigma_rhodot_A,sigma_dphase]);
%             [NF, rho, rhodot] = NF.update(imu_data(imu_index,2:7)+[0,0,0.6,0,0,0], sv_A, [rho_m,rhodot_m,dphase_m*NaN], [sigma_rho_A,sigma_rhodot_A,sigma_dphase]);
            delta_rho_A = rho - sv_A(:,4); %�뻷α��������ֵ����·ֵ
            delta_rhodot_A = rhodot - sv_A(:,8); %�ز���α�������
            lla = NF.pos; %���ջ�λ��
            %----����A����ͨ���ز������������������
            rb = [cosd(NF.att(2))*cosd(NF.att(1)), ...
                  cosd(NF.att(2))*sind(NF.att(1)), ...
                 -sind(NF.att(2))] * bl; %����ϵ�»���ʸ��
            lat = lla(1) /180*pi;
            lon = lla(2) /180*pi;
            Cen = [-sin(lat)*cos(lon), -sin(lat)*sin(lon),  cos(lat);
                            -sin(lon),           cos(lon),         0;
                   -cos(lat)*cos(lon), -cos(lat)*sin(lon), -sin(lat)];
            rp = lla2ecef(lla);
            rsp = ones(svN,1)*rp - rs;
            rho = sum(rsp.*rsp, 2).^0.5;
            rspu = rsp ./ (rho*[1,1,1]);
            A = rspu * Cen';
            dphase_cal = A*rb' / lamda; %����̬�����λ��
            dphase_error = dphase - dphase_cal; %��λ�����
            dN = round(dphase_error); %ͨ����������������λ�����ȡ�������û����������λ��Ӧ��0������ȡ����Ϊ0
            dN(isnan(dN)) = 0; %����λ���ͨ��������
            dphase_mask( isnan(dphase)) = NaN;
            dphase_mask(~isnan(dphase)) = 0;
            if NF.cnt>200 %�˲����ȶ��������������
                ki = find(dN~=0)';
                for k=ki
                    channels_A(k).carrCirc = mod(channels_A(k).carrCirc-dN(k), circ_limit);
                end
            end
            %----�������Ǹ߶Ƚǡ���λ�ǡ������˶������α���ʡ��ز����ٶ�
            ele = asind(A(:,3));
            azi = atan2d(-A(:,2),-A(:,1));
            rhodot1 = sum(-vs.*rspu, 2);
            carrAcc = -(rhodot1-rhodot0) / (dtpos/1000) / lamda;
            rhodot0 = rhodot1;
            %----����B���߻�·���
            % ͨ������ʸ�������B����λ�ã��������̬����йأ�����
            % ͨ�����ٶȺͻ���ʸ�������B�����ٶ��������������йأ�0.4deg/s��1m���߳��ȣ���Ӧ�ٶ����0.007m/s
            rb = rb * Cen; %ecef�»���ʸ��
            rp = rp + rb; %ecef��B����λ��ʸ��
            rsp = ones(svN,1)*rp - rs;
            rho = sum(rsp.*rsp, 2).^0.5;
            rspu = rsp ./ (rho*[1,1,1]);
            Cnb = angle2dcm(NF.att(1)/180*pi, NF.att(2)/180*pi, NF.att(3)/180*pi);
            vb = cross(imu_data(imu_index,2:4)/180*pi, [bl,0,0]) * Cnb * Cen; %ecef�¸˱��ٶ�ʸ��
            vp = NF.vel*Cen + vb; %ecef��B�����ٶ�ʸ��
            vsp = ones(svN,1)*vp - vs;
            rhodot = sum(vsp.*rspu, 2);
            delta_rho_B = rho - sv_B(:,4); %�뻷α��������ֵ����·ֵ
            delta_rhodot_B = rhodot - sv_B(:,8); %�ز���α�������
            %----����ͨ����ͨ����Ҫ���н��뵽״̬2��
            for k=1:svN
                %====����A
                if channels_A(k).state==2
                    % �����ź�ǿ����ȫ������λ���볬ǰ��������α��ƫ�̣�delta_rhoΪ����
                    channels_A(k).remCodePhase = channels_A(k).remCodePhase - delta_rho_A(k)/code_length;
                    % ���ź����ز�Ƶ�ʣ�˳������ز������������½磨�����ز��죬������α����ƫС��delta_rhodotΪ����
                    if channels_A(k).strength~=2
                        channels_A(k).PLL.Int = channels_A(k).PLL.Int - delta_rhodot_A(k)/lamda;
                        channels_A(k).PLL.upper = channels_A(k).PLL.Int + 1;
                        channels_A(k).PLL.lower = channels_A(k).PLL.Int - 1;
                    else
                    % ǿ�ź�ֻ�����ز������������½�
                        carrFreq0 = channels_A(k).PLL.Int - delta_rhodot_A(k)/lamda; %��������ز�Ƶ�ʣ������������ز�����������ֻ����������������½�
                        channels_A(k).PLL.upper = carrFreq0 + 1;
                        channels_A(k).PLL.lower = carrFreq0 - 1;
                    end
                    % ����ͨ���ز����ٶȣ����û���ز����ٶ�ǰ�������׻�����Ƶ��б�£�Ƶ���о��
                    if channels_A(k).trackStage=='D'
                        channels_A(k).carrAcc = carrAcc(k);
                    end
                    % ʹ�ս���2״̬��ͨ����������ϸ���ģʽ
                    if channels_A(k).trackStage=='T'
                        channels_A(k).trackStage = 'D';
                    end
                end
                %====����B
                if channels_B(k).state==2
                    % �����ź�ǿ����ȫ������λ���볬ǰ��������α��ƫ�̣�delta_rhoΪ����
                    channels_B(k).remCodePhase = channels_B(k).remCodePhase - delta_rho_B(k)/code_length;
                    % ���ź����ز�Ƶ�ʣ�˳������ز������������½磨�����ز��죬������α����ƫС��delta_rhodotΪ����
                    if channels_B(k).strength~=2
                        channels_B(k).PLL.Int = channels_B(k).PLL.Int - delta_rhodot_B(k)/lamda;
                        channels_B(k).PLL.upper = channels_B(k).PLL.Int + 1;
                        channels_B(k).PLL.lower = channels_B(k).PLL.Int - 1;
                    else
                    % ǿ�ź�ֻ�����ز������������½�
                        carrFreq0 = channels_B(k).PLL.Int - delta_rhodot_B(k)/lamda; %��������ز�Ƶ�ʣ������������ز�����������ֻ����������������½�
                        channels_B(k).PLL.upper = carrFreq0 + 1;
                        channels_B(k).PLL.lower = carrFreq0 - 1;
                    end
                    % ����ͨ���ز����ٶȣ����û���ز����ٶ�ǰ�������׻�����Ƶ��б�£�Ƶ���о��
                    if channels_B(k).trackStage=='D'
                        channels_B(k).carrAcc = carrAcc(k);
                    end
                    % ʹ�ս���2״̬��ͨ����������ϸ���ģʽ
                    if channels_B(k).trackStage=='T'
                        channels_B(k).trackStage = 'D';
                    end
                end
            end
            %----�洢�˲������
            output_filter(no,:) = [NF.pos, NF.vel, NF.att];
            output_bias(no,:)   = NF.bias;
            output_imu(no,:)    = imu_data(imu_index,2:4);
            output_P(no,:)      = sqrt(diag(NF.Px)');
            output_svn(no,1)    = sum(~isnan(rho_m));
            output_svn(no,2)    = sum(~isnan(rhodot_m));
            output_svn(no,3)    = sum(~isnan(dphase_m));
        end
        
        % 4.ֱ�Ӳ���
        if receiverState~=2 %����ģʽ����ģ��������������ͨ���������
            lat = lla(1) /180*pi;
            lon = lla(2) /180*pi;
            Cen = [-sin(lat)*cos(lon), -sin(lat)*sin(lon),  cos(lat);
                            -sin(lon),           cos(lon),         0;
                   -cos(lat)*cos(lon), -cos(lat)*sin(lon), -sin(lat)];
            rp = lla2ecef(lla);
            rsp = ones(svN,1)*rp - rs;
            rho = sum(rsp.*rsp, 2).^0.5;
            rspu = rsp ./ (rho*[1,1,1]);
            A = rspu * Cen';
            ele = asind(A(:,3)); %���Ǹ߶Ƚ�
            azi = atan2d(-A(:,2),-A(:,1)); %���Ƿ�λ��
            An = [A/lamda, ones(svN,1)]; %��λʸ��ת�����ز�������������ȫΪ1��һ��
            if sum(~isnan(dphase_m))<4 %��Ч��λ������С��4�����ܶ���
                if sum(~isnan(dphase))>=5 %ģ��������
                    % ��A��dphase��ȡ
                    index = find(~isnan(dphase)); %����λ���������
                    Ac = A(index,:);
                    pc = dphase(index);
                    pc = mod(pc,1); %ȡС������
                    Rx = IAR(Ac, pc, lamda, bl+[-br,br], tr);
                    dphase_mask(isnan(dphase)) = NaN;
                    dphase_mask(~isnan(dphase)) = 0;
                    dN = round(dphase-An*Rx);
                    dN(isnan(dN)) = 0; %����Ч��λ���ͨ������������ģ����
                else %�޷�����ģ��������
                    Rx = NaN(4,1);
                    dphase_mask(isnan(dphase)) = NaN;
                    dN = zeros(svN,1);
                end
            else %��Ч��λ���������ڵ���4��ֱ�Ӷ���
                % ��An��dphase_m��ȡ
                index = find(~isnan(dphase_m));
                Ac = An(index,:);
                pc = dphase_m(index);
                W = diag(Ac(:,3).^3); %�߶Ƚ�Խ��ȨֵԽ��
                Rx = (Ac'*W*Ac) \ (Ac'*W*pc); %��Ȩ��С����
                dphase_mask(isnan(dphase)) = NaN;
                dphase_mask(~isnan(dphase)) = 0;
                dN = round(dphase-An*Rx);
                dN(isnan(dN)) = 0;
            end
            % ����������������ͨ��
            ki = find(dN~=0)'; %������������
            for k=ki
                channels_A(k).carrCirc = mod(channels_A(k).carrCirc-dN(k), circ_limit);
            end
        else %�����ģʽ������ģ����������������ͨ���������ڵ����˲������������
            if sum(~isnan(dphase_m))<4
                Rx = NaN(4,1);
            else
                An = [A/lamda, ones(svN,1)]; %A�ڵ����˲���������
                index = find(~isnan(dphase_m));
                Ac = An(index,:);
                pc = dphase_m(index);
%                 W = diag(Ac(:,3).^3); %�߶Ƚ�Խ��ȨֵԽ��
                W = diag(1./sigma_dphase(index)')^2;
                Rx = (Ac'*W*Ac) \ (Ac'*W*pc); %��Ȩ��С����
            end
        end
        bl_length = norm(Rx(1:3));
        psi = atan2d(Rx(2),Rx(1));
        theta = -asind(Rx(3)/bl_length);
        
        % 5.ʱ�ӷ�������
        if receiverState==1
            if ~isnan(pos(7))
                deltaFreq = deltaFreq + 10*pos(8)*dtpos/1000; %��Ƶ���ۼ�
                ta = ta - sec2smu(10*pos(7)*dtpos/1000); %ʱ�����������Բ��ý�λ�����´θ���ʱ��λ��
            end
            if ~isnan(Rx(4))
                deltaPath = deltaPath + 10*Rx(4)*dtpos/1000; %·�����ۼ�
            end
        elseif receiverState==2
            deltaFreq = deltaFreq + NF.dtv;
            ta = ta - sec2smu(NF.dtr);
        end
        
        % 6.�洢���
        output_ta(no,1)     = tp(1) + tp(2)/1e3 + tp(3)/1e6;
        output_ta(no,2)     = receiverState;
        output_sv_A(:,:,no) = sv_A;
        output_sv_B(:,:,no) = sv_B;
        output_df(no)       = deltaFreq;
        output_dp(no)       = deltaPath;
        output_dphase(no,:) = dphase_m';
        output_pos(no,:)    = pos;
        output_Rx(no,:)     = [psi, theta, bl_length, Rx(4)];
        
        % 7.����ʼ��
        if receiverState==0 && ~isnan(pos(7))
            if abs(pos(7))>0.1e-3 %�Ӳ����0.1ms���������ջ�ʱ��
                ta = ta - sec2smu(pos(7)); %ʱ������
                ta = time_carry(ta);
                imu_index = find(imu_data(:,1)>(ta(1)+ta(2)/1e3+ta(3)/1e6), 1); %�����´ζ�λʱ��
            else %�Ӳ�С��0.1ms����ʼ������
                receiverState = 1;
            end
        end
        
        % 8.��ʼ�������˲���
        if receiverState==1
            if abs(pos(8))<1e-10 && abs(Rx(4))<0.005 %��Ƶ��������·��������
                %----��ʼ���˲���
                NF = navFilter_deep_dphase(pos(1:3), [0,0,0], [psi,theta,0], dtpos/1000, lamda, bl, para);
                %----�����˶�������α���ʣ��������ز����ٶ�
                [~, rhodot0, ~, ~, ~] = cal_rho_rhodot(rs, vs, pos(1:3), [0,0,0]); %�����ٶ�Ϊ0
                %----�����ͨ�����ز�Ƶ�ʣ�ȷ���ز������������½�
                [~, rhodot , ~, ~, ~] = cal_rho_rhodot(rs, vs, pos(1:3), pos(4:6));
                carrFreq0 = -(rhodot/299792458 + deltaFreq) * 1575.42e6; %���ջ���Ƶ�죬����ز�Ƶ��ƫС
                %----����ͨ������ģʽ
                for k=1:svN
                    if channels_A(k).state==2
                        channels_A(k).trackStage = 'D';
                        channels_A(k).PLL.upper = carrFreq0(k) + 1;
                        channels_A(k).PLL.lower = carrFreq0(k) - 1;
                    end
                    if channels_B(k).state==2
                        channels_B(k).trackStage = 'D';
                        channels_B(k).PLL.upper = carrFreq0(k) + 1;
                        channels_B(k).PLL.lower = carrFreq0(k) - 1;
                    end
                end
                %----���½��ջ�״̬
                receiverState = 2;
            end
        end
        
        % 9.�����´ζ�λʱ��
        imu_index = imu_index + 1; %imu����������1��ָ����һ��
        tp = sec2smu(imu_data(imu_index,1));
        no = no + 1; %ָ����һ�洢λ��
        
    end %end if dtp>=0
end

%% �ر��ļ����رս�����
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
output_dp(no:end,:)         = [];
output_dphase(no:end,:)     = [];
output_Rx(no:end,:)         = [];
output_filter(no:end,:)     = [];
output_imu(no:end,:)        = [];
output_bias(no:end,:)       = [];
output_P(no:end,:)          = [];
output_svn(no:end,:)        = [];
% ɾ�����ջ�δ��ʼ��ʱ������
index = find(output_ta(:,2)==0);
output_ta(index,:)          = [];
output_pos(index,:)         = [];
output_sv_A(:,:,index)      = [];
output_sv_B(:,:,index)      = [];
output_df(index,:)          = [];
output_dp(index,:)          = [];
output_dphase(index,:)      = [];
output_Rx(index,:)          = [];
output_filter(index,:)      = [];
output_imu(index,:)         = [];
output_bias(index,:)        = [];
output_P(index,:)           = [];
output_svn(index,:)         = [];

%% ��ӡͨ����־
clc
disp('<--------antenna A-------->')
print_log([result_path,'\logA.txt'], svList);
disp('<--------antenna B-------->')
print_log([result_path,'\logB.txt'], svList);

%% ��������
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

%% �����ٽ��
plot_track_double(sampleFreq, msToProcess, svList, trackResults_A, trackResults_B);

%% ����λ��
plot_svdata(output_dphase, svList, '��λ��');

%% �������
keepVariables = { ...
'sampleFreq'; 'msToProcess';
'p0'; 'tf'; 'svList'; 'svN'; %Ϊ�˻�����ͼ
'channels_A'; 'trackResults_A'; %A���߸�����Ϣ
'channels_B'; 'trackResults_B'; %B���߸�����Ϣ
'output_sv_A'; 'output_sv_B'; %������Ϣ
'ephemeris'; 'ion'; %����
'imu_data'; %IMU����
'output_ta'; 'output_pos'; 'output_df'; 'output_dp'; 'output_dphase'; 'output_Rx';
'output_filter'; 'output_bias'; 'output_imu'; 'output_P'; 'output_svn';
'file';
};
clearvars('-except', keepVariables{:})

%% ������
% ��ʱ������
t0 = clock;
time_str = sprintf('%4d%02d%02d_%02d%02d%02d', t0(1),t0(2),t0(3),t0(4),t0(5),floor(t0(6)));
result_path = fileread('.\temp\resultPath.txt');
save([result_path,'\',time_str,'__deeply_double__',file(1:end-8),'.mat'])

%% ��ʱ����
toc

%% ����
function ch = GPS_L1_CA_channel_struct()
% ����ͨ���ṹ�����г�
    ch.PRN              = []; %���Ǳ��
    ch.state            = []; %ͨ��״̬�����֣�
    ch.trackStage       = []; %���ٽ׶Σ��ַ���
    ch.msgStage         = []; %���Ľ����׶Σ��ַ���
    ch.strength         = []; %�ź�ǿ�ȣ����֣�
    ch.cnt_t            = []; %����ʱ�õļ�����
    ch.cnt_m            = []; %���Ľ���ʱ�õļ�����
    ch.stableCnt        = []; %�ź��ȶ�������
    ch.code             = []; %α��
    ch.timeIntMs        = []; %����ʱ�䣬ms
    ch.trackDataTail    = []; %���ٿ�ʼ�������ݻ����е�λ��
    ch.blkSize          = []; %�������ݶβ��������
    ch.trackDataHead    = []; %���ٽ����������ݻ����е�λ��
    ch.dataIndex        = []; %���ٿ�ʼ�����ļ��е�λ��
    ch.ts0              = []; %���ٿ�ʼ�����������ڵ����۷���ʱ�䣬ms
    ch.carrNco          = []; %�ز�������Ƶ��
    ch.codeNco          = []; %�뷢����Ƶ��
    ch.carrAcc          = []; %�ز�Ƶ�ʼ��ٶ�
    ch.carrFreq         = []; %�ز�Ƶ�ʲ���
    ch.codeFreq         = []; %��Ƶ�ʲ���
    ch.remCarrPhase     = []; %���ٿ�ʼ����ز���λ
    ch.remCodePhase     = []; %���ٿ�ʼ�������λ
    ch.carrCirc         = []; %��¼�ز���������������0~999
    ch.I_P0             = []; %�ϴθ��ٵ�I_P
    ch.Q_P0             = []; %�ϴθ��ٵ�Q_P
    ch.FLL              = []; %��Ƶ�����ṹ�壩
    ch.PLL              = []; %���໷���ṹ�壩
    ch.DLL              = []; %�ӳ����������ṹ�壩
    ch.bitSyncTable     = []; %����ͬ��ͳ�Ʊ�
    ch.bitBuff          = []; %���ػ���
    ch.frameBuff        = []; %֡����
    ch.frameBuffPoint   = []; %֡����ָ��
    ch.ephemeris        = []; %����
    ch.codeStd          = []; %���������������׼��ṹ��
    ch.carrStd          = []; %�����ز�����������׼��ṹ��
    ch.NWmean           = []; %����NBP/WBP��ֵ�ṹ��
    ch.CN0              = []; %ƽ�������
    ch.CN0i             = []; %˲ʱ�����
end

function ch = GPS_L1_CA_channel_init(ch, acqResult, n, sampleFreq)
% ͨ���ṹ���ʼ����ִ�����ͨ��������
% n��ʾ�Ѿ������˶��ٸ�������
% ��ҪԤ�ȸ�PRN
    code = GPS_L1_CA_generate(ch.PRN); %C/A��

    % ch.PRN ���ǺŲ���
    ch.state = 1; %����ͨ��
    ch.trackStage = 'F'; %Ƶ��ǣ��
    ch.msgStage = 'I'; %����
    ch.strength = 0; %�ź�ʧ��
    ch.cnt_t = 0;
    ch.cnt_m = 0;
    ch.stableCnt = 0;
    ch.code = [code(end),code,code(1)]'; %��������Ϊ�������ʱ��ʸ����˼���
    ch.timeIntMs = 1;
    ch.trackDataTail = sampleFreq*0.001 - acqResult(1) + 2;
    ch.blkSize = sampleFreq*0.001;
    ch.trackDataHead = ch.trackDataTail + ch.blkSize - 1;
    ch.dataIndex = ch.trackDataTail + n;
    ch.ts0 = NaN;
    ch.carrNco = acqResult(2);
    ch.codeNco = 1.023e6 + ch.carrNco/1540;
    ch.carrAcc = 0;
    ch.carrFreq = ch.carrNco;
    ch.codeFreq = ch.codeNco;
    ch.remCarrPhase = 0;
    ch.remCodePhase = 0;
    ch.carrCirc = 0;
    ch.I_P0 = NaN;
    ch.Q_P0 = NaN;

    ch.FLL.K = 40;
    ch.FLL.Int = ch.carrNco;

    [K1, K2] = orderTwoLoopCoef(25, 0.707, 1);
    ch.PLL.K1 = K1;
    ch.PLL.K2 = K2;
    ch.PLL.Int = 0;
    ch.PLL.upper = 0; %�������Ͻ�
    ch.PLL.lower = 0; %�������½�

    [K1, K2] = orderTwoLoopCoef(2, 0.707, 1);
    ch.DLL.K1 = K1;
    ch.DLL.K2 = K2;
    ch.DLL.Int = ch.codeNco;

    ch.bitSyncTable = zeros(1,20);
    ch.bitBuff = zeros(2,20); %��һ��I_P���ڶ���Q_P
    ch.frameBuff = zeros(1,1502);
    ch.frameBuffPoint = 0;
    % ch.ephemeris ��������

    % ���������������׼��ṹ��
    ch.codeStd.buff = zeros(1,200);
    ch.codeStd.buffSize = length(ch.codeStd.buff);
    ch.codeStd.buffPoint = 0;
    ch.codeStd.E0 = 0;
    ch.codeStd.D0 = 0;

    % �����ز�����������׼��ṹ��
    ch.carrStd.buff = zeros(1,200);
    ch.carrStd.buffSize = length(ch.carrStd.buff);
    ch.carrStd.buffPoint = 0;
    ch.carrStd.E0 = 0;
    ch.carrStd.D0 = 0;

    % ����NBP/WBP��ֵ�ṹ��
    ch.NWmean.buff = zeros(1,50); %50�������ֵ
    ch.NWmean.buffSize = length(ch.NWmean.buff);
    ch.NWmean.buffPoint = 0;
    ch.NWmean.E0 = 0;
    ch.CN0 = 0;
    ch.CN0i = 0;
end

function trackResult = trackResult_struct(m)
% ���ٽ���ṹ��
    trackResult.PRN = 0;
    trackResult.n = 1; %ָ��ǰ�洢���к�
    trackResult.dataIndex     = zeros(m,1); %�����ڿ�ʼ��������ԭʼ�����ļ��е�λ��
    trackResult.ts0           = zeros(m,1); %���������۷���ʱ�䣬ms
    trackResult.remCodePhase  = zeros(m,1); %�����ڿ�ʼ�����������λ����Ƭ
    trackResult.codeFreq      = zeros(m,1); %��Ƶ��
    trackResult.remCarrPhase  = zeros(m,1); %�����ڿ�ʼ��������ز���λ����
    trackResult.carrFreq      = zeros(m,1); %�ز�Ƶ��
    trackResult.I_Q           = zeros(m,6); %[I_P,I_E,I_L,Q_P,Q_E,Q_L]
    trackResult.disc          = zeros(m,5); %[codeError,std, carrError,std, freqError]��������
    trackResult.bitStartFlag  = zeros(m,1); %���ؿ�ʼ��־
    trackResult.CN0           = zeros(m,2); %����ȣ�ƽ����˲ʱ��
    trackResult.carrAcc       = zeros(m,1); %�ز����ٶ�
    trackResult.strength      = zeros(m,1); %�ź�ǿ��
end

function trackResult = trackResult_clean(trackResult)
% ������ٽ���еĿհ׿ռ�
    n = trackResult.n;
    trackResult.dataIndex(n:end,:)    = [];
    trackResult.ts0(n:end,:)          = [];
    trackResult.remCodePhase(n:end,:) = [];
    trackResult.codeFreq(n:end,:)     = [];
    trackResult.remCarrPhase(n:end,:) = [];
    trackResult.carrFreq(n:end,:)     = [];
    trackResult.I_Q(n:end,:)          = [];
    trackResult.disc(n:end,:)         = [];
    trackResult.bitStartFlag(n:end,:) = [];
    trackResult.CN0(n:end,:)          = [];
    trackResult.carrAcc(n:end,:)      = [];
    trackResult.strength(n:end,:)     = [];
end