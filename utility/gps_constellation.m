function svList = gps_constellation(varargin)
% ���ݸ�����ʱ���λ���Զ�����GPS���飬����õ�ǰ���п��ܼ����������б�
% �����ָ��ʱ�䣬ʹ�õ�ǰʱ��
% c = [year, month, day, hour, minute, second]
% p = [lat, lon, h], deg

if nargin==1
    c = clock; %��ǰʱ��
    p = varargin{1};
else
    c = varargin{1};
    p = varargin{2};
end

% ����GPS����
[filename, gps_week, gps_second] = download_gps_almanac(c);

% ��������
gps_almanac = read_gps_almanac(filename);

% ����ʱ�䡢λ�ã������������ǵķ�λ�ǡ��߶Ƚ�
sv = sv_azi_ele(gps_almanac, gps_week, gps_second, p);

sv(sv(:,3)<10,:) = []; %���ø߶Ƚ���ֵ��ѡ�����п��ܼ���������
sv(:,2) = mod(sv(:,2),360); %��λ��������0~360

svList = sv(:,1); %������Ǳ��

%% ��ͼ
sv(:,2) = mod(sv(:,2)-90,360)/180*pi; %Ϊ�˻�ͼʱ�����ϣ���λ�Ǽ�90��

figure
polarscatter(sv(:,2),sv(:,3), 220, 'MarkerEdgeColor','g', 'MarkerFaceColor','y');
ax = gca;
ax.RLim = [0 90];
ax.RDir = 'reverse';
ax.ThetaDir = 'clockwise';
ax.RTick = [0 15 30 45 60 75 90];
ax.ThetaTickLabel = {'90','120','150','180','210','240','270','300','330','0','30','60'};

for k=1:size(sv,1)
    text(sv(k,2),sv(k,3),num2str(sv(k,1)), 'HorizontalAlignment','center', 'VerticalAlignment','middle');
end

title(['UTC: ',num2str(c(1)),'-',num2str(c(2)),'-',num2str(c(3)),' ',...
    sprintf('%02d',c(4)),':',sprintf('%02d',c(5)),':',sprintf('%02d',floor(c(6)))]);

end

%% �������Ƿ�λ�ǡ��߶ȽǺ���
function sv = sv_azi_ele(almanac, gps_week, gps_second, p)
%sv = [ID, azimuth, elevation angle]

num = size(almanac,1);
sv = zeros(num,3);
sv(:,1) = almanac(:,1); %ID
toe = almanac(1,8);
t = (gps_week-almanac(1,12))*604800 + (gps_second-toe); %s
miu = 3.986005e14;
w = 7.2921151467e-5;

Cen = dcmecef2ned(p(1), p(2));
rp = lla2ecef([p(1), p(2), p(3)])'; %(ecef)

for k=1:num
    a = almanac(k,2);
    n = sqrt(miu/a^3); %mean motion
    M = mod(almanac(k,7)+n*t, 2*pi); %0-2*pi
    e = almanac(k,3);
    E = kepler(M, e); %0-2*pi
    f = 2*mod(atan(sqrt((1+e)/(1-e))*tan(E/2)), pi); %0-2*pi
    phi = f+almanac(k,6);
    i = almanac(k,4);
    Omega = almanac(k,5) + (almanac(k,9)-w)*t - w*toe;
    
    r = a*(1-e*cos(E));
    x = r*cos(phi);
    y = r*sin(phi);
    rs = [x*cos(Omega)-y*cos(i)*sin(Omega); x*sin(Omega)+y*cos(i)*cos(Omega); y*sin(i)]; %(ecef)
    
    rps = rs-rp; %the vector from p to sv (ecef)
    rpsu = rps/norm(rps); %unit vector (ecef)
    rpsu_n = Cen*rpsu; %(ned)
    
    sv(k,2) = atan2d(rpsu_n(2),rpsu_n(1)); %azimuth, deg
    sv(k,3) = asind(-rpsu_n(3)); %elevation angle, deg
end

end

function E = kepler(M, e)
    E = M;
    Ei = E - (E-e*sin(E)-M)/(1-e*cos(E));
    while abs(Ei-E) > 1e-10
        E = Ei;
        Ei = E - (E-e*sin(E)-M)/(1-e*cos(E));
    end
end