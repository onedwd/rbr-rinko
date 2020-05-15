% Load the different raw file version
rawFiles = ls('*raw_output*txt');
engFiles = ls('*eng_output*txt');

figure
ax = tight_subplot(2,1,.01,[.05 .05],[.05 .05]);

for ii= 1:length(rawFiles(:,1))
   
    rskR(ii) = RSKreadRENG(rawFiles(ii,:));
    rskE(ii) = RSKreadRENG(engFiles(ii,:));
    axes(ax(1)); 
    plot(rskR(ii).data.values(:,getchannelindex(rsk(ii),'Dissolved O2')));
    hold on
    axes(ax(2));
    plot(rskE(ii).data.values(:,getchannelindex(rsk(ii),'Dissolved O2')));
    hold on
    
end
axes(ax(1))
ylabel('Raw Values Ruskin R-Raw DO (V)')
legend(rawFiles,'Interpreter','none')
axes(ax(2))
ylabel('Eng Values Ruskin R-Eng DO (%)')
legend(engFiles,'Interpreter','none')
print(gcf,'CompareVoltValues_vs_RuskinVersion','-dpng','r300')