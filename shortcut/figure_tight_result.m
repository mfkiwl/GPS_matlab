t = filter_ta - filter_ta(1);

%% λ��
figure('Position', [200, 80, 650, 600]);

subplot(3,1,1)
plot(t,filter_gps(:,1))
hold on
grid on
plot(t,filter_nav(:,1))
set(gca,'Xlim',[t(1),t(end)])
title('γ��')

subplot(3,1,2)
plot(t,filter_gps(:,2))
hold on
grid on
plot(t,filter_nav(:,2))
set(gca,'Xlim',[t(1),t(end)])
title('����')

subplot(3,1,3)
plot(t,filter_gps(:,3))
hold on
grid on
plot(t,filter_nav(:,3))
set(gca,'Xlim',[t(1),t(end)])
title('�߶�')

%% �ٶ�
figure('Position', [200, 80, 650, 600]);

subplot(3,1,1)
plot(t,filter_gps(:,4))
hold on
grid on
plot(t,filter_nav(:,4))
set(gca,'Xlim',[t(1),t(end)])
title('�����ٶ�')

subplot(3,1,2)
plot(t,filter_gps(:,5))
hold on
grid on
plot(t,filter_nav(:,5))
set(gca,'Xlim',[t(1),t(end)])
title('�����ٶ�')

subplot(3,1,3)
plot(t,filter_gps(:,6))
hold on
grid on
plot(t,-filter_nav(:,6))
set(gca,'Xlim',[t(1),t(end)])
title('�����ٶ�')

%% ��̬
figure('Position', [200, 80, 650, 600]);

subplot(3,1,1)
plot(t,filter_gps(:,9))
hold on
grid on
plot(t,filter_nav(:,7))
set(gca,'Xlim',[t(1),t(end)])
title('�����')

subplot(3,1,2)
plot(t,filter_gps(:,10))
hold on
grid on
plot(t,filter_nav(:,8))
set(gca,'Xlim',[t(1),t(end)])
title('������')

subplot(3,1,3)
plot(t,filter_nav(:,9), 'Color',[0.85,0.325,0.098])
grid on
set(gca,'Xlim',[t(1),t(end)])
title('��ת��')

%% ʱ��
figure('Position', [200, 80, 650, 600]);

subplot(3,1,1)
plot(t,filter_gps(:,7))
hold on
grid on
plot(t,filter_dtr, 'LineWidth',2)
set(gca,'Xlim',[t(1),t(end)])
title('�Ӳ�')

subplot(3,1,2)
plot(t,filter_gps(:,8))
hold on
grid on
plot(t,filter_dtv, 'LineWidth',2)
set(gca,'Xlim',[t(1),t(end)])
title('��Ƶ��')

subplot(3,1,3)
plot(t,filter_gps(:,11))
hold on
grid on
plot(t,filter_tau, 'LineWidth',2)
set(gca,'Xlim',[t(1),t(end)])
title('·����')

%% ��������ƫ
figure('Position', [200, 80, 650, 600]);

subplot(3,1,1)
plot(t,filter_imu(:,1))
hold on
grid on
plot(t,filter_bias(:,1), 'LineWidth',2)
set(gca,'Xlim',[t(1),t(end)])
set(gca,'Ylim',[-1.5,1.5])
title('x������ƫ')

subplot(3,1,2)
plot(t,filter_imu(:,2))
hold on
grid on
plot(t,filter_bias(:,2), 'LineWidth',2)
set(gca,'Xlim',[t(1),t(end)])
set(gca,'Ylim',[-1.5,1.5])
title('y������ƫ')

subplot(3,1,3)
plot(t,filter_imu(:,3))
hold on
grid on
plot(t,filter_bias(:,3), 'LineWidth',2)
set(gca,'Xlim',[t(1),t(end)])
set(gca,'Ylim',[-1.5,1.5])
title('z������ƫ')

%% ���ٶȼ���ƫ
figure('Position', [200, 80, 650, 600]);

subplot(3,1,1)
plot(t,filter_bias(:,4), 'LineWidth',2)
grid on
set(gca,'Xlim',[t(1),t(end)])
title('x���ٶȼ���ƫ')

subplot(3,1,2)
plot(t,filter_bias(:,5), 'LineWidth',2)
grid on
set(gca,'Xlim',[t(1),t(end)])
title('y���ٶȼ���ƫ')

subplot(3,1,3)
plot(t,filter_bias(:,6), 'LineWidth',2)
grid on
set(gca,'Xlim',[t(1),t(end)])
title('z���ٶȼ���ƫ')