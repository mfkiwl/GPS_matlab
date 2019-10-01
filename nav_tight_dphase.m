function nav_tight_dphase()
% ����Ϻ������ֱ��ʹ����λ�������⣬�������ٶȼ���ƫ��·���18άģ��
% ��$�Ļ�����ʱ��Ҫ�޸�
% ��α�ࡢα������������receiver_noise.m
% ����λ���������������λ������

% ** ������att_measure.m
% ** ����ǰע�⣺���߳��ȡ����ݷ�Χ���˲�������

% ������ٶȹ�����ë������̬������ƫ���²���˫���߸����ⲻ׼�����ģ�Ҳ�п��ܰ�װ����ԭ�򣬽���λ��R���󣬿���ǿ���ٶ�����
% 0726������֤ͨ��

%% �������� ($)
imu_data = evalin('base', 'imu_data'); %IMU����
ta = evalin('base', 'output_ta(:,1)'); %ʱ������
output_sv = evalin('base', 'output_sv_A'); %������Ϣ��[x,y,z, rho, vx,vy,vz, rhodot]
BLs = evalin('base', 'BLs'); %��̬�������
dphase = evalin('base', 'output_dphase_modified'); %�������������λ��

bl = 1.3; %���߳���
lamda = 299792458 / 1575.42e6; %����

%% ���ݷ�Χ ($)
range = 1:length(ta); %���е�
% range = 1:40000;

%% �������ݽ�ȡ
ta = ta(range);
output_sv = output_sv(:,:,range);
BLs = BLs(range,:);
dphase = dphase(range,:);
index = find(round(imu_data(:,1)*1e4)==round(ta(1)*1e4),1); %IMU��������
imu_data = imu_data(index+(1:length(range))-1,2:7); %ɾ����һ��ʱ��

%% ����洢�ռ�
n = length(ta); %���ݵ���

filter_nav    = zeros(n,9);  %�˲����������
filter_bias   = zeros(n,6);  %��ƫ����
filter_dtr    = zeros(n,1);  %�Ӳ����
filter_dtv    = zeros(n,1);  %��Ƶ�����
filter_tau    = zeros(n,1);  %·�������
filter_P      = zeros(n,18); %���۹��Ʊ�׼��
filter_gps    = zeros(n,11); %ֱ�����ǽ��㣬��������Ǻ���ǡ������Ǻ�·����

%% ��ʼλ��
sv = output_sv(:,:,1);
sv(isnan(sv(:,1)),:) = [];
p0 = pos_solve(sv);
lat = p0(1);
lon = p0(2);
h = p0(3);

%% ��ʼ���˲��� ($)
dt = 0.01;
a = 6371000; %����뾶
para.P = diag([[1,1,1]*1 /180*pi, ...     %��ʼ��̬��rad
               [1,1,1]*1, ...             %��ʼ�ٶ���m/s
               [1/a,secd(lat)/a,1]*5, ... %��ʼλ����[rad,rad,m]
               2e-8 *3e8, ...             %��ʼ�Ӳ���룬m
               3e-9 *3e8, ...             %��ʼ��Ƶ���ٶȣ�m/s
               0.1, ...                   %��ʼ·�����ز�������circ
               [1,1,1]*0.2 /180*pi, ...   %��ʼ��������ƫ��rad/s
               [1,1,1]*2e-3 *9.8])^2;     %��ʼ���ٶȼ���ƫ��m/s^2
