function [acqResult, peakRatio] = GPS_L1_CA_acq_one(PRN, data)
% ������ΪPRN�����ǡ����δ���񵽣�acqResultΪ��
% data��Ҫ�������������񳤶ȵ�����

acqResult = []; %�沶��������һ������λ���ڶ����ز�Ƶ��

%%
N = length(data) / 2; %��������
fs = 4e6; %����Ƶ�ʣ�Hz
fc = 1.023e6; %��Ƶ�ʣ�Hz

carrFreq = -6e3:(fs/N/2):6e3; %Ƶ��������Χ
M = length(carrFreq);

acqThreshold = 1.4; %������ֵ������ȵڶ�������ٱ�

%%
% ȡ�����������������ݣ���Ϊ���ܴ��ڵ������ĵķ�ת������ط��С
baseband1 = data(1,  1:N)   + data(2,  1:N)  *1i;
baseband2 = data(1,N+1:end) + data(2,N+1:end)*1i;

result1 = zeros(M,4000); %����������������ز�Ƶ�ʣ���������λ
result2 = zeros(M,4000);
resultCorr1 = zeros(M,2); %��һ�д�ÿ������Ƶ��������ֵ���ڶ��д����ֵ��Ӧ������
resultCorr2 = zeros(M,2);

% [Xg,Yg] = meshgrid(1:4000,carrFreq); %��ͼ����-------------

%% �����㷨
CAcode = GPS_L1_CA_generate(PRN); %C/A������
code = CAcode(mod(floor((0:N-1)*fc/fs),1023) + 1); %C/A�����
CODE = fft(code); %C/A��FFT

%----����
for k=1:M
    carrier = exp(-2*pi * carrFreq(k) * (0:N-1)/fs * 1i); %���ظ��ز�����Ƶ��

    x = baseband1 .* carrier;
    X = fft(x);
    Y = conj(X).*CODE;
    y = abs(ifft(Y));
    result1(k,:) = y(1:4000); %ֻȡǰ4000����������Ķ����ظ���
    [resultCorr1(k,1), resultCorr1(k,2)] = max(result1(k,:)); %Ѱ��һ����ص����ֵ��������

    x = baseband2 .* carrier;
    X = fft(x);
    Y = conj(X).*CODE;
    y = abs(ifft(Y));
    result2(k,:) = y(1:4000);
    [resultCorr2(k,1), resultCorr2(k,2)] = max(result2(k,:));
end

%----ѡȡֵ�����������
if max(resultCorr1(:,1))>max(resultCorr2(:,1))
    corrValue = resultCorr1(:,1);
    corrIndex = resultCorr1(:,2);
%     result = result1; %������ͼ-------------
else
    corrValue = resultCorr2(:,1);
    corrIndex = resultCorr2(:,2);
%     result = result2; %������ͼ-------------
end

%----Ѱ����ط�
[peakSize, index] = max(corrValue); %����
corrValue(mod(index+(-3:3)-1,M)+1) = 0; %�ų��������ط���Χ�ĵ�
secondPeakSize = max(corrValue); %�ڶ����

%----�����ź�
peakRatio = peakSize / secondPeakSize; %��߷���ڶ����ı�ֵ
if peakRatio>acqThreshold
    % ��ͼ-------------
%     figure
%     surf(Xg,Yg,result)
%     title(['PRN = ',num2str(PRN)])

    acqResult(1) = corrIndex(index); %����λ
    acqResult(2) = carrFreq(index); %�ز�Ƶ��
end

end