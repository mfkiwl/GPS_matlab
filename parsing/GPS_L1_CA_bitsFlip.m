function word = GPS_L1_CA_bitsFlip(word, D30)
% ���ݵ�������У����򣬵���һ���ֵ����һ��������1ʱ����һ���ֵ�����λҪ��ת

if D30=='1'
    for k=1:24
        if word(k)=='1'
            word(k) = '0';
        else
            word(k) = '1';
        end
    end
end

end