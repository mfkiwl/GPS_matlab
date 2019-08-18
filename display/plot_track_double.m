function plot_track_double(sampleFreq, msToProcess, svList, trackResults_A, trackResults_B)
% ��˫���߸��ٽ��
% �����еĴ�����ֱ�Ӵ�ԭ�ű��и������ģ�û��

for k=1:length(svList)
    if trackResults_A(k).n==1 && trackResults_B(k).n==1 %����û���ٵ�ͨ��
        continue
    end
    
    % ����������
    screenSize = get(0,'ScreenSize'); %��ȡ��Ļ�ߴ�
    if screenSize(3)==1920 %������Ļ�ߴ����û�ͼ��Χ
        figure('Position', [390, 280, 1140, 670]);
    elseif screenSize(3)==1368 %SURFACE
        figure('Position', [114, 100, 1140, 670]);
    elseif screenSize(3)==1440 %С��Ļ
        figure('Position', [150, 100, 1140, 670]);
    elseif screenSize(3)==1600 %T430
        figure('Position', [230, 100, 1140, 670]);
    else
        error('Screen size error!')
    end
    ax1 = axes('Position', [0.08, 0.4, 0.38, 0.53]);
    hold(ax1,'on');
    axis(ax1, 'equal');
    title(['PRN = ',num2str(svList(k))])
    ax2 = axes('Position', [0.53, 0.7 , 0.42, 0.25]);
    hold(ax2,'on');
    ax3 = axes('Position', [0.53, 0.38, 0.42, 0.25]);
    hold(ax3,'on');
    ax4 = axes('Position', [0.53, 0.06, 0.42, 0.25]);
    hold(ax4,'on');
    grid(ax4,'on');
    ax5 = axes('Position', [0.05, 0.06, 0.42, 0.25]);
    hold(ax5,'on');
    grid(ax5,'on');
    
    % ��ͼ
    plot(ax1, trackResults_A(k).I_Q(1001:end,1),trackResults_A(k).I_Q(1001:end,4), 'LineStyle','none', 'Marker','.', 'Color',[0,0.447,0.741])
    plot(ax2, trackResults_A(k).dataIndex/sampleFreq, trackResults_A(k).I_Q(:,1), 'Color',[0,0.447,0.741])
    
%     index = find(trackResults_A(k).bitStartFlag==double('H')); %Ѱ��֡ͷ�׶Σ���ɫ��
%     plot(ax2, trackResults_A(k).dataIndex(index)/sampleFreq, trackResults_A(k).I_Q(index,1), 'LineStyle','none', 'Marker','.', 'Color','m')
%     index = find(trackResults_A(k).bitStartFlag==double('C')); %У��֡ͷ�׶Σ���ɫ��
%     plot(ax2, trackResults_A(k).dataIndex(index)/sampleFreq, trackResults_A(k).I_Q(index,1), 'LineStyle','none', 'Marker','.', 'Color','b')
%     index = find(trackResults_A(k).bitStartFlag==double('E')); %���������׶Σ���ɫ��
%     plot(ax2, trackResults_A(k).dataIndex(index)/sampleFreq, trackResults_A(k).I_Q(index,1), 'LineStyle','none', 'Marker','.', 'Color','r')
    %---------------------------------------------------------------------%
    plot(ax1, trackResults_B(k).I_Q(1001:end,1),trackResults_B(k).I_Q(1001:end,4), 'LineStyle','none', 'Marker','.', 'Color',[0.850,0.325,0.098])
    plot(ax3, trackResults_B(k).dataIndex/sampleFreq, trackResults_B(k).I_Q(:,1), 'Color',[0.850,0.325,0.098])
    
%     index = find(trackResults_B(k).bitStartFlag==double('H')); %Ѱ��֡ͷ�׶Σ���ɫ��
%     plot(ax3, trackResults_B(k).dataIndex(index)/sampleFreq, trackResults_B(k).I_Q(index,1), 'LineStyle','none', 'Marker','.', 'Color','m')
%     index = find(trackResults_B(k).bitStartFlag==double('C')); %У��֡ͷ�׶Σ���ɫ��
%     plot(ax3, trackResults_B(k).dataIndex(index)/sampleFreq, trackResults_B(k).I_Q(index,1), 'LineStyle','none', 'Marker','.', 'Color','b')
%     index = find(trackResults_B(k).bitStartFlag==double('E')); %���������׶Σ���ɫ��
%     plot(ax3, trackResults_B(k).dataIndex(index)/sampleFreq, trackResults_B(k).I_Q(index,1), 'LineStyle','none', 'Marker','.', 'Color','r')
    
    plot(ax4, trackResults_A(k).dataIndex/sampleFreq, trackResults_A(k).carrFreq, 'LineWidth',1.5, 'Color',[0,0.447,0.741]) %�ز�Ƶ��
    plot(ax4, trackResults_B(k).dataIndex/sampleFreq, trackResults_B(k).carrFreq, 'LineWidth',1.5, 'Color',[0.850,0.325,0.098])
    
    plot(ax5, trackResults_A(k).dataIndex/sampleFreq, trackResults_A(k).carrAcc, 'Color',[0,0.447,0.741]) %���߷�����ٶ�
    plot(ax5, trackResults_B(k).dataIndex/sampleFreq, trackResults_B(k).carrAcc, 'Color',[0.850,0.325,0.098])
    
    % ����������
    set(ax2, 'XLim',[0,msToProcess/1000])
    set(ax3, 'XLim',[0,msToProcess/1000])

    ax2_ylim = get(ax2, 'YLim');
    ax3_ylim = get(ax3, 'YLim');
    ylim = max(abs([ax2_ylim,ax3_ylim]));
    set(ax2, 'YLim',[-ylim,ylim])
    set(ax3, 'YLim',[-ylim,ylim])
    
    set(ax4, 'XLim',[0,msToProcess/1000])
    set(ax5, 'XLim',[0,msToProcess/1000])
end

end