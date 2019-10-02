function att_measure()
% ˫������̬��������
% ������������
% ������߲��������BLs
% �����������ģ���ȵ���λ�output_dphase_modified���԰���·���
% �����޸�Ȩֵȷ������
% ��$�Ļ�����ʱ��Ҫ�޸�

%% �������� ($)
svList = evalin('base', 'svList'); %���Ǳ���б�
output_pos = evalin('base', 'output_pos(:,1:3)'); %���ջ�������λ�ã�[lat,lon,h]��deg
output_sv = evalin('base', 'output_sv_A(:,1:8,:)'); %������Ϣ��[x,y,z, rho, vx,vy,vz, rhodot]
output_dphase = evalin('base', 'output_dphase'); %ԭʼ��������λ��

%% ������Ϣ ($)
bl = 1.3; %���»��߳���
br = 0.02; %���߳��ȷ�Χ
tr = [-5,5]; %�����Ƿ�Χ��deg
lamda = 299792458 / 1575.42e6; %����

% ��λ����ֵ��Χ
circ_limit = 1000;
circ_half = circ_limit/2;

%% ����洢�ռ�
n = size(output_pos,1); %���ݵ���
svN = length(svList); %���Ǹ���

BLs = NaN(n,4);   %���߲��������[����ǡ������ǡ����߳��ȡ�·����]��[deg,deg,m,circ]
PDb = NaN(n,svN); %���ݻ��������λ�������λ�
PDm = NaN(n,svN); %����ģ�������������λ�ʵ����λ�

%% ����
N = NaN(svN,1); %����ͨ������λ��������λ������ʱ��ȥ��ֵ
for k=1:n
    pos = output_pos(k,:);
    Cen = dcmecef2ned(pos(1), pos(2));
    rp = lla2ecef(pos);
    rs = output_sv(:,1:3,k);
    rsp = ones(svN,1)*rp - rs;
    rho = sum(rsp.*rsp, 2).^0.5;
    rspu = rsp ./ (rho*[1,1,1]);
    A = rspu * Cen';
    An = [A/lamda, ones(svN,1)]; %��λʸ��ת�����ز�������������ȫΪ1��һ��
    p = output_dphase(k,:)'; %ԭʼ��λ��
    pm = p - N; %�������������λ����ĳ����ûȷ������ģ���ȣ��������λ��ΪNaN
    pm = mod(pm + circ_half, circ_limit) - circ_half; %�鵽0����
    %----�������ʸ��
    if sum(~isnan(pm))<4 %���������λ������С��4�����ܶ���
        if sum(~isnan(p))>=5 %ģ��������
            % ��A��p��ȡ
            index = find(~isnan(p)); %����λ���������
            Ac = A(index,:);
            pc = p(index);
            pc = mod(pc,1); %ȡС������
            %----�����ų���ĳЩ����
%             Ac(1,:) = [];
%             pc(1) = [];
            Rx = IAR(Ac, pc, lamda, bl+[-br,br], tr);
        else
            Rx = NaN(4,1);
        end
    else %���������λ���������ڵ���4������ֱ�Ӷ���
        % ��An��pm��ȡ
        index = find(~isnan(pm)); %����λ���������
        Ac = An(index,:);
        pc = pm(index);
        %----�����ų���ĳЩ����
%         Ac(1,:) = [];
%         pc(1) = [];
        %----��С����
        % Rx = (Ac'*Ac) \ (Ac'*pc);
        %----��Ȩ��С����
        W = diag(Ac(:,3).^3); %�߶Ƚ�Խ��ȨֵԽ��
        Rx = (Ac'*W*Ac) \ (Ac'*W*pc);
    end
    N = round(p-An*Rx); %���¼�������ͨ��������ģ���ȣ��²���ͨ����ֵ�ᱻֱ�Ӽ��㣬�ж�ͨ����ֵ�ᱻ����
    %----�洢���
    L = norm(Rx(1:3));         %���߳���
    psi = atan2d(Rx(2),Rx(1)); %���ߺ����
    theta = -asind(Rx(3)/L);   %���߸�����
    BLs(k,:) = [psi,theta,L,Rx(4)];
    PDb(k,:) = (A*Rx(1:3) / lamda)';
    PDm(k,:) = (mod((p-N) + circ_half, circ_limit) - circ_half)';
end

%% �������
assignin('base', 'BLs', BLs)
assignin('base', 'output_dphase_modified', PDm)

%% �����߲������
figure
subplot(3,1,1)
plot(BLs(:,1))
grid on
set(gca,'Xlim',[0,n])
title('�����')
subplot(3,1,2)
plot(BLs(:,2))
grid on
set(gca,'Xlim',[0,n])
title('������')
subplot(3,1,3)
plot(BLs(:,3))
grid on
set(gca,'Xlim',[0,n])
set(gca,'Ylim',[bl-br,bl+br])
title('���߳���')

%% ����λ��
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
%----���߻����������λ��
for k=1:svN
    if sum(~isnan(PDm(:,k)))~=0
        plot(PDb(:,k), 'Color',colorTable(k,:), 'LineWidth',1, 'LineStyle','--')
    end
end
legend(legend_str)
set(gca,'Xlim',[0,n])
title('ʵ����λ���������λ��')
% ��ȷ�����ʵ����λ���������λ��ֻ�ֵ·����

%% ��ʵ����λ���������λ��֮�� (·����)
% �������ͨ���غϣ�������һ��ֱ����
% �غϱ�ʾ·����һ�£���ֱ�߱�ʾ·�����
figure
hold on
grid on
for k=1:svN
    if sum(~isnan(PDm(:,k)))~=0
        plot(PDm(:,k)-PDb(:,k), 'Color',colorTable(k,:))
    end
end
legend(legend_str)
set(gca,'Xlim',[0,n])
set(gca,'Ylim',[-0.5,0.5])
title('ʵ����λ�� - ������λ��')

end