function Rx = IAR(A, p, lamda, rho, theta)
% 未知基线长度，限制俯仰角范围，求解基线矢量和路径差
% Integer Ambiguity Resolution
% Rx = [x; y; z; tau]
% A的各行为卫星指向天线的单位矢量
% p为两天线相位差不足整周部分，单位：周
% lamda为波长，单位：m
% rho为基线长度范围，[rho_min,rho_max]，单位：m
% theta为俯仰角范围，[theta_min,theta_max]，单位：deg

% 与高度角最高的做差，排除两天线路径差的影响（双差法）
ele = asind(A(:,3)); %所有卫星高度角
[~,i1] = max(ele); %高度角最高的行
Ac = A - ones(size(A,1),1)*A(i1,:);
Ac(i1,:) = [];
pc = p - p(i1);
pc(i1) = [];

% 与高度角相关的权值（高度角的正弦值）
ele(i1) = [];
W = diag(sind(ele))^3;

% 寻找最佳星座
D_max = 0;
n = size(Ac,1);
for I2=1:(n-2)
    for I3=(I2+1):(n-1)
        for I4=(I3+1):n
            C = [Ac(I2,:); Ac(I3,:); Ac(I4,:)];
            [~,D] = eig(C'*C);
            D = diag(D);
            D = min(D); %特征值的最小值
            if D>D_max %寻找最大值
                D_max = D;
                i2 = I2;
                i3 = I3;
                i4 = I4;
            end
        end
    end
end

% 确定整周模糊度搜索范围
N_max = 2*ceil(rho(2)/lamda); %整周上界，乘2是因为上一步的做差
N_min = -N_max; %整周下界

% 降维搜索（提升计算效率）
pe_min = 100; %存储当前最小的量测误差
r11 = Ac(i2,1);
r12 = Ac(i2,2);
r13 = Ac(i2,3);
r21 = Ac(i3,1);
r22 = Ac(i3,2);
r23 = Ac(i3,3);
r31 = Ac(i4,1);
r32 = Ac(i4,2);
r33 = Ac(i4,3);
f = r23*r12 - r13*r22;
d2 = (r23*r11 - r13*r21) /  f;
e2 = (r22*r11 - r12*r21) / -f;
a = 1 + d2^2 + e2^2; %a>0
for N1=N_min:N_max
    for N2=N_min:N_max
        % 判断方程是否有解
        % r11*x + r12*y + r13*z = s1 = (phi1 + N1)*lamda
        % r21*x + r22*y + r23*z = s2 = (phi2 + N2)*lamda
        % rho(1)^2 <= x^2 + y^2 + z^2 <= rho(2)^2
        s1 = (pc(i2)+N1)*lamda;
        s2 = (pc(i3)+N2)*lamda;
        d1 = (r23*s1 - r13*s2 ) /  f;
        e1 = (r22*s1 - r12*s2 ) / -f;
        b = -2 * (d1*d2 + e1*e2);
        c1 = d1^2 + e1^2 - rho(1)^2;
        c2 = d1^2 + e1^2 - rho(2)^2; %rho(2)>rho(1)，c2<c1
        h1 = b^2-4*a*c1;
        h2 = b^2-4*a*c2; %h为单调递减函数，c2<c1，h2>h1，只要h2<0，h1必然小于零
        if h2<0 %方程无解
            continue
        end
        
        %判断是否有整数的N3
        if h1<=0 %N3为单区间
            x = (-b-sqrt(h2))/(2*a);
            y = d1 - d2*x;
            z = e1 - e2*x;
            N3_e1 = (r31*x + r32*y + r33*z)/lamda - pc(i4); %N3的一个边界
            x = (-b+sqrt(h2))/(2*a);
            y = d1 - d2*x;
            z = e1 - e2*x;
            N3_e2 = (r31*x + r32*y + r33*z)/lamda - pc(i4); %N3的另一个边界
            % 寻找N3两个边界中的整数值
            N3_n = integer_between_edge(N3_e1, N3_e2);
        else %N3为双区间
            x = (-b-sqrt(h1))/(2*a);
            y = d1 - d2*x;
            z = e1 - e2*x;
            N3_e1 = (r31*x + r32*y + r33*z)/lamda - pc(i4); %N3第一区间的一个边界
            x = (-b-sqrt(h2))/(2*a);
            y = d1 - d2*x;
            z = e1 - e2*x;
            N3_e2 = (r31*x + r32*y + r33*z)/lamda - pc(i4); %N3第一区间的另一个边界
            % 寻找N3两个边界中的整数值
            N3_n1 = integer_between_edge(N3_e1, N3_e2);
            %=============================================================%
            x = (-b+sqrt(h1))/(2*a);
            y = d1 - d2*x;
            z = e1 - e2*x;
            N3_e1 = (r31*x + r32*y + r33*z)/lamda - pc(i4); %N3第二区间的一个边界
            x = (-b+sqrt(h2))/(2*a);
            y = d1 - d2*x;
            z = e1 - e2*x;
            N3_e2 = (r31*x + r32*y + r33*z)/lamda - pc(i4); %N3第二区间的另一个边界
            % 寻找N3两个边界中的整数值
            N3_n2 = integer_between_edge(N3_e1, N3_e2);
            %=============================================================%
            N3_n = [N3_n1, N3_n2];
        end
        
        for N3=N3_n
            % 1.计算基线矢量
            R = Ac([i2,i3,i4],:) \ ((pc([i2,i3,i4])+[N1;N2;N3])*lamda);
            % 2.计算所有整周模糊度
            N = round(Ac*R/lamda-pc);
            % 3.最小二乘计算基线矢量
            % R = (A'*A) \ (A'*(p+N)*lamda);
            R = (Ac'*W*Ac) \ (Ac'*W*(pc+N)*lamda); %加权最小二乘
            % 俯仰角限制
            pitch = -asind(R(3)/norm(R));
            if pitch<theta(1) || pitch>theta(2)
                continue
            end
            % 4.比较量测误差
            pe = norm(Ac*R/lamda-N-pc);
            if pe<pe_min
                pe_min = pe;
                Rm = R;
            end
        end
    end
end

% 确定路径差
if exist('Rm', 'var')
    taus = mod(p-A*Rm/lamda,1); %公共误差的小数部分
    n = length(taus);
    for k=2:n %将其他值转到第一个值附近，求均值得到路径差，避免0~1跳变的问题
        if taus(k)-taus(1)<-0.5
            taus(k) = taus(k) + 1;
        end
        if taus(k)-taus(1)>0.5
            taus(k) = taus(k) - 1;
        end
    end
%     tau = mod(mean(taus),1);
    tau = mod(mean(taus)+0.5,1) - 0.5;
    Rx = [Rm; tau];
else
    Rx = [NaN; NaN; NaN; NaN];
end

end

function n = integer_between_edge(e1, e2)
    if e1>e2
        eu = e1; %上界
        ed = e2; %下界
    else
        eu = e2; %上界
        ed = e1; %下界
    end
    n = ceil(ed):floor(eu); %下界向上取整，上界向下取整
end