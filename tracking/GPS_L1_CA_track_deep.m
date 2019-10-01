function [ch, I_Q, disc, bitStartFlag] = GPS_L1_CA_track_deep(ch, sampleFreq, buffSize, rawSignal, logID)

bitStartFlag = 0;

%% ��ȡͨ����Ϣ�������㷨�õ��Ŀ��Ʋ�����
trackStage     = ch.trackStage;
msgStage       = ch.msgStage;
cnt_t          = ch.cnt_t;
cnt_m          = ch.cnt_m;
code           = ch.code;
timeIntMs      = ch.timeIntMs;
blkSize        = ch.blkSize;
carrNco        = ch.carrNco;
codeNco        = ch.codeNco;
remCarrPhase   = ch.remCarrPhase;
remCodePhase   = ch.remCodePhase;
carrCirc       = ch.carrCirc;
I_P0           = ch.I_P0;
Q_P0           = ch.Q_P0;
FLL            = ch.FLL;
PLL            = ch.PLL;
DLL            = ch.DLL;
bitSyncTable   = ch.bitSyncTable;
bitBuff        = ch.bitBuff;
frameBuff      = ch.frameBuff;
frameBuffPoint = ch.frameBuffPoint;

ch.dataIndex = ch.dataIndex + blkSize; %�¸����ݶο�ʼ����������
ch.ts0       = ch.ts0 + timeIntMs; %��ǰ�����ڽ�����ʱ�䣬ms

timeInt = timeIntMs * 0.001; %����ʱ�䣬s
codeInt = timeIntMs * 1023; %����ʱ������Ƭ����
pointInt = 20 / timeIntMs; %һ�����ı������ж��ٸ����ֵ�

%% ��������
% ʱ������
t = (0:blkSize-1) / sampleFreq;
te = blkSize / sampleFreq;

% ���ɱ����ز�
theta = (remCarrPhase + carrNco*t) * 2; %��Ƶ���ز�����2��Ϊ��������piΪ��λ�����Ǻ���
carr_cos = cospi(theta); %�����ز�
carr_sin = sinpi(theta);
theta_next = remCarrPhase + carrNco*te;
remCarrPhase = mod(theta_next, 1); %ʣ���ز���λ����
carrCirc = mod(floor(carrCirc+theta_next), 1000); %�ز�������������

% ���ɱ�����
tcode = remCodePhase + codeNco*t + 2; %��2��֤���ͺ���ʱ����1
earlyCode  = code(floor(tcode+0.5)); %��ǰ��
promptCode = code(floor(tcode));     %��ʱ��
lateCode   = code(floor(tcode-0.5)); %�ͺ���
remCodePhase = remCodePhase + codeNco*te - codeInt; %ʣ���ز���λ����

% ԭʼ���ݳ��ز�
% ��������˲𿪣�Ϊ�˱���ȡʵ�����鲿ʱ���ú�����ʱ
iBasebandSignal = rawSignal(1,:).*carr_cos + rawSignal(2,:).*carr_sin; %�˸��ز�
qBasebandSignal = rawSignal(2,:).*carr_cos - rawSignal(1,:).*carr_sin;

% ��·����
% ������������������˴���sum(X.*X)������
I_E = iBasebandSignal * earlyCode;
Q_E = qBasebandSignal * earlyCode;
I_P = iBasebandSignal * promptCode;
Q_P = qBasebandSignal * promptCode;
I_L = iBasebandSignal * lateCode;
Q_L = qBasebandSignal * lateCode;

% �������
S_E = sqrt(I_E^2+Q_E^2);
S_L = sqrt(I_L^2+Q_L^2);
codeError = 0.5 * (S_E-S_L)/(S_E+S_L); %��λ����Ƭ
[ch.codeStd, codeSigma] = std_rec(ch.codeStd ,codeError); %���������������׼��

% �ز�������
carrError = atan(Q_P/I_P) / (2*pi); %��λ����
[ch.carrStd, carrSigma] = std_rec(ch.carrStd ,carrError); %�����ز�����������׼��

