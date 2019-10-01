clear;
clc;

%% ����
exe_path = [strtok(cd,':'),':\GNSS\USRP_B210\Release']; %��ִ���ļ�·����strtok(cd,':')�õ��̷�
data_path = fileread('.\temp\dataPath.txt'); %���ݴ洢·��
sample_time = 60*10; %����ʱ�䣬s
channel = 2; %ͨ������                                                                                       
gain = 46; %���棬dB
ref = 1; %�Ƿ�ʹ���ⲿʱ��
pps = 0; %�Ƿ�ʹ���ⲿPPS����ʱ��ʹ��

%% ��������
exe_opt = [exe_path,'\gnss_rx'];
data_opt = [' -p "',data_path,'"'];
name_opt = ' -n';
time_opt = [' -t ',num2str(sample_time)];
gain_opt = [' -g ',num2str(gain)];
if channel==1
    channel_opt = [];
else
    channel_opt = ' -d';
end
if ref==0
    ref_opt = [];
else
    ref_opt = ' -r';
end

cmd = [exe_opt, data_opt, name_opt, time_opt, gain_opt, channel_opt, ref_opt]; %����̨����
system(cmd); %ִ��ϵͳ����

clearvars