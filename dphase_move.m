function dphase_move()
% ��������ϵ����������̬������λ��
% ������������
% ����ǰע�������Ϣ���޸�

%% �������� ($)
svList = evalin('base', 'svList'); %���Ǳ���б�
output_filter = evalin('base', 'output_filter'); %��ϵ����˲������
output_sv = evalin('base', 'output_sv_A'); %������Ϣ��[x,y,z, rho, vx,vy,vz, rhodot]
PDm = evalin('base', 'output_dphase'); %��λ��

%% ������Ϣ ($)
bl = 1.3; %���߳��ȣ�m
lamda = 299792458 / 1575.42e6; %����

%% ����洢�ռ�
n = size(output_filter,1); %���ݵ���
svN = length(svList); %���Ǹ���

PDa = NaN(n,svN); %ʹ����̬�����λ��

%% ����
for k=1:n
    att = output_filter(k,7:9);
    rb = [cosd(att(2))*cosd(att(1)); ...
          cosd(att(2))*sind(att(1)); ...
         -sind(att(2))] * bl;
    pos = output_filter(k,1:3);
    Cen = dcmecef2ned(pos(1), pos(2));
    rp = lla2ecef(pos);
    rs = output_sv(:,1:3,k);
    rsp = ones(svN,1)*rp - rs;
    rho = sum(rsp.*rsp, 2).^0.5;
    rspu = rsp ./ (rho*[1,1,1]);
    A = rspu * Cen';
    PDa(k,:) = (A*rb/lamda)';
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
%----���߻���������λ��
for k=1:svN
    if sum(~isnan(PDm(:,k)))~=0
        plot(PDm(:,k), 'Color',colorTable(k,:), 'LineWidth',1, 'LineStyle','--')
        eval('legend_str = [legend_str; string(num2str(svList(k)))];')
    end
end
%----ʵ�߻����������λ��
for k=1:svN
    if sum(~isnan(PDm(:,k)))~=0
        plot(PDa(:,k), 'Color',colorTable(k,:), 'LineWidth',1)
    end
end
legend(legend_str)
set(gca,'Xlim',[0,n])
title('ʵ����λ���������λ��')

% ��λ��������
dPD = PDm - PDa;
figure
hold on
grid on
for k=1:svN
    if sum(~isnan(PDm(:,k)))~=0
        plot(dPD(:,k), 'Color',colorTable(k,:))
    end
end
legend(legend_str)
set(gca,'Xlim',[0,n])
title('��λ��������')

end