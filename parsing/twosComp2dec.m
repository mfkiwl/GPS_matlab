function intNumber = twosComp2dec(binaryNumber)
% ת�������Ʋ����ַ���Ϊʮ��������

%--- Convert from binary form to a decimal number -------------------------
intNumber = bin2dec(binaryNumber);

%--- If the number was negative, then correct the result ------------------
if binaryNumber(1) == '1'
    intNumber = intNumber - 2^length(binaryNumber);
end

end