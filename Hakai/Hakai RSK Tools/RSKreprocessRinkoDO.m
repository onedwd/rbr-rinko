function [rsk,hf] = RSKreprocessRinkoDO(rsk,doCalibration,method)



%% Constant Values to be used for voltage 
VOLTAGE_RESOLUTION = 0.001;
VOLTAGE_RANGE = [1 4];
VOLTAGE_VECTOR = [VOLTAGE_RANGE(1):VOLTAGE_RESOLUTION:VOLTAGE_RANGE(2)]';

TR_RESOLUTION = 0.01;
TR_RANGE = [-2 30]; %Could be a flexible range based on the temperature range listed
TR_VECTOR = [TR_RANGE(1):TR_RESOLUTION:TR_RANGE(2)]';

%% If calibration field do not exist in the rsk structure try to get it
if ~exist('doCalibration','var') || isempty(doCalibration)
    if ~isfield(rsk,'calibrations')
        try
            rsk =RSKreadcalibrations(rsk);
        catch
            error('Calibrations not available in the RSK structure and can''t be retrieved');
        end
    else
        %Retrieve calibration from calirations field
        rinkoAvailableEquation = {'corr_rinkoB','corr_rinkoT'};
        calibrationChan = find(ismember({rsk.calibrations.equation},rinkoAvailableEquation));
        doCalibration = rsk.calibrations(calibrationChan);
    end
end

%% Get Uncorrected Dissolved Oxygen Channel related info
%DO uncorrected DO channel
doChanID = getchannelindex(rsk,'Dissolved O2');
tChanID = getchannelindex(rsk,'Temperature');
pChanID = getchannelindex(rsk,'Pressure');

%% Retrieve Raw  Values
%constantTr: a constant Tr value was applied by the CTD firmware with the
%first temperature value recorded by the instrument when the instrument got
%turned on.
%variableTr:  Retrieve the raw volt value if the proper temperature
%correction was applied on the DO Volt data.

switch method
    case 'constantTr'
        %Retrieve Flat Temperature Time Series
        [Tr_Constant,profileStartID] = getFlatTr(rsk,doCalibration);
        DOVolt = NaN(size(rsk.data.tstamp));
        
        %Get voltage equivalent for each temperature values
        for ii = 1:length(profileStartID)
            TrApply = Tr_Constant(profileStartID(ii))*ones(size(VOLTAGE_VECTOR));
            
            
            switch doCalibration.equation
                case 'corr_rinkoT'
                    DOtcomp(:,ii) = corr_rinkoT(VOLTAGE_VECTOR(:),TrApply,doCalibration);
                case 'corr_rinkoB'
                    DOtcomp(:,ii) = corr_rinkoT(VOLTAGE_VECTOR(:),TrApply,doCalibration);
            end
            
            %Add Drift Correction and ignore pressure correction
            DOCorrGridnoP(:,ii) = applyDriftAndPressureCorrection(DOtcomp(:,ii),0,doCalibration);
            
            %Get Records for this profile
            if ii<length(profileStartID)
                presentProfilRecID = profileStartID(ii):[profileStartID(ii+1)-1];
            else
                presentProfilRecID = profileStartID(ii):length(rsk.data.tstamp);
            end
            
            %Remove Pressure Correction from original data
            DO_noPressureCorrection= removePressureCorrection(rsk.data.values(presentProfilRecID,doChanID),rsk.data.values(presentProfilRecID,pChanID),doCalibration);
            
            %Interpolate Value to voltage space
            DOVolt(presentProfilRecID) = interp1(DOCorrGridnoP(:,ii),VOLTAGE_VECTOR,DO_noPressureCorrection,'linear');
            
        end
    case 'variableTr' 
        
        [TR_GRID,VOLTAGE_GRID] = meshgrid(TR_VECTOR,VOLTAGE_VECTOR);
        for ii = 1:length(TR_VECTOR)
            
            switch doCalibration.equation
                case 'corr_rinkoT'
                    DOtcomp(:,ii) = corr_rinkoT(VOLTAGE_VECTOR(:),TR_VECTOR(ii),doCalibration);
                case 'corr_rinkoB'
                    DOtcomp(:,ii) = corr_rinkoT(VOLTAGE_VECTOR(:),TR_VECTOR(ii),doCalibration);
            end
        end

        %Add Drift Correction and ignore pressure correction
        DOCorrGridnoP = applyDriftAndPressureCorrection(DOtcomp,0,doCalibration);
         
        %Compute Tr from temperature time series
        Tr = getTr(rsk,doCalibration);
        
        %Remove Pressure Correction from original data
        DO_noPressureCorrection= removePressureCorrection(rsk.data.values(:,doChanID),rsk.data.values(:,pChanID),doCalibration);
        
        %Interpolate Value to voltage space
