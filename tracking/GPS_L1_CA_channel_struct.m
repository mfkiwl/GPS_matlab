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
ch.loseCnt          = []; %�ź�ʧ��������
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
ch.inverseFlag      = []; %��λ��ת��־
ch.ephemeris        = []; %����
ch.codeStd          = []; %���������������׼��ṹ��
ch.carrStd          = []; %�����ز�����������׼��ṹ��
ch.NWmean           = []; %����NBP/WBP��ֵ�ṹ��
ch.CN0              = []; %ƽ�������
ch.CN0i             = []; %˲ʱ�����

end