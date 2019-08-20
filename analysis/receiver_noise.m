function receiver_noise
% �������ջ�α�ࡢα���ʲ�������
% ���ջ���ֹ���������ջ��ο�λ�ã��������ǵ��ο�λ�õľ��������ٶȣ������ֵ��Ƚ�
% ��$�Ļ�����ʱ��Ҫ�޸�

%% �������� ($)
svList = evalin('base', 'svList'); %���Ǳ���б�
sv_info = evalin('base', 'output_sv_A(:,1:8,:)'); %������Ϣ��[x,y,z, rho, vx,vy,vz, rhodot]

%% �ο����� ($)
p0 = [45.73104, 126.62481, 209]; %��γ�ȱ���С�����5λ���߶ȱ���������
rp = lla2ecef(p0); %ecef

%% ���ݷ�Χ ($)
% range = 1:size(sv_info,3); %���е�
range = 1:40000; %�ӵڼ����㵽�ڼ�����

%% �������ݽ�ȡ
sv_info = sv_info(:,:,range);

%% ����洢�ռ�
n = size(sv_info,3); %���ݵ���
svN = length(svList); %���Ǹ���

error_rho = zeros(n,svN); %α����ÿһ��Ϊһ������
error_rhodot = zeros(n,svN); %α�������

%% ����
for k=1:n
    rs = sv_info(:,1:3,k);
    rsp = ones(svN,1)*rp - rs;
    rho = sum(rsp.*rsp, 2).^0.5;
    rspu = rsp ./ (rho*[1,1,1]);
    vs = sv_info(:,5:7,k);
    vsp = 0 - vs;
    rhodot = sum(vsp.*rspu, 2);
    error_rho(k,:) = (sv_info(:,4,k) - rho)'; %����ֵ������ֵ
    error_rhodot(k,:) = (sv_info(:,8,k) - rhodot)';
end

%% �������
% assignin('base', 'error_rho', error_rho);
% assignin('base', 'error_rhodot', error_rhodot);

%% ��ͼ
std_rho = zeros(svN,1); %α��������׼��
std_rhodot = zeros(svN,1); %α����������׼��
for k=1:svN
    x = find(~isnan(error_rho(:,k)));
    y = error_rho(x,k); %��ȡα��ΪNaN�ĵ㣬������ֱ�����
    if ~isempty(x) %û��ֵ�Ĳ���
        figure
        %----��α�����
        subplot(2,2,1)
        plot(error_rho(:,k))
        grid on
        set(gca, 'xlim', [0,n])
        hold on
        p = polyfit(x, y, 1); %ֱ�����
        error_rho_fit = polyval(p, (1:n)'); %��Ϻ�ĵ�
        plot(error_rho_fit) %�����ֱ��
        title(['SV ',num2str(svList(k)),',  column ',num2str(k)]) %���Ǳ�ź��к�
        %----��α������
        subplot(2,2,2)
        plot(error_rho(:,k)-error_rho_fit)
        grid on
        set(gca, 'xlim', [0,n])
        std_rho(k) = std(error_rho(:,k)-error_rho_fit, 'omitnan');
        title(['\sigma=',num2str(std_rho(k),'%.2f')])
        %----��α�������
        subplot(2,2,3)
        plot(error_rhodot(:,k))
        grid on
        set(gca, 'xlim', [0,n])
        std_rhodot(k) = std(error_rhodot(:,k), 'omitnan');
        title(['\mu=',num2str(mean(error_rhodot(:,k),'omitnan'),'%.2f'),',  \sigma=',num2str(std_rhodot(k),'%.3f')])
    end
end
% ����������������׼���һ��Ƚ�
figure
subplot(2,1,1)
bar(1:svN, std_rho)
grid on
title('α��������׼��')
subplot(2,1,2)
bar(1:svN, std_rhodot)
grid on
title('α����������׼��')

end