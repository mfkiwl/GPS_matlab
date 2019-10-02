for k=1:svN
    %====����A
    t = trackResults_A(k).dataIndex/sampleFreq;
    carrFreq = trackResults_A(k).carrFreq;
    
    carrFreq0 = carrFreq;
    carrFreq0(trackResults_A(k).strength~=0) = NaN;
    
    carrFreq1 = carrFreq;
    carrFreq1(trackResults_A(k).strength~=1) = NaN;
    
    carrFreq2 = carrFreq;
    carrFreq2(trackResults_A(k).strength~=2) = NaN;
    
    figure
    subplot(2,1,1)
    plot(t, carrFreq2, 'LineWidth',2) %ǿ�ź�
    hold on
    plot(t, carrFreq1, 'LineWidth',2) %���ź�
    plot(t, carrFreq0, 'LineWidth',2) %ʧ��
    set(gca, 'XLim',[0,msToProcess/1000])
    
    %====����A
    t = trackResults_B(k).dataIndex/sampleFreq;
    carrFreq = trackResults_B(k).carrFreq;
    
    carrFreq0 = carrFreq;
    carrFreq0(trackResults_B(k).strength~=0) = NaN;
    
    carrFreq1 = carrFreq;
    carrFreq1(trackResults_B(k).strength~=1) = NaN;
    
    carrFreq2 = carrFreq;
    carrFreq2(trackResults_B(k).strength~=2) = NaN;
    
    subplot(2,1,2)
    plot(t, carrFreq2, 'LineWidth',2) %ǿ�ź�
    hold on
    plot(t, carrFreq1, 'LineWidth',2) %���ź�
    plot(t, carrFreq0, 'LineWidth',2) %ʧ��
    set(gca, 'XLim',[0,msToProcess/1000])
end

clearvars t carrFreq carrFreq0 carrFreq1 carrFreq2