function print_log(filename, svList)
% ��ӡ��־�ļ��������Ǳ�ŷ���

svList = svList'; %ת����������Ϊ�˽���ѭ��

fileID = fopen(filename, 'r');

for PRN=svList
    fprintf('PRN %d\n', PRN); %ʹ��\r\n���һ������
    
    fseek(fileID, 0, 'bof'); %���ļ�ͷ��ʼ
    while ~feof(fileID) %һֱ�����ļ�β
        tline = fgetl(fileID); %��һ��
        [la, lb] = strtok(tline, ':'); %��:���ֳ�����
        ID = sscanf(la,'%2d'); %ʶ����־�е����Ǳ��
        if ID==PRN
            fprintf([lb(3:end),'\n']);
        end
    end
    
	disp(' ');
end

fclose(fileID);

end