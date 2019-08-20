function acqResults = GPS_L1_CA_acq(file_path, sample_offset, N)
% GPS�źŲ���32������ȫ��������������2�����ݣ�ʹ�����ֵ��������ڱ���acqResults��
% sample_offset������ǰ���ٸ������㴦��ʼ����
% N��FFT����

%%
Ns = N; %��������
fs = 4e6; %����Ƶ�ʣ�Hz
fc = 1.023e6; %��Ƶ�ʣ�Hz

carrFreq = -6e3:(fs/Ns/2):6e3; %Ƶ��������Χ
M = length(carrFreq);

acqThreshold = 1.4; %������ֵ������ȵڶ�������ٱ�

%%
% ȡ�����������������ݣ���Ϊ���ܴ��ڵ������ĵķ�ת������ط��С
fileID = fopen(file_path, 'r');
    fseek(fileID, round(sample_offset*4), 'bof');
    if int32(ftell(fileID))~=int32(sample_offset*4)
        error('Sample offset error!');
    end
    baseband1 = double(fread(fileID, [2,Ns], 'int16'));
    baseband1 = baseband1(1,:) + baseband1(2,:)*1i; %������
    baseband2 = double(fread(fileID, [2,Ns], 'int16'));
    baseband2 = baseband2(1,:) + baseband2(2,:)*1i; %������
fclose(fileID);

result1 = zeros(M,4000); %����������������ز�Ƶ�ʣ���������λ
result2 = zeros(M,4000);
resultCorr1 = zeros(M,2); %��һ�д�ÿ������Ƶ��������ֵ���ڶ��д����ֵ��Ӧ������
resultCorr2 = zeros(M,2);

[Xg,Yg] = meshgrid(1:4000,carrFreq); %��ͼ����

% �沶��������һ������λ���ڶ����ز�Ƶ��
acqResults = NaN(32,2);

%% �����㷨
for PRN=1:32
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
        result = result1; %������ͼ
    else
        corrValue = resultCorr2(:,1);
        corrIndex = resultCorr2(:,2);
        result = result2;
    end
    
    %----Ѱ����ط�
    [peakSize, index] = max(corrValue); %����
    corrValue(mod(index+(-3:3)-1,M)+1) = 0; %�ų��������ط���Χ�ĵ�
    secondPeakSize = max(corrValue); %�ڶ����
    
    %----�����ź�
    if (peakSize/secondPeakSize)>acqThreshold
        % ��ͼ
        figure
        surf(Xg,Yg,result)
        title(['PRN = ',num2str(PRN)])
        
        %�洢������
        acqResults(PRN,1) = corrIndex(index); %����λ
        acqResults(PRN,2) = carrFreq(index); %�ز�Ƶ��
    end
end

end