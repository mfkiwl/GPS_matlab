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