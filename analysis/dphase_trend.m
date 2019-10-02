function dphase_trend()
% ��֪���ߣ�����ʱ����λ��������ƶԲ���
% ������������
% ֻ��ͼ�����
% ��������̬��������
% ��$�Ļ�����ʱ��Ҫ�޸�

%% �������� ($)
svList = evalin('base', 'svList'); %���Ǳ���б�
output_pos = evalin('base', 'output_pos(:,1:3)'); %���ջ�������λ�ã�[lat,lon,h]��deg
output_sv = evalin('base', 'output_sv_A(:,1:8,:)'); %������Ϣ��[x,y,z, rho, vx,vy,vz, rhodot]
PDm = evalin('base', 'output_dphase_modified'); %�������������λ��

%% �ο����� ($)
BLr = [7.8, -0.5, 1.3];
Rr = [cosd(BLr(2))*cosd(BLr(1)); cosd(BLr(2))*sind(BLr(1)); -sind(BLr(2))] * BLr(3);
lamda = 299792458 / 1575.42e6; %����

%% ����洢�ռ�
n = size(output_pos,1); %���ݵ���
svN = length(svList); %���Ǹ���

PDr = NaN(n,svN); %ʹ�òο����������λ��

%% ����
for k=1:n
    pos = output_pos(k,:);
    Cen = dcmecef2ned(pos(1), pos(2));
    rp = lla2ecef(pos);
    rs = output_sv(:,1:3,k);
    rsp = ones(svN,1)*rp - rs;
    rho = sum(rsp.*rsp, 2).^0.5;
    rspu = rsp ./ (rho*[1,1,1]);
    A = rspu * Cen';
    PDr(k,:) = (A*Rr / lamda)';
end

%% ��ͼ
colorTable = [    0, 0.447, 0.741;
              0.850, 0.325, 0.098;
              0.929, 0.694, 0.125;
              0.494, 0.184, 0.556;
              0.466, 0.674, 0.188;
              0.301, 0.745, 0.933;
              0.635, 0.078, 0.184;
                  0,     0,     1;
                  1,     0,     0;
                  0,     1,     0;
                  0,     0,     0];
figure
hold on
grid on
legend_str = [];
%----ʵ�߻���������λ��
for k=1:svN
    if sum(~isnan(PDm(:,k)))~=0
        plot(PDm(:,k), 'Color',colorTable(k,:), 'LineWidth',1)
        eval('legend_str = [legend_str; string(num2str(svList(k)))];')
    end
end
%----���߻��ο����������λ��
for k=1:svN
    if sum(~isnan(PDm(:,k)))~=0
        plot(PDr(:,k), 'Color',colorTable(k,:), 'LineWidth',1, 'LineStyle','--')
    end
end
legend(legend_str)
set(gca,'Xlim',[0,n])
title('ʵ����λ����ο���λ��')

end