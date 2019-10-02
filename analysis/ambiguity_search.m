function ambiguity_search()
% ���е���ģ������������ģ���������ɹ��ʣ�ͬʱ�궨����
% ����������ֻ��ͼ
% �����������ݷ�Χ
% ��$�Ļ�����ʱ��Ҫ�޸�
% ����ǰע�⣺���߳��ȡ����ݷ�Χ

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

%% ���ݷ�Χ ($)
% range = 1:size(output_pos,1); %���е�
range = 1:2000; %�ӵڼ����㵽�ڼ�����

%% �������ݽ�ȡ
output_pos = output_pos(range,:);
output_sv = output_sv(:,:,range);
output_dphase = output_dphase(range,:);

%% ����洢�ռ�
n = size(output_pos,1); %���ݵ���
svN = length(svList); %���Ǹ���

BLs = NaN(n,4); %���߲��������[����ǡ������ǡ����߳��ȡ�·����]��[deg,deg,m,circ]

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
    p = output_dphase(k,:)'; %ԭʼ��λ��
    %----�������ʸ��
    if sum(~isnan(p))>=5
        index = find(~isnan(p)); %����λ���������
        Ac = A(index,:);
        pc = p(index);
        pc = mod(pc,1); %ȡС������
        %----�����ų���ĳЩ����
%         Ac(1,:) = [];
%         pc(1) = [];
        Rx = IAR(Ac, pc, lamda, bl+[-br,br], tr);
    else
        Rx = NaN(4,1);
    end
    %----�洢���
    L = norm(Rx(1:3));         %���߳���
    psi = atan2d(Rx(2),Rx(1)); %���ߺ����
    theta = -asind(Rx(3)/L);   %���߸�����
    BLs(k,:) = [psi,theta,L,Rx(4)];
end

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

end