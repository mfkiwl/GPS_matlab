% ���Կ��������˲���
clear
clc

%% ����ʱ��
T = 200;        % ��ʱ�䣬s
dt = 0.01;      % ʱ������s
n = T / dt;     % �ܷ������
t = (1:n)'*dt;  % ʱ�����У���������

%% ��������ָ��
sigma_gyro = 0.15;             % ������������׼�deg/s
sigma_acc = 1.5e-3;            % ���ٶȼ�������׼�g
bias_gyro = [0.2, 0, 0.6] *1;  % �����ǳ�ֵ��ƫ��deg/s
bias_acc = [1, 0, 2]*1e-3 *1;  % ���ٶȼƳ�ֵ��ƫ��g

%% ���ջ�����
sigma_rho = 3;            % α�����������׼�m
sigma_rhodot = 0.1;       % α���ʲ���������׼�m/s
sigma_dphase = 0.004;     % ��λ�����������׼�circ
dtr = 1e-8;               % ��ʼ�Ӳs
dtv = 3e-9;               % ��ʼ��Ƶ�s/s
dpath = 0.2;              % ˫����·���circ
c = 299792458;            % ���٣�m/s
lamda = c / 1575.42e6;    % ������m

%% ���ջ�λ��
lat = 46;      % γ�ȣ�deg
lon = 126;     % ���ȣ�deg
h = 200;       % �߶ȣ�m

%% ����
bl_psi = 50;       % ���ߺ���ǣ�deg
bl_theta = 00;     % ���߸����ǣ�deg
bl_gamma = 00;     % ���߹�ת�ǣ�deg
bl_length = 1.3;   % ���߳��ȣ�m

%% ����λ��
% ��һ��Ϊ��λ�ǣ��ڶ���Ϊ�߶Ƚǣ�deg
sv_info = [  0, 45;
            23, 28;
            58, 80;
           100, 49;
           146, 34;
           186, 78;
           213, 43;
           255, 15;
           310, 20];
rho = 20000000; % ���ǵ����ջ��ľ��룬m

%% ��������������
Cnb = angle2dcm(bl_psi/180*pi, ...
                bl_theta/180*pi, ...
                bl_gamma/180*pi);
acc = (Cnb*[0;0;-1])'; % ��ʵ���ٶȣ�g
imu = zeros(n,6);
imu(:,1:3) = ones(n,1)*bias_gyro + ...
             randn(n,3)*sigma_gyro; % �������������ƫ+������deg/s
imu(:,4:6) = ones(n,1)*acc + ...
             ones(n,1)*bias_acc + ...
             randn(n,3)*sigma_acc;  % ���ٶȼ��������ֵ+��ƫ+������g

%% ��������λ�á��ٶȺ���λ��
svN = size(sv_info,1); % ���Ǹ���
sv_real = zeros(svN,9); % �洢������������⣬[x,y,z, rho, vx,vy,vz, rhodot, dpahse]
Cen = dcmecef2ned(lat, lon);
rp = lla2ecef([lat, lon, h]); % ���ջ�λ��ʸ����ecef����������
rb = [ cosd(bl_theta)*cosd(bl_psi), ...
       cosd(bl_theta)*sind(bl_psi), ...
      -sind(bl_theta)] * bl_length; % ����λ��ʸ��������ϵ����������
for k=1:svN
    e = [-cosd(sv_info(k,2))*cosd(sv_info(k,1)), ...
         -cosd(sv_info(k,2))*sind(sv_info(k,1)), ...
          sind(sv_info(k,2))]; % ����ָ����ջ��ĵ�λʸ��������ϵ����������
    rsp = e * rho; % ����ָ����ջ���λ��ʸ��������ϵ��
    sv_real(k,1:3) = rp - (rsp*Cen);  % ����λ��ʸ����ecef��
    sv_real(k,4) = rho;               % α��
    sv_real(k,5:8) = 0;               % �ٶȺ�α����
    sv_real(k,9) = dot(rb,e) / lamda; % ��λ��
end

%% �洢������
output_filter = zeros(n,9);    % �˲����������
output_gps    = zeros(n,8);    % ����ֱ�ӽ������
output_bias   = zeros(n,6);    % ��ƫ����
output_dt     = zeros(n,1);    % �Ӳ�������
output_df     = zeros(n,1);    % ��Ƶ�����
output_dp     = zeros(n,1);    % ·�������
output_P      = zeros(n,18);   % ���۹��Ʊ�׼��

%% ��ʼ�������˲���
a = 6371000; % ����뾶
para.P = diag([[1,1,1]*1 /180*pi, ...     % ��ʼ��̬��rad
               [1,1,1]*1, ...             % ��ʼ�ٶ���m/s
               [1/a,secd(lat)/a,1]*5, ... % ��ʼλ����[rad,rad,m]
               2e-8 *3e8, ...             % ��ʼ�Ӳ���룬m
               3e-9 *3e8, ...             % ��ʼ��Ƶ���ٶȣ�m/s
               0.1, ...                   % ��ʼ·�����ز�������circ
               [1,1,1]*0.2 /180*pi, ...   % ��ʼ��������ƫ��rad/s
               [1,1,1]*2e-3 *9.8])^2;     % ��ʼ���ٶȼ���ƫ��m/s^2
