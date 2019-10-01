classdef navFilter_tight_open_dphase_level_nacc
    % 15άģ�ͣ���λ���ˮƽͶӰ��Ϊ���⣬��·����������ٶȼ���ƫ
    % ����ģʽ�����ջ�ʱ��У�����洢���˲�����
    
    % ����״̬�����ջ����ߵ���ƫ��ִ�и��º����
    properties (Access = public)
        % ����״̬����������
        pos     %λ�ã�[lat,lon,h]��[deg,deg,m]
        vel     %�ٶȣ�[ve,vn,vd]��m/s
        att     %��̬��[psi,theta,gamma]��deg
        % ���Ƴ��Ľ��ջ�������У����������
        dtr     %�Ӳs
        dtv     %��Ƶ�s/s
        tau     %·���circ
        % �ߵ���ƫ
        bias    %[gyro,acc]��[deg/s,g]��������
        % �˲�������
        T       %�������ڣ�s
        lamda   %������m
        bl      %���߳��ȣ�m
        Px
        Qx
        R_rho
        R_rhodot
        R_dphase
    end
    
    properties (Access = private)
        % �ߵ������õı���
        latx    %γ�ȣ�rad
        lonx    %���ȣ�rad
        hx      %�߶ȣ�m
        vx      %�ٶȣ�[ve;vn;vd]��m/s����������
        qx      %��Ԫ����[q0,q1,q2,q3]����������
    end
    
    methods
        %--------��ʼ��
        function obj = navFilter_tight_open_dphase_level_nacc(p0, v0, a0, T, lamda, bl, para)
            % p0����ʼλ�ã�deg
            % v0����ʼ�ٶȣ�m/s
            % a0����ʼ��̬��deg
            %----�������
            obj.pos = p0;
            obj.vel = v0;
            obj.att = a0;
            obj.dtr = 0;
            obj.dtv = 0;
            obj.tau = 0;
            obj.bias = [0,0,0,0,0,0];
            %----���ò���
            obj.latx = p0(1)/180*pi;
            obj.lonx = p0(2)/180*pi;
            obj.hx = p0(3);
            obj.vx = v0'; %ת��������
            obj.qx = angle2quat(a0(1)/180*pi, a0(2)/180*pi, a0(3)/180*pi);
            obj.T = T;
            obj.lamda = lamda;
            obj.bl = bl;
            obj.Px = para.P;
            obj.Qx = para.Q;
            obj.R_rho = para.R_rho;
            obj.R_rhodot = para.R_rhodot;
            obj.R_dphase = para.R_dphase;
        end
        
        %--------����
        function obj = update(obj, imu, sv, dphase)
            % imu���ߵ������[deg/s, g]��������
            % sv = [x,y,z, rho, vx,vy,vz, rhodot]
            % dphase����λ�circ����ЧֵΪNaN
            
            %% �ߵ�����
            % 1. ��ƫ����
            imu = imu - obj.bias;
            % 2. �������
            lat = obj.latx;
            lon = obj.lonx;
            h = obj.hx;
            [g, Rm, Rn] = earthPara(lat, h); %���������ʰ뾶
            % 3. ��̬����
            wb = imu(1:3) /180*pi; %deg/s => rad/s
            q = obj.qx; %������
            q = q + (0.5*[  0,   -wb(1), -wb(2), -wb(3);
                          wb(1),    0,    wb(3), -wb(2);
                          wb(2), -wb(3),    0,    wb(1);
                          wb(3),  wb(2), -wb(1),    0]*q'*obj.T)';
            % 4. �ٶȽ���
            Cnb = quat2dcm(q);
            Cbn = Cnb';
            fb = imu(4:6)' *g; %������
            fn = Cbn*fb;
            v0 = obj.vx;
            v = v0 + (fn + [0;0;g])*obj.T; %������
            % 5. λ�ý���
            lat = lat + (v0(1)+v(1))/2/(Rm+h)*obj.T;
            lon = lon + (v0(2)+v(2))/2/(Rn+h)*sec(lat)*obj.T;
            h = h - (v0(3)+v(3))/2*obj.T;
            
            %% ״̬����
            A = zeros(15);
            A(1:3,13:15) = -Cbn;
            A(4:6,1:3) = [0,-fn(3),fn(2); fn(3),0,-fn(1); -fn(2),fn(1),0];
            A(7:9,4:6) = diag([1/(Rm+h), sec(lat)/(Rn+h), -1]);
            A(10,11) = 1;
            Phi = eye(15) + A*obj.T;
            
            %% ���ⷽ��
            % 1. ����ά��
            index = find(isnan(dphase)==0)'; %����λ����к�
            n1 = size(sv,1);                 %α�ࡢα�����������
            n2 = length(index);              %��λ���������
            % 2. ����α��
            rp = lla2ecef([lat/pi*180, lon/pi*180, h]); %���ջ�λ��ʸ����ecef����������
            rs = sv(:,1:3);                             %����λ��ʸ����ecef����������
            rsp = ones(n1,1)*rp - rs;                   %����ָ����ջ���λ��ʸ�����˴�ʹ�þ���˷���repmat���죩
            rho = sum(rsp.*rsp, 2).^0.5;                %�����α��
            rspu = rsp ./ (rho*[1,1,1]);                %����ָ����ջ��ĵ�λʸ����ecef��
            % 3. ����α����
            Cen = [-sin(lat)*cos(lon), -sin(lat)*sin(lon),  cos(lat);
                            -sin(lon),           cos(lon),         0;
                   -cos(lat)*cos(lon), -cos(lat)*sin(lon), -sin(lat)];
            vp = v'*Cen;                                %���ջ��ٶ�ʸ����ecef����������
            vs = sv(:,5:7);                             %�����ٶ�ʸ����ecef����������
            vsp = ones(n1,1)*vp - vs;                   %���ջ�������ǵ��ٶ�ʸ��
            rhodot = sum(vsp.*rspu, 2);                 %�����α����
            % 4. �������
            f = 1/298.257223563;
            F = [-(Rn+h)*sin(lat)*cos(lon), -(Rn+h)*cos(lat)*sin(lon), cos(lat)*cos(lon);
                 -(Rn+h)*sin(lat)*sin(lon),  (Rn+h)*cos(lat)*cos(lon), cos(lat)*sin(lon);
                   (Rn*(1-f)^2+h)*cos(lat),             0,                 sin(lat)    ];
            Ha = rspu*F;
            Hb = rspu*Cen'; %����Ϊ����ϵ������ָ����ջ��ĵ�λʸ��
            U = Hb(index,:);
            J = [-U(2:end,3), eye(n2-1)*U(1,3)]; %J*UʹU�ĵ�����Ϊ0
            Hc = cross(U,ones(n2,1)*Cnb(1,:), 2); %��������
            Hc = Hc * obj.bl/obj.lamda;
            H = zeros(2*n1+n2-1, 15);
            H(1:n1,7:9) = Ha;
            H(1:n1,10) = -ones(n1,1);
            H((n1+1):(2*n1),4:6) = Hb;
            H((n1+1):(2*n1),11) = -ones(n1,1);
            H((2*n1+1):end,1:3) = J*Hc;
            H((2*n1+1):end,12) = -J*ones(n2,1);
            % 5.0 У�����ջ����
            obj.dtr = obj.dtr + obj.dtv*obj.T; %�����Ӳ�
            rho_m    = sv(:,4) - obj.dtr*299792458;
            rhodot_m = sv(:,8) - obj.dtv*299792458;
            dphase_m = dphase - obj.tau;
            % 5. ������
            Z = [rho    - rho_m; ...                              %α����������⣩
                 rhodot - rhodot_m; ...                           %α���ʲ�
              J*(U*Cbn(:,1)*obj.bl/obj.lamda - dphase_m(index))]; %��λ��Ĳ�
            % 6. ��������������
            R = diag([ones(1,n1)*obj.R_rho, ...
                      ones(1,n1)*obj.R_rhodot, ...
                      zeros(1,n2-1)]);
            R((2*n1+1):end,(2*n1+1):end) = J*(eye(n2)*obj.R_dphase)*J';
            
            %% �˲�����
            P = obj.Px;
            Q = obj.Qx;
            P = Phi*P*Phi' + Q;
            K = P*H' / (H*P*H'+R);
            X = K*Z;
            P = (eye(length(X))-K*H)*P;
            obj.Px = (P+P')/2;
            
            %% ��������
            % ����̬
            if norm(X(1:3))>1e-6
                phi = norm(X(1:3));
                qc = [cos(phi/2), X(1:3)'/phi*sin(phi/2)];
                q = quatmultiply(qc, q);
            end
            obj.qx = quatnormalize(q);
            % ���ٶ�
            obj.vx = v - X(4:6);
            % ��λ��
            obj.latx = lat - X(7);
            obj.lonx = lon - X(8);
            obj.hx = h - X(9);
            % �޽��ջ����
            obj.dtr = obj.dtr + X(10)/299792458; %s
            obj.dtv = obj.dtv + X(11)/299792458; %s/s
            obj.tau = obj.tau + X(12); %circ
            % �޹ߵ���ƫ
            obj.bias(1:3) = obj.bias(1:3) + X(13:15)'/pi*180;
            
            %% ���
            obj.pos = [obj.latx/pi*180, obj.lonx/pi*180, obj.hx]; %deg
            obj.vel = obj.vx; %m/s
            [r1,r2,r3] = quat2angle(obj.qx);
            obj.att = [r1,r2,r3]/pi*180; %deg
            
        end %end function
    end %end methods
    
end %end classdef

function [g, Rm, Rn] = earthPara(lat, h)
% ����ģ�Ͳμ�WGS84�ֲ�4-1
% ��gravitywgs84��������ȫһ��
% γ�ȵ�λ��rad

% a = 6378137;
% f = 1/298.257223563;

% Rm = (1-f)^2*a / (1-(2-f)*f*sin(lat)^2)^1.5;
% Rn =         a / (1-(2-f)*f*sin(lat)^2)^0.5;

sin_lat_2 = sin(lat)^2;
Rm = 6335439.32729282 / (1-0.00669437999014*sin_lat_2)^1.5;
Rn = 6378137.00000000 / (1-0.00669437999014*sin_lat_2)^0.5;

% w = 7.292115e-5;
% GM = 3.986004418e14;
% re = 9.7803253359;
% rp = 9.8321849378;

% b = (1-f)*a;
% k = b*rp/(a*re)-1;
% m = w*w*a*a*b/GM;
% e2 = f*(2-f);

% b = 6356752.3142;
% k = 0.00193185265241;
% m = 0.00344978650684;
% e2 = 6.69437999014e-3;

% r = re * (1+k*sin(lat)^2) / (1-e2*sin(lat)^2)^0.5;
% g = r * (1 - 2/a*(1+f+m-2*f*sin(lat)^2)*h + 3/a^2*h^2);

r = 9.7803253359 * (1+0.00193185265241*sin_lat_2) / (1-0.00669437999014*sin_lat_2)^0.5;
g = r * (1 - 3.135711885774796e-07*(1.006802597171588-0.006705621329495*sin_lat_2)*h + 7.374516772941995e-14*h^2);
    
end