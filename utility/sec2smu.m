function ts = sec2smu(t)
% ����Ϊ��λ��ʱ��ת��Ϊ[s,ms,us]����

ts = [0,0,0]; %[s,ms,us]

ts(1) = floor(t); %���벿��
t = mod(t,1) * 1000;
ts(2) = floor(t); %���벿��
ts(3) = mod(t,1) * 1000; %΢�벿��

end