function plot_nav_error(t, traj, nav, P)
% ����ʱ�����������
% tΪʱ������
% trajΪ��ʵ�켣
% navΪ�������
% [lat,lon,h, ve,vn,vd, psi,theta,gamma]
% [deg,deg,m,    m/s,        deg]
% PΪ���۹��Ʊ�׼�1~3Ϊ��̬�ǣ�4~6Ϊ�ٶȣ�7~9Ϊλ��
% ʧ׼�ǵ���̬�ǵı�׼��任��������

nav_error = nav - traj; %�������
nav_error(:,7:9) = mod(nav_error(:,7:9)+180,360)-180; %��̬���ת����180

P(:,1:3) = P(:,1:3)/pi*180;
P(:,7:8) = P(:,7:8)/pi*180;
P = P*3;

%% ��λ�����
figure
subplot(3,1,1)
plot(t, nav_error(:,1), 'LineWidth',2)
hold on
grid on
axis manual
plot(t,  P(:,7), 'Color','r', 'LineStyle','--')
plot(t, -P(:,7), 'Color','r', 'LineStyle','--')
set(gca, 'xlim', [t(1),t(end)])
xlabel('\itt\rm(s)')
ylabel('\delta\itL\rm(\circ)')
title('λ�����')

subplot(3,1,2)
plot(t, nav_error(:,2), 'LineWidth',2)
hold on
grid on
axis manual
plot(t,  P(:,8), 'Color','r', 'LineStyle','--')
plot(t, -P(:,8), 'Color','r', 'LineStyle','--')
set(gca, 'xlim', [t(1),t(end)])
xlabel('\itt\rm(s)')
ylabel('\delta\lambda(\circ)')

subplot(3,1,3)
plot(t, nav_error(:,3), 'LineWidth',2)
hold on
grid on
axis manual
plot(t,  P(:,9), 'Color','r', 'LineStyle','--')
plot(t, -P(:,9), 'Color','r', 'LineStyle','--')
set(gca, 'xlim', [t(1),t(end)])
xlabel('\itt\rm(s)')
ylabel('\delta\ith\rm(m)')

%% ���ٶ����
figure
subplot(3,1,1)
plot(t, nav_error(:,4), 'LineWidth',2)
hold on
grid on
axis manual
plot(t,  P(:,4), 'Color','r', 'LineStyle','--')
plot(t, -P(:,4), 'Color','r', 'LineStyle','--')
set(gca, 'xlim', [t(1),t(end)])
xlabel('\itt\rm(s)')
ylabel('\delta\itv_n\rm(m/s)')
title('�ٶ����')

subplot(3,1,2)
plot(t, nav_error(:,5), 'LineWidth',2)
hold on
grid on
axis manual
plot(t,  P(:,5), 'Color','r', 'LineStyle','--')
plot(t, -P(:,5), 'Color','r', 'LineStyle','--')
set(gca, 'xlim', [t(1),t(end)])
xlabel('\itt\rm(s)')
ylabel('\delta\itv_e\rm(m/s)')

subplot(3,1,3)
plot(t, nav_error(:,6), 'LineWidth',2)
hold on
grid on
axis manual
plot(t,  P(:,6), 'Color','r', 'LineStyle','--')
plot(t, -P(:,6), 'Color','r', 'LineStyle','--')
set(gca, 'xlim', [t(1),t(end)])
xlabel('\itt\rm(s)')
ylabel('\delta\itv_d\rm(m/s)')

%% ����̬���
figure
subplot(3,1,1)
plot(t, nav_error(:,7), 'LineWidth',2)
hold on
grid on
axis manual
plot(t,  P(:,1), 'Color','r', 'LineStyle','--')
plot(t, -P(:,1), 'Color','r', 'LineStyle','--')
set(gca, 'xlim', [t(1),t(end)])
xlabel('\itt\rm(s)')
ylabel('\delta\psi(\circ)')
title('��̬���')

subplot(3,1,2)
plot(t, nav_error(:,8), 'LineWidth',2)
hold on
grid on
axis manual
plot(t,  P(:,2), 'Color','r', 'LineStyle','--')
plot(t, -P(:,2), 'Color','r', 'LineStyle','--')
set(gca, 'xlim', [t(1),t(end)])
xlabel('\itt\rm(s)')
ylabel('\delta\theta(\circ)')

subplot(3,1,3)
plot(t, nav_error(:,9), 'LineWidth',2)
hold on
grid on
axis manual
plot(t,  P(:,3), 'Color','r', 'LineStyle','--')
plot(t, -P(:,3), 'Color','r', 'LineStyle','--')
set(gca, 'xlim', [t(1),t(end)])
xlabel('\itt\rm(s)')
ylabel('\delta\gamma(\circ)')

end