function [rho, rhodot, Cen, rspu, A] = cal_rho_rhodot(rs, vs, pos, vel)
% �������Ǻͽ��ջ�λ�á��ٶȼ�����Ծ��������ٶ�
% pos�����ջ�λ�ã�γ���ߣ���������deg
% vel�����ջ��ٶȣ�����ϵ��������
% rho����Ծ���
% rhodot������ٶȣ���������Ϊ��
% Cen��ecef������ϵ����任��
% A������ϵ������ָ����ջ���λʸ��

n = size(rs,1); %��������

lat = pos(1) /180*pi;
lon = pos(2) /180*pi;
Cen = [-sin(lat)*cos(lon), -sin(lat)*sin(lon),  cos(lat);
                -sin(lon),           cos(lon),         0;
       -cos(lat)*cos(lon), -cos(lat)*sin(lon), -sin(lat)];

rp = lla2ecef(pos);
rsp = ones(n,1)*rp - rs;
rho = sum(rsp.*rsp, 2).^0.5;
rspu = rsp ./ (rho*[1,1,1]);

vp = vel * Cen;
vsp = ones(n,1)*vp - vs;
rhodot = sum(vsp.*rspu, 2);

A = rspu * Cen';

end