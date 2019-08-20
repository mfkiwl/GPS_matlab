function [a, sigma] = std_rec(a ,x1)
% ���Ƽ������ݱ�׼��
% a.buff
% a.buffSize
% a.buffPoint����ֵ��0
% a.E0
% a.D0

k = a.buffSize; %����ռ��С
n = a.buffPoint + 1; %ָ��ǰ����λ��
x0 = a.buff(n); %��ǰ�����е�����

E0 = a.E0;
D0 = a.D0;

E1 = E0 + (x1-x0)/k;
D1 = D0 + ((x1-E1)^2 - (x0-E0)^2 - 2*(E1-E0)*(E0*k-x0) + (k-1)*(E1^2-E0^2))/k;

a.E0 = E1;
a.D0 = D1;
a.buff(n) = x1;
if n==k
    a.buffPoint = 0;
else
    a.buffPoint = n;
end

sigma = sqrt(D1); %�����ǰ��׼��

end