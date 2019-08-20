% ����imu���������̬
% ��Ҫ��ֹһ��ʱ�䣬����У����ƫ
% ��IMU���ݣ�������imu_data��������̬���㣬��̬��ֵ����0������ǰ��һ�ξ�ֹ���ݼ�����ƫ�������꿴nav����

% ��ǰ��ĵ������ƫ
m = 1:4000;
imu_data(:,2) = imu_data(:,2) - mean(imu_data(m,2));
imu_data(:,3) = imu_data(:,3) - mean(imu_data(m,3));
imu_data(:,4) = imu_data(:,4) - mean(imu_data(m,4));

n = size(imu_data,1);
nav = zeros(n,3);

q = [1;0;0;0]; %��̬��ֵ��ȫ0

for k=1:n
    wb = imu_data(k,2:4) /180*pi;
    q = q + 0.5*[  0,   -wb(1), -wb(2), -wb(3);
                 wb(1),    0,    wb(3), -wb(2);
                 wb(2), -wb(3),    0,    wb(1);
                 wb(3),  wb(2), -wb(1),    0]*q*0.01;
    q = quatnormalize(q')';
    
    [r1,r2,r3] = quat2angle(q');
    nav(k,:) = [r1,r2,r3] /pi*180;
end