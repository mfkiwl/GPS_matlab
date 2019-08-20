% �Ƚ������ߵ����������
% ��Ҫ����������IMU5210_data��ADIS16448_data
% IMU5210��������Ҫ5ms��ADIS16448��������Ҫ350us��IMU5210��ʱ��5ms
% IMU5210��Լ��100ms���˲���ʱ

% �Ը��Ե�ʱ���Ϊx�����꣬��ȥ��������ʱ�䣬��ʱ���0��ʼ
t0 = floor(min([IMU5210_data(1,1),ADIS16448_data(1,1)]));
t_IMU5210 = IMU5210_data(:,1) - t0;
t_ADIS16448 = ADIS16448_data(:,1) - t0;

figure
subplot(3,2,1)
plot(t_IMU5210,IMU5210_data(:,2))
hold on
plot(t_ADIS16448,ADIS16448_data(:,2))

subplot(3,2,3)
plot(t_IMU5210,IMU5210_data(:,3))
hold on
plot(t_ADIS16448,ADIS16448_data(:,3))

subplot(3,2,5)
plot(t_IMU5210,IMU5210_data(:,4))
hold on
plot(t_ADIS16448,ADIS16448_data(:,4))

subplot(3,2,2)
plot(t_IMU5210,IMU5210_data(:,5))
hold on
plot(t_ADIS16448,ADIS16448_data(:,5))

subplot(3,2,4)
plot(t_IMU5210,IMU5210_data(:,6))
hold on
plot(t_ADIS16448,ADIS16448_data(:,6))

subplot(3,2,6)
plot(t_IMU5210,IMU5210_data(:,7))
hold on
plot(t_ADIS16448,ADIS16448_data(:,7))