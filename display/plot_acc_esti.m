function plot_acc_esti(t, acc_bias, acc_esti, P)
% ����ʱ�������ٶȼ���ƫ���ƽ��
% tΪʱ������
% acc_biasΪ�������õ���ƫ��ֵ���У�g
% acc_estiΪ���Ƶ���ƫ���У�g
% PΪ���۹��Ʊ�׼�m/s^2

P = P/9.8;
P = P*3;

%% �����ٶȼ���ƫ����
figure
subplot(3,1,1)
plot(t, acc_esti(:,1), 'LineWidth',2)
hold on
grid on
axis manual
plot(t, acc_bias(:,1)+P(:,1), 'Color','r', 'LineStyle','--')
plot(t, acc_bias(:,1)-P(:,1), 'Color','r', 'LineStyle','--')
set(gca, 'xlim', [t(1),t(end)])
xlabel('\itt\rm(s)')
ylabel('\it\nabla_x\rm(g)')
title('���ٶȼ���ƫ����')

subplot(3,1,2)
plot(t, acc_esti(:,2), 'LineWidth',2)
hold on
grid on
axis manual
plot(t, acc_bias(:,2)+P(:,2), 'Color','r', 'LineStyle','--')
plot(t, acc_bias(:,2)-P(:,2), 'Color','r', 'LineStyle','--')
set(gca, 'xlim', [t(1),t(end)])
xlabel('\itt\rm(s)')
ylabel('\it\nabla_y\rm(g)')

subplot(3,1,3)
plot(t, acc_esti(:,3), 'LineWidth',2)
hold on
grid on
axis manual
plot(t, acc_bias(:,3)+P(:,3), 'Color','r', 'LineStyle','--')
plot(t, acc_bias(:,3)-P(:,3), 'Color','r', 'LineStyle','--')
set(gca, 'xlim', [t(1),t(end)])
xlabel('\itt\rm(s)')
ylabel('\it\nabla_z\rm(g)')

end