para.Q = diag([[1,1,1]*sigma_gyro /180*pi, ...                 % ��̬һ��Ԥ�ⲻȷ���ȣ�rad/s��ȡ������������׼�
               [1,1,1]*sigma_acc *9.8, ...                     % �ٶ�һ��Ԥ�ⲻȷ���ȣ�m/s/s��ȡ���ٶȼ�������׼�
               [1/a,secd(lat)/a,1]*sigma_acc *9.8 *(dt/1), ... % λ��һ��Ԥ�ⲻȷ���ȣ�m/s��ȡ�ٶȲ�ȷ���ȵĻ��ֻ����֣�
               0.03e-9 *3e8 *(dt/1), ...                       % �Ӳ����һ��Ԥ�ⲻȷ���ȣ�m/s��ȡ��Ƶ���ٶ�Ư�ƵĻ��ֻ����֣�
               0.03e-9 *3e8, ...                               % ��Ƶ���ٶ�Ư�ƣ�m/s/s����������þ���ͷ������߾��ĵ��ڣ�
               0.002, ...                                      % ·����Ư�ƣ�circ/s������ݷ������߾��ĵ��ڣ�
               [1,1,1]*0.01 /180*pi, ...                       % ��������ƫƯ�ƣ�rad/s/s������ݷ������߾��ĵ��ڣ�
               [1,1,1]*0.1e-3 *9.8])^2 * dt^2;                 % ���ٶȼ���ƫƯ�ƣ�m/s^2/s������ݷ������߾��ĵ��ڣ�
para.R_rho    = sigma_rho^2;
para.R_rhodot = sigma_rhodot^2;
para.R_dphase = sigma_dphase^2;
NF = navFilter_open([lat, lon, h], ...
               [0, 0, 0] + [1, -1, 0.5], ...
               [bl_psi, bl_theta, bl_gamma] + [1, -1, 1], ...
               dt, lamda, bl_length, para);

%% ��ʼ����
for k=1:n
    % ������������
    dtr = dtr + dtv*dt; % ��ǰ�Ӳs
    sv = sv_real;
    sv(:,4) = sv(:,4) + randn(svN,1)*sigma_rho    + dtr*c; % α�������
    sv(:,8) = sv(:,8) + randn(svN,1)*sigma_rhodot + dtv*c; % α���ʼ�����
    sv(:,9) = sv(:,9) + randn(svN,1)*sigma_dphase + dpath; % ��λ�������
    
    % ���µ����˲���
    NF = NF.update(imu(k,:), sv);
    
    % �洢�������
    output_filter(k,1:3) = NF.pos;
    output_filter(k,4:6) = NF.vel;
    output_filter(k,7:9) = NF.att;
    output_bias(k,:) = NF.bias;
    output_dt(k) = NF.dtr - dtr;
    output_df(k) = NF.dtv;
    output_dp(k) = NF.tau;
    
    % �洢P��
    output_P(k,:) = sqrt(diag(NF.Px)');
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
    output_P(k,1:3) = sqrt(diag(P)');
end

%% ��ʾ������
%----�����������
traj = zeros(n,9); % ��ʵ�켣����
traj(:,1) = lat;
traj(:,2) = lon;
traj(:,3) = h;
traj(:,7) = bl_psi;
traj(:,8) = bl_theta;
traj(:,9) = bl_gamma;
plot_nav_error(t, traj, output_filter, output_P(:,1:9));
%----��������ƫ��������
plot_gyro_esti(t, ones(n,1)*bias_gyro, output_bias(:,1:3), output_P(:,13:15));
%----���ٶȼ���ƫ��������
plot_acc_esti(t, ones(n,1)*bias_acc, output_bias(:,4:6), output_P(:,16:18));
%----�Ӳ�����������
figure
plot(t, output_dt, 'LineWidth',2)
hold on
grid on
axis manual
plot(t,  output_P(:,10)/299792458*3, 'Color','r', 'LineStyle','--')
plot(t, -output_P(:,10)/299792458*3, 'Color','r', 'LineStyle','--')
set(gca, 'xlim', [t(1),t(end)])
xlabel('\itt\rm(s)')
ylabel('\itdt\rm(s)')
title('�Ӳ�������')
%----��Ƶ���������
figure
plot(t, output_df, 'LineWidth',2)
hold on
grid on
axis manual
plot(t, ones(n,1)*dtv+output_P(:,11)/c*3, 'Color','r', 'LineStyle','--')
plot(t, ones(n,1)*dtv-output_P(:,11)/c*3, 'Color','r', 'LineStyle','--')
set(gca, 'xlim', [t(1),t(end)])
xlabel('\itt\rm(s)')
ylabel('\itdf\rm(s/s)')
title('��Ƶ�����')
%----·�����������
figure
plot(t, output_dp, 'LineWidth',2)
hold on
grid on
axis manual
plot(t, ones(n,1)*dpath+output_P(:,12)*3, 'Color','r', 'LineStyle','--')
plot(t, ones(n,1)*dpath-output_P(:,12)*3, 'Color','r', 'LineStyle','--')
set(gca, 'xlim', [t(1),t(end)])
xlabel('\itt\rm(s)')
ylabel('\itdp\rm(circ)')
title('·�������')