% ��Ƶ��
if ~isnan(I_P0)
    yc = I_P0*I_P + Q_P0*Q_P;
    ys = I_P0*Q_P - Q_P0*I_P;
    freqError = atan(ys/yc)/timeInt / (2*pi); %��λ��Hz
else
    freqError = 0;
end

%% �����㷨
switch trackStage
    case 'F' %<<====Ƶ��ǣ��
        %----FLL
        FLL.Int = FLL.Int + FLL.K*freqError*timeInt; %��Ƶ��������
        carrNco = FLL.Int;
        carrFreq = FLL.Int;
        % 500ms��ת����ͳ����
        cnt_t = cnt_t + 1;
        if cnt_t==500
            cnt_t = 0; %����������
            PLL.Int = FLL.Int; %��ʼ�����໷������
            trackStage = 'T';
            fprintf(logID, '%2d: Start traditional tracking at %.8fs\r\n', ...
                    ch.PRN, ch.dataIndex/sampleFreq);
        end
        %----DLL
        DLL.Int = DLL.Int + DLL.K2*codeError*timeInt; %�ӳ�������������
        codeNco = DLL.Int + DLL.K1*codeError;
        codeFreq = DLL.Int;
        
	case 'T' %<<====��ͳ����
        %----PLL
        PLL.Int = PLL.Int + PLL.K2*carrError*timeInt; %���໷������
        carrNco = PLL.Int + PLL.K1*carrError;
        carrFreq = PLL.Int;
        % 500ms����б���ͬ��
        if msgStage=='I'
            cnt_t = cnt_t + 1;
            if cnt_t==500
                cnt_t = 0; %����������
                msgStage = 'B';
                fprintf(logID, '%2d: Start bit synchronization at %.8fs\r\n', ...
                        ch.PRN, ch.dataIndex/sampleFreq);
            end
        end
        %----DLL
        DLL.Int = DLL.Int + DLL.K2*codeError*timeInt; %�ӳ�������������
        codeNco = DLL.Int + DLL.K1*codeError;
        codeFreq = DLL.Int;
        
	case 'D' %<<====������뻷�����໷������
        %----PLL
        if ch.strength==2 %ǿ�ź�ʱʹ�ö��׻����������ֿ��ƣ��õ��ز�Ƶ�ʲ���
            PLL.Int = PLL.Int + PLL.K2*carrError*timeInt + ch.carrAcc*timeInt; %���໷������
            if PLL.Int>PLL.upper %���ֱ���
                PLL.Int = PLL.upper;
            elseif PLL.Int<PLL.lower
                PLL.Int = PLL.lower;
            end
            carrNco = PLL.Int + PLL.K1*carrError;
            carrFreq = PLL.Int;
        else %���ź�ʱʹ��Ƶ�ʸ�����һ�׻����������ƣ������ز���λ
            carrNco = PLL.Int + PLL.K1*carrError;
%             carrNco = PLL.Int + 8*carrError;
            carrFreq = PLL.Int;
        end
        %----DLL
        codeNco = 1.023e6 + carrFreq/1540; %��Ƶ��ֱ�����ز�Ƶ�ʼ���
        codeFreq = 1.023e6 + carrFreq/1540;
        
	otherwise
end

