% ���ļ���ѡ��Ի���ѡ���������ڵ��ļ���
% ÿ�δ򿪹���ʱ���У���·��д��.\temp\dataPath.txt
% �����޸ģ��ٴ����д˽ű�
% ���˽ű����ÿ�ݼ�

while 1
    selpath = uigetdir('.', 'ѡ�������ļ�·��');
    if selpath~=0 %���δѡ·��������ѭ��
        break
    end
end

fileID = fopen('.\temp\dataPath.txt', 'w');
fprintf(fileID, '%s', selpath);
fclose(fileID);

clearvars ans fileID selpath