para.Q = diag([[1,1,1]*0.15 /180*pi, ...
               ... %��̬һ��Ԥ�ⲻȷ���ȣ�rad/s��ȡ������������׼�
               [1,1,1]*1.5e-3 *9.8, ...
               ... %�ٶ�һ��Ԥ�ⲻȷ���ȣ�m/s/s����Ϊ������ƫ��ȡ���ٶȼ�������׼���������
               [1/a,secd(lat)/a,1]*1.5e-3 *9.8 *(dt/1), ...
               ... %λ��һ��Ԥ�ⲻȷ���ȣ�m/s��ȡ�ٶȲ�ȷ���ȵĻ��ֻ����֣�
               0.03e-9 *3e8 *(dt/1), ...
               ... %�Ӳ����һ��Ԥ�ⲻȷ���ȣ�m/s��ȡ��Ƶ���ٶ�Ư�ƵĻ��ֻ����֣�
               0.03e-9 *3e8, ...
               ... %��Ƶ���ٶ�Ư�ƣ�m/s/s����������þ���͹������߾��ĵ��ڣ�
               0.002, ...
               ... %·����Ư�ƣ�circ/s������ݹ������߾��ĵ��ڣ�
               [1,1,1]*0.01 /180*pi, ...
               ... %��������ƫƯ�ƣ�rad/s/s������ݹ������߾��ĵ��ڣ�
               [1,1,1]*0.1e-3 *9.8])^2 * dt^2;
                   %���ٶȼ���ƫƯ�ƣ�m/s^2/s������ݹ������߾��ĵ��ڣ�
para.R_rho    = 4^2;
para.R_rhodot = 0.04^2;
para.R_dphase = 0.01^2;
NF = navFilter_tight_open_dphase([lat, lon, h], ...
                    [0, 0, 0] + [1, -1, 0.5]*0, ...
                    [BLs(1,1), BLs(1,2), 0] + [1, -1, 1]*0, ...
                    dt, lamda, bl, para);

%% ����
for k=1:n
    % ���µ����˲���
    index = find(~isnan(output_sv(:,1,k))); %�����ݵ�����
    sv = output_sv(index,:,k);
    NF = NF.update(imu_data(k,:), sv, dphase(k,index)');
    
    % �洢�������
    filter_nav(k,1:3) = NF.pos;
    filter_nav(k,4:6) = NF.vel;
    filter_nav(k,7:9) = NF.att;
    filter_bias(k,:) = NF.bias;
    filter_dtr(k) = NF.dtr;
    filter_dtv(k) = NF.dtv;
    filter_tau(k) = NF.tau;
    filter_gps(k,:) = [pos_solve(sv), BLs(k,[1,2,4])];
    
    % P��
    filter_P(k,:) = sqrt(diag(NF.Px)');
    Cnb = angle2dcm(NF.att(1)/180*pi, NF.att(2)/180*pi, NF.att(3)/180*pi);
    C = zeros(3);
    C(1,1) = -Cnb(1,3)*Cnb(1,1) / (Cnb(1,1)^2+Cnb(1,2)^2);
    C(1,2) = -Cnb(1,3)*Cnb(1,2) / (Cnb(1,1)^2+Cnb(1,2)^2);
    C(1,3) = 1;
    C(2,1) = -Cnb(1,2) / sqrt(1-Cnb(1,3)^2);
    C(2,2) =  Cnb(1,1) / sqrt(1-Cnb(1,3)^2);
    C(2,3) = 0;
    C(3,1) = (Cnb(2,2)*Cnb(3,3)-Cnb(3,2)*Cnb(2,3)) / (Cnb(3,3)^2+Cnb(2,3)^2);
    C(3,2) = (Cnb(3,1)*Cnb(2,3)-Cnb(2,1)*Cnb(3,3)) / (Cnb(3,3)^2+Cnb(2,3)^2);
    C(3,3) = 0;
    P = C*NF.Px(1:3,1:3)*C';
    filter_P(k,1:3) = sqrt(diag(P)');
end

%% �������
assignin('base', 'filter_nav',  filter_nav)
assignin('base', 'filter_bias', filter_bias)
assignin('base', 'filter_dtr',  filter_dtr)
assignin('base', 'filter_dtv',  filter_dtv)
assignin('base', 'filter_tau',  filter_tau)
assignin('base', 'filter_P',    filter_P)
assignin('base', 'filter_gps',  filter_gps)
filter_ta = ta;
assignin('base', 'filter_ta',   filter_ta)
filter_imu = imu_data;
assignin('base', 'filter_imu',  filter_imu)

%% ��ͼ
figure_tight_result;

end