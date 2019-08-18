function plot_gnss_file(file_path)
% ��ǰ0.1s�����ݣ�400000���㣩

n = 4e5; %0.1s

fileID = fopen(file_path, 'r');
    data = fread(fileID, [2,n], 'int16'); %��������
    t = (1:n)/4e6;
    figure
    plot(t, data(1,:)) %ʵ��
    hold on
    plot(t, data(2,:)) %�鲿
    xlabel('\itt\rm(s)')
fclose(fileID);

end