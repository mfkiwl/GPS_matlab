function dt = sample2dt(n, sampleFreq)
% ��������ת��Ϊʱ��������n�������0��

dt = [0,0,0]; %[s,ms,us]

% dt(1) = floor(n/sampleFreq);
% dt(2) = floor(rem(n,sampleFreq) * (1e3/sampleFreq));
% % (1e3/sampleFreq)��ʾһ����������ٺ��룬rem(n,sampleFreq)��ʾ����1���ж��ٸ�������
% dt(3) = rem(n,(sampleFreq/1e3)) * (1e6/sampleFreq);
% % (1e6/sampleFreq)��ʾһ�����������΢�룬rem(n,(sampleFreq/1e3))��ʾ����1�����ж��ٸ�������

t = n / sampleFreq;
dt(1) = floor(t); %���벿��
t = mod(t,1) * 1000;
dt(2) = floor(t); %���벿��
dt(3) = mod(t,1) * 1000; %΢�벿��

end