%% ���Ľ����㷨
switch msgStage %I, B, W, H, C, E
    case 'I' %<<====����
        
    case 'B' %<<====����ͬ��
        % ������1ms����ʱ�䣬����2s����100������
        % ����ͬ�������ʵ�ָ����Ļ���ʱ��
        % ����ͬ������Խ�������ȼ���
        cnt_m = cnt_m + 1;
        if (I_P0*I_P)<0 %���ֵ�ƽ��ת
            index = mod(cnt_m-1,20) + 1;
            bitSyncTable(index) = bitSyncTable(index) + 1; %ͳ�Ʊ��еĶ�Ӧλ��1
        end
        if cnt_m==2000 %2s�����ͳ�Ʊ�
            if max(bitSyncTable)>10 && (sum(bitSyncTable)-max(bitSyncTable))<=2 %ȷ����ƽ��תλ�ã���ƽ��ת�󶼷�����һ�����ϣ�
                [~,cnt_m] = max(bitSyncTable);
                bitSyncTable = zeros(1,20); %����ͬ��ͳ�Ʊ�����
                cnt_m = -cnt_m + 1;
                if cnt_m==0
                    msgStage = 'H'; %����Ѱ��֡ͷģʽ
                    fprintf(logID, '%2d: Start find head at %.8fs\r\n', ...
                            ch.PRN, ch.dataIndex/sampleFreq);
                else
                    msgStage = 'W'; %����ȴ�cnt_m==0ģʽ
                end
            else
                ch.state = 0; %����ͬ��ʧ�ܣ��ر�ͨ��
                fprintf(logID, '%2d: ***Bit synchronization fails at %.8fs\r\n', ...
                        ch.PRN, ch.dataIndex/sampleFreq);
            end
        end
        
    case 'W' %<<====�ȴ�cnt_m==0
        cnt_m = cnt_m + 1;
        if cnt_m==0
            msgStage = 'H'; %����Ѱ��֡ͷģʽ
            fprintf(logID, '%2d: Start find head at %.8fs\r\n', ...
                    ch.PRN, ch.dataIndex/sampleFreq);
        end
        
    otherwise %<<====�Ѿ���ɱ���ͬ��
        cnt_m = cnt_m + 1;
        bitBuff(1,cnt_m) = I_P; %�����ػ����д���
        bitBuff(2,cnt_m) = Q_P; %�����ػ����д���
        if cnt_m==1 %��ǵ�ǰ���ٵ����ݶ�Ϊ���ؿ�ʼλ��
            bitStartFlag = double(msgStage);
        end
        if cnt_m==pointInt %������һ������
            cnt_m = 0; %����������
            %-------------------------------------------------------------%
            %====����ƽ�������
            Ps = bitBuff(1,1:pointInt).^2 + bitBuff(2,1:pointInt).^2; %ÿ����Ĺ���
            WBP = sum(Ps); %������ʣ����е�Ĺ�����ͣ���ƽ������ͣ�
            Is = sum(bitBuff(1,1:pointInt)); %�ϳ�I
            Qs = sum(bitBuff(2,1:pointInt)); %�ϳ�Q
            NBP = Is^2 + Qs^2; %խ�����ʣ��ϳ�IQ�Ĺ��ʣ��ź�Խ�ã�խ������Խ���������ƽ����
            if ch.CN0==0 %��ʼ�����ֵ�ṹ�壨ͨ���ռ���ʱCN0Ϊ0��
                ch.NWmean.buff = ones(1,ch.NWmean.buffSize)*(NBP/WBP);
                ch.NWmean.E0 = NBP/WBP;
            end
            [ch.NWmean, NWm] = mean_rec(ch.NWmean, NBP/WBP); %����Z�ľ�ֵ
            S = (NWm-1) / (pointInt-NWm) / timeInt;
            if S>10
                CN0 = 10*log10(S); %�����
            else
                CN0 = 10; %��������ȵ���СֵΪ10���ճ�ʼ��ʱΪ0
            end
            ch.CN0 = CN0;
            %====û�������ʱʧ��Ҫ����ͨ��
            if CN0<30
                if trackStage=='T'
                    ch.state = 0;
                    fprintf(logID, '%2d: ***Abandon at %.8fs\r\n', ...
                            ch.PRN, ch.dataIndex/sampleFreq);
                end
            end
            %====����˲ʱ�����
            Z = NBP / WBP;
            S = (Z-1) / (pointInt-Z) / timeInt;
            if S>10
                CN0i = 10*log10(S); %˲ʱ�����
            else
                CN0i = 10;
            end
            ch.CN0i = CN0i;
            %====�źŴ�Խ�ж�
            if length(unique(sign(bitBuff(1,1:pointInt))))==1 %һ�������ڵ����е���Ŷ���ͬ
                through_flag = 0; %�޴�Խ
            else
                through_flag = 1; %�д�Խ
            end
            %====�����ź��ȶ�������
            stableCnt = ch.stableCnt;
            if CN0i>=30 && through_flag==0 %����ȴ�����ֵ�����޴�Խʱ����������1�����������ֵΪ50��1s��
                if (stableCnt+1)>50
                    stableCnt = 50; %��ʾ�ź��Ѿ��ȶ���1s
                else
                    stableCnt = stableCnt + 1;
                end
            else
                stableCnt = 0; %��⵽�����С����ֵ������һ�������ڴ��ڻ��ֵ㴩Խ������������
            end
            ch.stableCnt = stableCnt;
            %====�ж��ź�ǿ��
            strength = ch.strength;
            if strength==2 %ǿ�ź�
                if stableCnt==0
                    ch.strength = 1;
                    fprintf(logID, '%2d: ***Weak signal at %.8fs\r\n', ...
                            ch.PRN, ch.dataIndex/sampleFreq);
                end
            elseif strength==1 %���ź�
                if CN0<30
                    ch.strength = 0;
                    fprintf(logID, '%2d: ***Lose lock at %.8fs\r\n', ...
                            ch.PRN, ch.dataIndex/sampleFreq);
                end
                if stableCnt==50
                    ch.strength = 2;
                    fprintf(logID, '%2d: Strong signal at %.8fs\r\n', ...
                            ch.PRN, ch.dataIndex/sampleFreq);
                end
            elseif strength==0 %ʧ��
                if CN0>=32
                    ch.strength = 1;
                    fprintf(logID, '%2d: Weak signal at %.8fs\r\n', ...
                            ch.PRN, ch.dataIndex/sampleFreq);
                end
            end
            %-------------------------------------------------------------%
            bit = sum(bitBuff(1,1:pointInt)) > 0; %�жϱ���ֵ��0/1
            frameBuffPoint = frameBuffPoint + 1;
            frameBuff(frameBuffPoint) = (double(bit) - 0.5) * 2; %�洢����ֵ����1
            switch msgStage
                case 'H' %<<====Ѱ��֡ͷ
                    if frameBuffPoint>=10 %������10�����أ�ǰ��������У��
                        if abs(sum(frameBuff(frameBuffPoint+(-7:0)).*[1,-1,-1,-1,1,-1,1,1]))==8 %��⵽����֡ͷ
                            frameBuff(1:10) = frameBuff(frameBuffPoint+(-9:0)); %��֡ͷ��ǰ
                            frameBuffPoint = 10;
                            msgStage = 'C'; %����У��֡ͷģʽ
                        end
                    end
                    if frameBuffPoint==1502 %��ֹBug��һ�㵽�������30s��û�ҵ�֡ͷ��ͱ��ж�Ϊʧ����
                        frameBuffPoint = 0;
                    end
                case 'C' %<<====У��֡ͷ
                    if frameBuffPoint==310 %�洢��һ����֡��2+300+8
                        if GPS_L1_CA_check(frameBuff(1:32))==1 && GPS_L1_CA_check(frameBuff(31:62))==1 && ... %У��ͨ��
                            abs(sum(frameBuff(303:310).*[1,-1,-1,-1,1,-1,1,1]))==8
                            % ��ȡ����ʱ��
                            % frameBuff(32)Ϊ��һ�ֵ����һλ��У��ʱ���Ƶ�ƽ��ת��Ϊ1��ʾ��ת��Ϊ0��ʾ����ת���μ�ICD-GPS���ҳ
                            bits = -frameBuff(32) * frameBuff(33:49); %��ƽ��ת��31~47����
                            bits = dec2bin(bits>0)'; %��1����ת��Ϊ01�ַ���
                            TOW = bin2dec(bits); %01�ַ���ת��Ϊʮ������
                            ch.ts0 = (TOW*6+0.16)*1000; %ms��0.16=8/50
                            if ~isnan(ch.ephemeris(1))
                                ch.state = 2; %����״̬��֪���뷢��ʱ�䣬������������
                            end
                            msgStage = 'E'; %�����������ģʽ
                            fprintf(logID, '%2d: Start parse ephemeris at %.8fs\r\n', ...
                                    ch.PRN, ch.dataIndex/sampleFreq);
                        else %У��δͨ��
                            for k=11:310 %���������������û��֡ͷ
                                if abs(sum(frameBuff(k+(-7:0)).*[1,-1,-1,-1,1,-1,1,1]))==8 %��⵽����֡ͷ
                                    frameBuff(1:320-k) = frameBuff(k-9:310); %��֡ͷ�ͺ���ı�����ǰ��320-k = 310-(k-9)+1
                                    frameBuffPoint = 320-k;
                                    break
                                end
                            end
                            if frameBuffPoint==310 %û��⵽����֡ͷ
                                frameBuff(1:9) = frameBuff(302:310); %��δ���ı�����ǰ
                                frameBuffPoint = 9;
                                msgStage = 'H'; %�ٴ�Ѱ��֡ͷ
                            end
                        end
                    end
                case 'E' %<<====��������
                    if frameBuffPoint==1502 %������5֡
                        ephemeris = GPS_L1_CA_ephemeris(frameBuff); %��������
                        if isempty(ephemeris) %��������
                            fprintf(logID, '%2d: ***Ephemeris error at %.8fs\r\n', ...
                                    ch.PRN, ch.dataIndex/sampleFreq);
                            %-------------------------------------------------------------%
