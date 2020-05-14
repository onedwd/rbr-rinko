
%% Read both R-Eng data 20190225_datset
cd('C:\Files\BarretteJ\1_WorkSpace\1_Data\2_Troubleshouting\20200513_ReviewRuskinVersion2.10')
testFiles = ls('Ruskin 2.10\*rsk');
testFiles = regexprep(cellstr(testFiles),'.rsk','');

cd('C:\Files\BarretteJ\1_WorkSpace\1_Data\2_Troubleshouting\20200513_ReviewRuskinVersion2.10')
for ii = 1:length(testFiles)
    % Load file
    ii=10;
    inFileName = testFiles{ii};
    
    % Get 2.9 version
    cd('Ruskin 2.9')
%     R29raw = RSKreadRENG(ls([inFileName,'_raw.txt']));
    R29eng = RSKreadRENG(ls([inFileName,'_eng.txt']));
    
    %Load RSK data from uncorrected 2.9 version and apply Hakai correction
    R29RSK = RSKopen(ls([inFileName,'*rsk']));
    R29RSK = RSKreaddata(R29RSK);
    R29RSK = RSKreadcalibrations(R29RSK);
    R29RSKconstant = RSKreprocessRinkoDO(R29RSK,[],'constantTr'); % Get correction with Constant Tr value
    R29RSKvariable = RSKreprocessRinkoDO(R29RSK,[],'variableTr'); % Retrieve raw and reapply the oxygen equation like normal.
    
    cd('..')
    % Get 2.10 Version
    cd('Ruskin 2.10')
%     R210raw = RSKreadRENG(ls([inFileName,'_raw.txt'])); % Failed for some reasons
    R210eng = RSKreadRENG(ls([inFileName,'_eng.txt']));
    
    % Apply correction to Ruskin2.9 RSK data
    R210RSK = RSKopen(ls([inFileName,'*rsk']));
    R210RSK = RSKreaddata(R210RSK);
    R210RSK = RSKreadcalibrations(R210RSK);
    
    cd('..')
    
    %% Looks some version have a different amount of data
    r29Length = length(R29eng.data.tstamp);
    r210Length = length(R210eng.data.tstamp);
    recLength = min([r29Length, r210Length]);
    
    %% Get version
    RuskinVersion = R29eng.appSettings.ruskinVersion;
    RSK_RuskinVersion = R29RSK.appSettings.ruskinVersion;
    
    %%
    hf = figure;
    ax = tight_subplot(4,1,.02,[.05 .05],[.1 .05]);
    
    axes(ax(1))
    plot(R29eng.data.values(:,end),'.-')
    title({inFileName,['RuskinVersion ',RuskinVersion]},'interpreter','none')
    
    hold on
    plot(R210eng.data.values(:,end),'linewidth',4)
    plot(R29RSK.data.values(:,getchannelindex(R29RSK,'Dissolved O2')),'linewidth',2)
    plot(R210RSK.data.values(:,getchannelindex(R210RSK,'Dissolved O2')))
    
    legend({['Ruskin ',RuskinVersion,' R-Eng'],'Ruskin 2.10 R-Eng',...
        ['RSK ',RSK_RuskinVersion,' Corrected-Hakai'],'RSK 2.10'},...
    'location','SouthEast')
    ylabel('Dissolved Oxygen (%)')
    
    %Original data 
    axes(ax(2))
    plot(R29eng.data.values(1:recLength,end)-R210RSK.data.values(1:recLength,getchannelindex(R210RSK,'Dissolved O2')),'.-')
    if diff(ylim)<0.5
        ylim([-.5 .5])
    end
    ylabel({'Original R-Eng - R2.10','\Delta Perc. DO'})
    
    %Hakai Corrected data
    axes(ax(3))
    plot(R29RSKconstant.data.values(1:recLength,getchannelindex(R29RSK,'Dissolved O2'))-R210RSK.data.values(1:recLength,getchannelindex(R210RSK,'Dissolved O2')),'.-')
    hold on
    plot(R29RSKvariable.data.values(1:recLength,getchannelindex(R29RSK,'Dissolved O2'))-R210RSK.data.values(1:recLength,getchannelindex(R210RSK,'Dissolved O2')),'.-')
    if diff(ylim)<0.5
        ylim([-.5 .5])
    end
    ylabel({'Hakai Corrected - R2.10','\Delta Perc. DO'})
    legend({'Tr=Constant', 'Tr=T/(x6-x7)'});
    
        %REng R2.10
    axes(ax(4))
    plot(R210RSK.data.values(1:recLength,getchannelindex(R210RSK,'Dissolved O2'))-R210RSK.data.values(1:recLength,getchannelindex(R210RSK,'Dissolved O2')),'.-')
    if diff(ylim)<0.5
        ylim([-.5 .5])
    end
    ylabel({'REng2.10 - RSK2.10','\Delta Perc. DO'})    

    xlabel('Record Number #')
    set(ax(1:end-1),'XTickLabel',[])
    set(gcf,'Position',[2    42   958   954])
    
    savefig(hf,[inFileName(1:end-4),'_compareDataFigure.fig'])
    print(hf,[inFileName(1:end-4),'_compareDataFigure'],'-dpng','-r300')
end