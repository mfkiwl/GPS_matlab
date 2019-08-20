function varargout = IMU_parse()
% ����IMU���ݣ���ʱ���ת��ΪGPSʱ��
% ʱ�䵥λs�����ٶȵ�λdeg/s�����ٶȵ�λg
% ������ʽ��ʹ�öԻ���ѡ���ļ�
% ʹ�ÿɱ���������ʹ�ó������ֱ�����У������

%% 1.���ļ�
default_path = fileread('.\temp\dataPath.txt'); %�����ļ�����Ĭ��·��
[file, path] = uigetfile([default_path,'\*.dat'], 'ѡ��IMU�����ļ�'); %�ļ�ѡ��Ի�������Ϊ.dat�ļ�
if file==0
    disp('Invalid file!');
    return
end
if strcmp(file(1:9),'ADIS16448')==0 && strcmp(file(1:7),'IMU5210')==0
    error('File error!');
end
file_path = [path, file];
fileID = fopen(file_path, 'r');
stream = fread(fileID, 'uint8=>uint8');
fclose(fileID);

%% 2.����ԭʼ����
n = length(stream); %���ֽ���
data = zeros(ceil(n/27),16); %������ԭʼ���ݣ�ÿ֡27�ֽ�
% [cnt, year,mon,day, hour,min,sec, TIM3, wx,wy,wz, fx,fy,fz, temp, PPS_error]

k = 1; %�ֽ�ָ��
m = 1; %���ݴ洢ָ��
while 1
    if stream(k)==85 %֡ͷ��0x55
        if k+26<=n %֡β�����ֽ�������
            if stream(k+26)==170 %֡β��0xAA
                buff = stream(k+(0:26)); %��ȡһ֡
                data(m,1) = double(buff(3)); %cnt
                data(m,2) = double(buff(4)); %year
                data(m,3) = double(buff(5)); %mon
                data(m,4) = double(buff(6)); %day
                data(m,5) = double(buff(7)); %hour
                data(m,6) = double(buff(8)); %min
                data(m,7) = double(buff(9)); %sec
                data(m,8)  = double(typecast(buff(10:11),'uint16')); %TIM3
                switch buff(2) %�����豸�Ž�������ת��
                    case 0
                        data(m,10) =  double(typecast(buff(12:13),'int16')) /32768*300;
                        data(m,9)  =  double(typecast(buff(14:15),'int16')) /32768*300;
                        data(m,11) = -double(typecast(buff(16:17),'int16')) /32768*300;
                        data(m,13) =  double(typecast(buff(18:19),'int16')) /32768*10;
                        data(m,12) =  double(typecast(buff(20:21),'int16')) /32768*10;
                        data(m,14) = -double(typecast(buff(22:23),'int16')) /32768*10;
                        data(m,15) =  double(typecast(buff(24:25),'int16')) /10; %temperature
                    case 1
                        data(m,10) = -double(typecast(buff(12:13),'int16')) /50;
                        data(m,9)  = -double(typecast(buff(14:15),'int16')) /50;
                        data(m,11) = -double(typecast(buff(16:17),'int16')) /50;
                        data(m,13) = -double(typecast(buff(18:19),'int16')) /1200;
                        data(m,12) = -double(typecast(buff(20:21),'int16')) /1200;
                        data(m,14) = -double(typecast(buff(22:23),'int16')) /1200;
                        data(m,15) = double(typecast(buff(24:25),'int16')) *0.07386 + 31; %temperature
                end
                data(m,16) = double(buff(26)); %PPS_error
                m = m+1; %ָ����һ�洢λ��
                k = k+27; %ָ����һ֡
            else
                k = k+1; %ָ����һ�ֽ�
            end
        else %���ļ�β���˳�
            break
        end
    else
        k = k+1;
    end
    if k>n %���ļ�β���˳�
        break
    end
end

data(m:end,:) = []; %ɾ���հ�����

%% 3.У��cnt��PPS_error
cnt_diff = mod(diff(data(:,1)),256);
if(sum(cnt_diff~=1) ~= 0) %cnt���������1
    error('cnt error!')
end
if(sum(data(:,16)~=data(1,16)) ~= 0) %PPS_error���붼��ͬ
    error('PPS_error error!')
end

% ͳ�Ʋ���ʱ��
sample_time = mod(diff(data(:,8)),10000); %����ʱ�䣬ֻ��Ϊ99,100,101����λ��0.1ms
figure
plot(sample_time)
title('����ʱ��')
sample_time_mean = cumsum(sample_time) ./ (1:length(sample_time))'; %ƽ������ʱ�䣬������Ϊ10ms��ʵ�ʿ����Ը߻��Ե�
figure
plot(sample_time_mean)
grid on
title('ƽ������ʱ��')

%% 4.��ȡimu���ݣ���ʱ���ת��ΪGPSʱ��
n = length(data);
imu_data = zeros(n,7); %IMU����
% [t, wx,wy,wz, fx,fy,fz], deg/s, g
imu_data(:,2:7) = data(:,9:14);
for k=1:n
    c = data(k,2:7); %ʱ������
    c(1) = c(1) + 2000;
    c(4) = c(4) + 8; %ת���ɱ���ʱ��
    if(c(4)>=24) %���ڽ�λ
        c(4) = c(4) - 24;
        c(3) = c(3) + 1;
    end
    [~, gps_second] = gps_time(c);
    imu_data(k,1) = gps_second + data(k,8)/10000; %GPS��
end

% ���ʱ���Ƿ���ȷ
time_diff = diff(imu_data(:,1));
if(sum(time_diff>0.0102)~=0 || sum(time_diff<0.0098)~=0) %����ʱ��Ӧ����10ms
    error('time error!')
end

%% ��imu����
figure
t = imu_data(:,1) - imu_data(1,1);
subplot(3,2,1)
plot(t,imu_data(:,2))
grid on
set(gca, 'xlim', [t(1),t(end)])
subplot(3,2,3)
plot(t,imu_data(:,3))
grid on
set(gca, 'xlim', [t(1),t(end)])
subplot(3,2,5)
plot(t,imu_data(:,4))
grid on
set(gca, 'xlim', [t(1),t(end)])
subplot(3,2,2)
plot(t,imu_data(:,5))
grid on
set(gca, 'xlim', [t(1),t(end)])
subplot(3,2,4)
plot(t,imu_data(:,6))
grid on
set(gca, 'xlim', [t(1),t(end)])
subplot(3,2,6)
plot(t,imu_data(:,7))
grid on
set(gca, 'xlim', [t(1),t(end)])

%% ���
if nargout==1
    varargout{1} = imu_data;
end

end