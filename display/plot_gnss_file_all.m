function plot_gnss_file_all(file_path)
% ����ļ��е��������ݣ�ÿ1000���㣨0.25ms����һ����

%% �ڴ�ӳ��汾
% ʹ���ڴ�ӳ������ʱ���ڴ�ռ�ü������ߣ������ǻ�ͼ�������Ҫ��ȫ���ļ�����������ȡ��
% m = memmapfile(file_path, 'Format','int16'); %�ļ��ڴ�ӳ��
% 
% di = 2000; %ÿ��1000����ȡ1����di����ֵҪ��2
% dt = 0.25e-3; %ʱ����
% n = length(m.Data)/di; %�ܹ������ٸ���
% 
% t = (1:n)*dt; %ʱ��������
% figure
% plot(t, m.Data((1:n)*di-1))
% hold on
% plot(t, m.Data((1:n)*di))
% xlabel('\itt\rm(s)')
% grid on

%% �������ļ��汾
listing = dir(file_path); %��ȡ�ļ���Ϣ
di = 1000; %ÿ��1000����ȡ1��
dt = 0.25e-3; %ʱ����
n = listing.bytes/4/di; %�ܹ������ٸ���
data = zeros(2,n); %�洢�����ĵ㣬ʹ��int16�洢ʱ��ͼ�ᱨĪ������Ĵ�

fileID = fopen(file_path, 'r');
for k=1:n
    temp = fread(fileID, [2,di], 'int16');
    data(:,k) = double(temp(:,end));
end
fclose(fileID);

t = (1:n)*dt; %ʱ��������
figure
plot(t, data(1,:)) %ʵ��
hold on
plot(t, data(2,:)) %�鲿
xlabel('\itt\rm(s)')
grid on

end