%                             bits = -frameBuff(62) * frameBuff; %��ƽ��ת
%                             bits = dec2bin(bits>0)'; %��1����ת��Ϊ01�ַ���
%                             fprintf(logID, ['%2d: ',bits(1:2),'\r\n'], ch.PRN);
%                             for k=1:50 %������ĵ�����������ҵ��Ĵ���ԭ��
%                                 fprintf(logID, ['%2d: ',bits((k-1)*30+2+(1:30)),'\r\n'], ch.PRN);
%                             end
                            %-------------------------------------------------------------%
                            frameBuffPoint = 0;
                            msgStage = 'H'; %����Ѱ��֡ͷ
                            fprintf(logID, '%2d: Start find head at %.8fs\r\n', ...
                                    ch.PRN, ch.dataIndex/sampleFreq);
                        else
                            if ephemeris(2)~=ephemeris(3) %�����ı�
                                fprintf(logID, '%2d: ***Ephemeris changes at %.8fs, IODC=%d, IODE=%d\r\n', ...
                                        ch.PRN, ch.dataIndex/sampleFreq, ephemeris(2), ephemeris(3));
                            else
                                ch.ephemeris = ephemeris; %��������
                                ch.state = 2; %����״̬��֪���뷢��ʱ�䣬������������
                                fprintf(logID, '%2d: Ephemeris is parsed at %.8fs\r\n', ...
                                        ch.PRN, ch.dataIndex/sampleFreq);
                            end
                            frameBuff(1:2) = frameBuff(1501:1502); %���������������ǰ
                            frameBuffPoint = 2;
                        end
                    end
                otherwise
            end
        end
        
