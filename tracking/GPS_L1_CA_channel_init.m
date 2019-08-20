function ch = GPS_L1_CA_channel_init(ch, acqResult, n, sampleFreq)
% ͨ���ṹ���ʼ����ִ�����ͨ��������
% n��ʾ�Ѿ������˶��ٸ�������
% ��ҪԤ�ȸ�PRN

code = GPS_L1_CA_generate(ch.PRN);

% ch.PRN ���ǺŲ���
ch.state = 1; %����ͨ��
ch.trackStage = 'F'; %Ƶ��ǣ��
ch.msgStage = 'I'; %����
ch.cnt_t = 0;
ch.cnt_m = 0;
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

[K1, K2] = orderTwoLoopCoef(2, 0.707, 1);
ch.DLL.K1 = K1;
ch.DLL.K2 = K2;
ch.DLL.Int = ch.codeNco;

ch.bitSyncTable = zeros(1,20);
ch.bitBuff = zeros(2,20); %��һ��I_P���ڶ���Q_P
ch.frameBuff = zeros(1,1502);
ch.frameBuffPoint = 0;
ch.inverseFlag = -1; %-1��ʾ����ת��1��ʾ��ת
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

% ���ٿ������˲���P��
ch.Px = diag([0.02, 0.01, 5, 1].^2); %6m, 3.6deg, 5Hz, 1Hz/s (1sigma)

end