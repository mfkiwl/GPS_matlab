function vel_yaw()
% ����ϳ������к󣬱Ƚ��ٶȷ���ͺ���
% ֻ��ͼ�������

%% ��������
vn  = evalin('base', 'output_filter(:,4)'); %�����ٶ�
ve  = evalin('base', 'output_filter(:,5)'); %�����ٶ�
yaw = evalin('base', 'output_filter(:,7)'); %����

n = length(vn);
t = (1:n)'*0.01;

%% ����
v = sqrt(vn.^2 + ve.^2);
vel_yaw = NaN(n,1);

index = find(v>0.4);
vel_yaw(index) = atan2d(ve(index),vn(index)); %�ٶȷ���
yaw_error = vel_yaw - yaw; %�ٶȷ����뺽��֮��
yaw_error = mod(yaw_error+180,360) - 180;

%% ��ͼ
figure
plot(t,v, 'LineWidth',1)
grid on
title('ˮƽ�ٶ�')

figure
plot(t,vel_yaw)
hold on
grid on
plot(t,yaw)
title('����')

figure
plot(t,yaw_error)
grid on
title('�������')

for k=2:n
    if yaw(k)-yaw(k-1)<-180
        yaw(k:end) = yaw(k:end) + 360;
    elseif yaw(k)-yaw(k-1)>180
        yaw(k:end) = yaw(k:end) - 360;
    end
end

figure
stackedplot(t, [v, yaw_error, yaw]);
grid on

end