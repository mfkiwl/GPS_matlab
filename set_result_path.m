% ���ļ���ѡ��Ի���ѡ�����н���洢���ļ���
% ÿ�δ򿪹���ʱ���У���·��д��.\temp\resultPath.txt
% �����޸ģ��ٴ����д˽ű�
% ���˽ű����ÿ�ݼ�

while 1
    selpath = uigetdir('.', 'ѡ�����洢·��');
    if selpath~=0 %���δѡ·��������ѭ��
        break
    end
end

fileID = fopen('.\temp\resultPath.txt', 'w');
fprintf(fileID, '%s', selpath);
fclose(fileID);

clearvars ans fileID selpath