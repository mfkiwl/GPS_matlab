function [a, xm] = mean_rec(a ,x1)
% ���Ƽ������ݾ�ֵ
% a.buff
% a.buffSize
% a.buffPoint����ֵ��0
% a.E0

k = a.buffSize; %����ռ��С
n = a.buffPoint + 1; %ָ��ǰ����λ��
x0 = a.buff(n); %��ǰ�����е�����

a.E0 = a.E0 + (x1-x0)/k;

a.buff(n) = x1;
if n==k
    a.buffPoint = 0;
else
    a.buffPoint = n;
end

xm = a.E0; %�����ǰ��ֵ

end