function out = RSKreadRENG(inFileName)

% function out = RSKreadRENG(inFileName)
%
% This function read the R-ENG files created by Ruskin and convert the
% metadata and data to a structure format compatible with the RSKTools.
%
% Jessy Barrette, 05-Sep-2017


%% Load all the lines in a string format
C = textread(inFileName,'%s','delimiter','\n');

%% Sort Header Info
isHeaderInfo = ~cellfun('isempty',regexp(C,'[\w[]()]+\=[\w[]()°\%\s\.\-]+'));
headerCellRaw = C(isHeaderInfo);

%Correct Characters
headerCell= regexprep(headerCellRaw,'[','('); % Change [ to ( in header to make compatible with MatLab language
headerCell= regexprep(headerCell,']',')');    % Change ] to ) in header to make compatible with MatLab language
headerCell= regexprep(headerCell,'=','=''','once');  % Add " after the = sign to all answers in the header. Assumes all the answers are strings. 
headerCell=strcat(headerCell,''';');          % Add " at the end of each header lines. Assumes all the answers are strings. 

%Remove " " from answers in the header file for which there's only a number
%value.
isJustNumber = ~cellfun('isempty',regexp(headerCell,'''\d+''')) & cellfun('isempty',regexp(headerCell,'Serial'));
headerCell(isJustNumber) = regexprep(headerCell(isJustNumber),'''','');

%Add a in. at the beginning of the lines to create a in.(...) structure.
headerCell = strcat('in.',headerCell);
% Read the header lines header data is now in the "in" structure
for ii = 1:length(headerCell)
   eval(headerCell{ii}) 
end

%Correct channel names
%Dissolved Oxygen There's a typo in the dissolved oxygen name it write ?
%instead of 2
isDOWrong = ~cellfun('isempty',regexp({in.Channel.name},'Dissolved O?'));
if any(isDOWrong)
    in.Channel(isDOWrong).name = 'Dissolved O2';
end

%% Load Data
%Find data lines
isData  = ~isHeaderInfo & ~cellfun('isempty',C);
in.dataCell = C(isData);
isDataHeader = find(~cellfun('isempty',regexp(in.dataCell,'Date & Time')));

%Replace null values by NaN
in.dataCell = regexprep(in.dataCell,'null','NaN');

%If the header of the data isn't the first line, than create an error
if isDataHeader>1
    warning(char(in.dataCell(1:isDataHeader)))
    error('Can''t properly read the header file')
end

%How many columns is there
nCol = length(regexp(in.dataCell{1},'\w+'));

%Get the column names
in.channelNames = textscan(in.dataCell{1},...
    repmat('%s',1,nCol+1),'delimiter',' ','MultipleDelimsAsOne',1);
in.channelNames = [{'Date & Time'},in.channelNames{4:end}];

%Extract the data
for jj = 1:(length(in.dataCell)-1)
in.dataTemp = textscan(char(in.dataCell(jj+1)),...
    ['%s%s',repmat('%f',1,nCol-2)],...
    'delimiter',' ','MultipleDelimsAsOne',1);
in.data.values(jj,:) = [in.dataTemp{3:end}];
in.timeString{jj} = strcat(in.dataTemp{1:2});
end

%Convert time strings to matlab time values
try
    in.data.tstamp = datenum(char([in.timeString{:}]),'yyyy-mm-ddHH:MM:SS.FFF');
catch
    in.data.tstamp = datenum(char([in.timeString{:}]),'dd-mmm-yyyyHH:MM:SS.FFF');
end

%% PARSE TO RSK FORMAT
instrumentID = 1;
deploymentID = 1;

%dbinfo
out.dbInfo.version = regexprep(in.HostVersion,'[a-zA-Z()-]','');
out.dbInfo.type = 'full';

%instrumentChannels

%channels
shortName = in.channelNames(2:in.NumberOfChannels+1)';
longName = {in.Channel.name}';
units = regexprep({in.Channel.units}',' \(.+\)','');
out.channels = cell2struct([shortName,longName,units],{'shortName','longName','units'},2);

%epochs
out.epochs.deploymentID = deploymentID;
out.epochs.startTime = datestr(in.LoggerTime,'dd-mmm-yyyy HH:MM:SS.FFF');
out.epochs.endTime = datestr(in.LoggingEndTime,'dd-mmm-yyyy HH:MM:SS.FFF');

%schedules
out.schedules.scheduleID = 1;
out.schedules.instrumentID = instrumentID;
out.schedules.mode = 'continuous';
if isfield(in,'Event')
    if ~isempty(regexp([in.Event.type],'Twist detected'))
        out.schedules.gate='twist activation';
    else
        out.schedules.gate = 'unknown';
    end
end

%deployment
out.deployments.deploymentID = deploymentID;
out.deployments.instrumentID = instrumentID;
out.deployments.comment = '';
out.deployments.loggerStatus = 'NA';
out.deployments.loggerTimeDrift = 'NA';
out.deployments.timeOfDownload = 'NA';
out.deployments.name = inFileName;
out.deployments.sampleSize = in.NumberOfSamples;

%instrument
out.instruments.instrumentID = instrumentID;
out.instruments.serialID = in.Serial;
out.instruments.model = in.Model;
out.instruments.firmwareVersion = in.Firmware;
out.instruments.firmwareType = 'NA';

%appSettings
out.appSettings.deploymentID = deploymentID;
out.appSettings.ruskinVersion = out.dbInfo.version;

%ranging
iID = repmat({instrumentID},in.NumberOfChannels,1);
cID = num2cell(1:in.NumberOfChannels)';
cOrd= num2cell(1:in.NumberOfChannels)';
if isfield(in.Channel,'rangingMode')
    mode= {in.Channel.rangingMode}';
else
    mode= cellstr(repmat('NA',in.NumberOfChannels,1));
end
gain= cellstr(repmat('NA',in.NumberOfChannels,1));
avGain= cellstr(repmat('NA',in.NumberOfChannels,1));

out.ranging = cell2struct([iID cID cOrd mode gain avGain],...
    {'instrumentID','channelID','channelOrder','mode','gain','availableGains'},2);

%continuous
out.continuous.continousID = 1;
out.continuous.scheduleID = 1;
if ~isempty(regexp(in.LoggingSamplingPeriod,'Hz'))
    samplFreq = str2num(regexprep(in.LoggingSamplingPeriod,'Hz',''));
    out.continuous.samplingPeriod = round(1/samplFreq*1000);
else
    out.continuous.samplingPeriod = in.LoggingSamplingPeriod*1000;
end

% %parameters
% out.parameters.parametersID = 1;
% out.parameters.tstamp = 'NA';

% %parametersKeys
% parmKeys= {1 ,'SPECIFIC_CONDUCTIVITY_TEMPERATURE_CORRECTION','0.0191';...
%     1, 'DISSOLVED_O2_OPTODE_UNIT','mL/L';...
%     1, 'LONGITUDE','0.0';...
%     1, 'OFFSET_FROM_UTC', '0.0';...
%     1,'FETCH_POWER_OFF_DELAY','8000';...
%     1,'DISSOLVED_O2_OXYGUARD_UNIT','mL/L';...
%     1,'ALTITUDE','0.0';...
%     1,'GRAVITY','0.980665';...
%     1,'ATMOSPHERE','10.1325';...
%     1,'DENSITY','1.0281';...
%     1,'PRESSURE','10.1325';
%     1,'CAST_DETECTION','ON';...
%     1,'SPEED_OF_SOUND_EQN_TYPE','UNESCO';...
%     1,'TEMPERATURE','15.0';...
%     1,'CONDUCTIVITY','42.914';...
%     1,'SIMPLIFIED_DEPTH_CALCULATION_TYPE','ON';...
%     1,'AVERAGE_SPEED_OF_SOUND','1550.7440';...
%     1,'DISSOLVED_O2_GENERIC_UNIT','mL/L';...
%     1,'INPUT_TIMEOUT','10000';...
%     1,'DISSOLVED_02_RINKO_UNIT','mg/L';...
%     1,'SALINITY','35.0';...
%     1,'LATITUDE','0.0';...
%     1,'SENSOR_POWER_ALWAYS_ON','off'};
% out.parameterKeys = cell2struct(parmKeys,{'parameterID','key','value'},2);

%thumbnailData(not really needed)

%region

%regionCast

%profiles
%No Profile selected on R-Text Files

%log

%data
out.data = in.data;
out.data.values = out.data.values(:,1:length(out.channels));%Crop Unknown Channels
 