end

%% ������һ���ݿ�λ��
trackDataTail = ch.trackDataHead + 1;
if trackDataTail>buffSize
    trackDataTail = 1;
end
blkSize = ceil((codeInt-remCodePhase)/codeNco*sampleFreq);
trackDataHead = trackDataTail + blkSize - 1;
if trackDataHead>buffSize
    trackDataHead = trackDataHead - buffSize;
end
ch.trackDataTail = trackDataTail;
ch.blkSize       = blkSize;
ch.trackDataHead = trackDataHead;

%% ����ͨ����Ϣ
ch.trackStage     = trackStage;
ch.msgStage       = msgStage;
ch.cnt_t          = cnt_t;
ch.cnt_m          = cnt_m;
ch.code           = code;
ch.timeIntMs      = timeIntMs;
ch.carrNco        = carrNco;
ch.codeNco        = codeNco;
ch.carrFreq       = carrFreq;
ch.codeFreq       = codeFreq;
ch.remCarrPhase   = remCarrPhase;
ch.remCodePhase   = remCodePhase;
ch.carrCirc       = carrCirc;
ch.I_P0           = I_P;
ch.Q_P0           = Q_P;
ch.FLL            = FLL;
ch.PLL            = PLL;
ch.DLL            = DLL;
ch.bitSyncTable   = bitSyncTable;
ch.bitBuff        = bitBuff;
ch.frameBuff      = frameBuff;
ch.frameBuffPoint = frameBuffPoint;

%% ���
I_Q = [I_P, I_E, I_L, Q_P, Q_E, Q_L];
disc = [codeError, codeSigma, carrError, carrSigma, freqError];

end