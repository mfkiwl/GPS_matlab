t = filter_ta - filter_ta(1);

figure('Position', [400, 80, 650, 800]);

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