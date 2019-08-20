function status = GPS_L1_CA_check(ndat)
% GPS��������ÿ���ֵ�У��
% ndatΪ��1���������ù����໷��λģ����ɵĵ�ƽ��ת��32λ��ǰ2λΪ�ϸ��ֵ����2λ
% ��Ϊ1Ϊ-1��-1Ϊ1

%--- Check if the data bits must be inverted ------------------------------
if ndat(2) == -1
    ndat(3:26)= -1 * ndat(3:26);
end

%--- Calculate 6 parity bits ----------------------------------------------
parity(1) = ndat(1)  * ndat(3)  * ndat(4)  * ndat(5)  * ndat(7)  * ...
            ndat(8)  * ndat(12) * ndat(13) * ndat(14) * ndat(15) * ...
            ndat(16) * ndat(19) * ndat(20) * ndat(22) * ndat(25);

parity(2) = ndat(2)  * ndat(4)  * ndat(5)  * ndat(6)  * ndat(8)  * ...
            ndat(9)  * ndat(13) * ndat(14) * ndat(15) * ndat(16) * ...
            ndat(17) * ndat(20) * ndat(21) * ndat(23) * ndat(26);

parity(3) = ndat(1)  * ndat(3)  * ndat(5)  * ndat(6)  * ndat(7)  * ...
            ndat(9)  * ndat(10) * ndat(14) * ndat(15) * ndat(16) * ...
            ndat(17) * ndat(18) * ndat(21) * ndat(22) * ndat(24);

parity(4) = ndat(2)  * ndat(4)  * ndat(6)  * ndat(7)  * ndat(8)  * ...
            ndat(10) * ndat(11) * ndat(15) * ndat(16) * ndat(17) * ...
            ndat(18) * ndat(19) * ndat(22) * ndat(23) * ndat(25);

parity(5) = ndat(2)  * ndat(3)  * ndat(5)  * ndat(7)  * ndat(8)  * ...
            ndat(9)  * ndat(11) * ndat(12) * ndat(16) * ndat(17) * ...
            ndat(18) * ndat(19) * ndat(20) * ndat(23) * ndat(24) * ...
            ndat(26);

parity(6) = ndat(1)  * ndat(5)  * ndat(7)  * ndat(8)  * ndat(10) * ...
            ndat(11) * ndat(12) * ndat(13) * ndat(15) * ndat(17) * ...
            ndat(21) * ndat(24) * ndat(25) * ndat(26);

%--- Compare if the received parity is equal the calculated parity --------
if (sum(parity == ndat(27:32))) == 6
    status = 1; %�ɹ�
else
    status = 0; %ʧ��
end

end