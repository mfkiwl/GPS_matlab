function plot_svdata(data, svList, title_str)
% ��һ�����ݣ�ÿ�ж�Ӧһ�����ǣ�������Ǳ��ͼ��
% svListΪ���Ǳ���б�title_strΪ�����ַ���
% �����ݵ�ֵΪNaN
% ���ĳһ��ȫΪNaN�������ݲ���
% �кŶ�Ӧ�̶�����ɫ��Ŀǰֻ�ܻ�11���ߣ��ٶ���������ɫ

%----��ɫ��
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
                  0,     0,     0;];

figure
hold on
grid on
legend_str = []; %ͼ���ַ������飬string����
for k=1:length(svList)
    if sum(~isnan(data(:,k)))~=0
        plot(data(:,k), 'LineWidth',1, 'Color',colorTable(k,:))
        eval('legend_str = [legend_str; string(num2str(svList(k)))];')
    end
end
legend(legend_str)
title(title_str)

end