%         F = griddedInterpolant(DOCorrGridnoP,TR_GRID,VOLTAGE_GRID);
        F = scatteredInterpolant(DOCorrGridnoP(:),TR_GRID(:),VOLTAGE_GRID(:));
        DOVolt = F(DO_noPressureCorrection,Tr);    
end

% Add Rinko Dissolved Oxygen Raw Voltage back to RSK 
addDo.values = DOVolt;
rsk = RSKaddchannel(rsk,addDo,'Raw Dissolved Oxygen','volt');
doVChan = getchannelindex(rsk,'Raw Dissolved Oxygen');

%% Recalculate the Rinko Oxygen data based appropriate Temperature correction
%Get Temperature correction Tr Values
Tr = getTr(rsk,doCalibration);

%DO compensated values
switch doCalibration.equation
    case 'corr_rinkoT'
        DOtcomp = corr_rinkoT(rsk.data.values(:,doVChan),Tr,doCalibration);
    case 'corr_rinkoB'
        DOtcomp = corr_rinkoT(rsk.data.values(:,doVChan),Tr,doCalibration);
end

%Get DO Corrected value
DOcorr = applyDriftAndPressureCorrection(DOtcomp,rsk.data.values(:,pChanID),doCalibration);

%Move original DO percentage
%to Dissolved O2 Original
doValues.values = rsk.data.values(:,doChanID);
rsk = RSKaddchannel(rsk,doValues,'Dissolved O2:Original','perc');
originalDOChanID = getchannelindex(rsk,'Dissolved O2:Original');

%Apply the corrected values to the Dissolved O2 channel
rsk.data.values(:,doChanID) = DOcorr;

%% Add comments to log
doCalibration.tstamp = datestr(doCalibration.tstamp ,1);
doCalibCell = struct2cell(doCalibration);
doCalibField = [fieldnames(doCalibration)];
hasVal = ~cellfun('isempty',doCalibCell) & ~ismember(doCalibField,{'calibrationID','channelOrder','type'});

doCalibList = [doCalibField(hasVal),doCalibCell(hasVal)];
logString = '';
for ii = 1:length(doCalibList(:,1))
     logString = [logString,doCalibList{ii,1},'='];
    if isnumeric(doCalibList{ii,2})
         logString = [logString,num2str(doCalibList{ii,2},'%1.4E'),'; '];
    else
        logString = [logString,doCalibList{ii,2},'; '];
    end    
end

%Add to processing log
rsk = RSKappendtolog(rsk,logString);

%% Plot comparison figure
if any(ismember({rsk.channels.longName},'Sea Pressure'))
    pressChan = getchannelindex(rsk,'Sea Pressure');
    y_label = 'Sea Pressure';
elseif any(ismember({rsk.channels.longName},'Pressure'))
    pressChan = getchannelindex(rsk,'Pressure');
    y_label = 'Pressure';
end

hf = figure;
ax = tight_subplot(1,2,.05,[.1 .1],[.1 .1]);
axes(ax(1));
plot(rsk.data.tstamp,...
    rsk.data.values(:,doChanID));
hold on
plot(rsk.data.tstamp,...
    rsk.data.values(:,originalDOChanID));
datetick(gca,'x','keeplimits')
ylabel('Dissolved Oxygen Percent of Saturation (%)')

axes(ax(2));
plot(rsk.data.values(:,doChanID),rsk.data.values(:,pressChan));
hold on
plot(rsk.data.values(:,originalDOChanID),rsk.data.values(:,pressChan));
set(ax(2),'YAxisLocation','right','YDir','reverse')
yy = ylim;
ylim([-1 yy(2)])
legend('Corrected Values','Original Values','Location','SouthEast')
xlabel('Dissolved Oxygen Percent of Saturation (%)')
ylabel([y_label,' (',rsk.channels(pressChan).units,')'])

end


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Subfunction areas
%% Compute Slowed Temperature values (Tr)
% Standard Slow Temperature Response Calculation
%As describe at: https://docs.rbr-global.com/L3commandreference/calibration-equations-and-cross-channel-dependencies/dependent-equations/example-5-corr_rinko-correction-of-rinko-dissolved-oxygen-using-rinko-temperature-sensor
function [Tr,newProfileStart] = getTr(rsk,cal,maxDeltaTime)
if ~exist('maxDeltaTime','var')
    maxDeltaTime = 1; %1 seconde
end

%Get Temperature Channel
tChan = getchannelindex(rsk,'Temperature');
T = rsk.data.values(:,tChan);

%Get the start of each segment of when the CTD is running 
newProfileStart = [1;find(diff(rsk.data.tstamp).*24*3600>maxDeltaTime)+1];

%Get Sampling rate
if isfield(rsk,'continuous')
    samplingPeriod = rsk.continuous.samplingPeriod/1000;
elseif isfield(rsk,'schedules')
    samplingPeriod = rsk.schedules.samplingPeriod/1000;
else 
    error('Can''t retrieve the sampling rate')
end

%Compute coefficient K
K = samplingPeriod./(cal.x6-cal.x7);
    
%Start Tr with the first temperature recorded
Tr(1) = T(1); 
for ii = 2:length(T)
    if ismember(ii,newProfileStart) %Restart Tr if New Profile Start
        Tr(ii) = T(ii);
    else
        Tr(ii) = K*T(ii)+(1-K)*Tr(ii-1);
    end
end
Tr=Tr(:);
end

%Bad Temperature Response Calculation that seems to be applied by RBR
function [Tr,newProfileStart] = getFlatTr(rsk,cal,maxDeltaTime)
%Default minimun time interval to detect new profile
if ~exist('maxDeltaTime','var')
    maxDeltaTime = 1; %1 seconde
end

%Get Temperature Channel
tChan = getchannelindex(rsk,'Temperature');
doChan = getchannelindex(rsk,'Dissolved O2');
T = rsk.data.values(:,tChan);

%Get first T Recorded when CTD open, look for time gaps of more than 10s
newProfileStart = [1;find(diff(rsk.data.tstamp).*24*3600>maxDeltaTime)+1];

%If DO record is null, the sensor used the first Temperature associated
%with  a non null record
if any(isnan(rsk.data.values(newProfileStart,doChan)))
    nRec = [1:length(rsk.data.tstamp)]';
    for ii=1:length(newProfileStart)
       newProfileStart(ii) = find(nRec>=newProfileStart(ii) &...
           ~isnan(rsk.data.values(:,doChan)),1,'first');
    end
end

if length(newProfileStart)>1
    Tr = interp1(rsk.data.tstamp(newProfileStart),T(newProfileStart),rsk.data.tstamp,'previous');
else
    Tr = T(newProfileStart).*ones(size(rsk.data.tstamp));
end
end

%% Dissoved Oxygen Transfer equation for Rinko CTDs
%Film A Units
%As describe at: https://docs.rbr-global.com/L3commandreference/calibration-equations-and-cross-channel-dependencies/dependent-equations/example-6-corr_rinkot-correction-of-rinko-dissolved-oxygen-using-logger-temperature-sensor
function DOtcomp = corr_rinkoT(N,Tr,cal)
%N = Raw Dissolved Oxygen Voltage ouput from Rinko 
%Tr= Slowed Temperature Value
alpha = 1+cal.x3.*(Tr-25);
DOtcomp = cal.x0./alpha + cal.x1./((N-cal.x5).*alpha+cal.x2+cal.x5);
end

%Film B units
%As describe at: https://docs.rbr-global.com/L3commandreference/calibration-equations-and-cross-channel-dependencies/dependent-equations/example-11-corr_rinkob-correction-of-rinko-dissolved-oxygen-using-rinko-temperature-sensor
function DOtcomp = corr_rinkoB(N,Tr,cal)
%N = Raw Dissolved Oxygen Voltage ouput from Rinko 
%Tr= Slowed Temperature Value
alpha = 1+cal.x3.*(Tr-25)+cal.x5.*(Tr-25).^2;
DOtcomp = cal.x0./alpha+cal.x1./(N.*alpha+cal.x2);
end

%% Calibration Correction and Pressure correction
% As describe at:
% <https://docs.rbr-global.com/L3commandreference/calibration-equations-and-cross-channel-dependencies/dependent-equations/example-5-corr_rinko-correction-of-rinko-dissolved-oxygen-using-rinko-temperature-sensor>
function DOcorr = applyDriftAndPressureCorrection(DOtcomp,Pressure,cal)
pressureMPa = Pressure.*0.01; %Convert from dBar to MPa
DOcorr = (cal.c0+cal.c1*DOtcomp).*(1+cal.x4.*(pressureMPa));
end

function DOcorrNoP = removePressureCorrection(DOcorr,Pressure,cal)
pressureMPa = Pressure.*0.01; %Convert from dBar to MPa
DOcorrNoP = DOcorr./(1+cal.x4.*(pressureMPa));
end