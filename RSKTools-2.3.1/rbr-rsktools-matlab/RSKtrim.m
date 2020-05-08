function [RSK, trimidx] = RSKtrim(RSK, varargin)

% RSKtrim - Remove or replace values that fall in a certain range.
%
% Syntax:  [RSK] = RSKtrim(RSK, [OPTIONS])
% 
% Flags values that fall within the range of the specified reference
% channel, time, or index.  Flagged samples can be replaced with NaN
% or removed or interpolated by neighbouring points.
%
% Inputs: 
%    [Required] - RSK - Input RSK structure
%
%
%    [Optional] - profile - Profile number. Default is to operate
%                       on all profiles.
%
%                 direction - 'up' for upcast, 'down' for downcast, or
%                       'both' for all. Defaults to all directions available.
%
%                 reference - Channel that determines which samples will be
%                       in the range and trimmed.  To trim according to time,
%                       use 'time', or, to trim by index, choose 'index'.  
%
%                 range - A 2 element vector of minimum and maximum
%                       values. The samples in 'reference' that fall within
%                       the range (including the edges) will be trimmed.
%                       If 'reference' is 'time', then range must be in
%                       Matlab datenum format.
%                 
%                 channel - Apply the flag to specified channels.
%                       Default is all channels. When action is set to 
%                       'remove`, specifying channel will not work.
%                           
%                 action - Action to apply to the flagged values.  Can be 
%                       'nan' (default) or 'remove' or 'interp'.
%
%                 visualize - To give a diagnostic plot on specified
%                       profile number(s). Original, processed data and  
%                       flagged data will be plotted to show users how the 
%                       algorithm works. Default is 0.
%
% Outputs:
%    RSK - Structure with trimmed channel values.
%
%    trimidx - Index of trimmed samples.
%
% Example:
%
% Replace data acquired during a shallow surface soak with NaN:
%    RSK = RSKtrim(RSK, 'reference', 'sea pressure', 'range',[-1 1]);
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2018-05-07

validAction = {'remove', 'nan','interp'};
checkAction = @(x) any(validatestring(x,validAction));

validDirections = {'down', 'up', 'both'};
checkDirection = @(x) any(validatestring(x,validDirections));

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addParameter(p, 'profile', [], @isnumeric);
addParameter(p, 'direction', [], checkDirection);
addParameter(p, 'reference', 'index');
addParameter(p, 'range', [], @isnumeric);
addParameter(p, 'channel','all');
addParameter(p, 'action', 'nan', checkAction);
addParameter(p, 'visualize', 0, @isnumeric);
parse(p, RSK, varargin{:})

RSK = p.Results.RSK;
profile = p.Results.profile;
direction = p.Results.direction;
reference = p.Results.reference;
range = p.Results.range;
channel = p.Results.channel;
action = p.Results.action;
visualize = p.Results.visualize;


appliedchanCol = [];
channels = cellchannelnames(RSK, channel);
for chan = channels
    appliedchanCol = [appliedchanCol getchannelindex(RSK, chan{1})];
end
castidx = getdataindex(RSK, profile, direction);

if visualize ~= 0; [raw, diagndx] = checkDiagPlot(RSK, visualize, direction, castidx); end

for ndx =  castidx
    if strcmpi(reference, 'index')
        refdata = 1:size(RSK.data(ndx).values,1);
    elseif strcmpi(reference, 'time')
        refdata = RSK.data(ndx).tstamp;
    else
        channelCol = getchannelindex(RSK, reference);
        refdata = RSK.data(ndx).values(:, channelCol);
    end
    
    % Find indices
    trimindex = refdata >= range(1) & refdata <= range(2);
    nontrimindex = refdata < range(1) | refdata > range(2);
    trimidx(ndx).index = find(trimindex);
    
    switch action
      case 'remove'
        RSK.data(ndx).values(trimindex,:) = [];
        RSK.data(ndx).tstamp(trimindex,:) = [];
      case 'nan'
        RSK.data(ndx).values(trimindex,appliedchanCol) = NaN;
      case 'interp'
        for c = appliedchanCol
            t = RSK.data(ndx).tstamp;
            x = RSK.data(ndx).values(:,c);
            y = x;
            y(trimindex) = interp1(t(nontrimindex), x(nontrimindex), t(trimindex));
            RSK.data(ndx).values(:,c) = y;
        end
    end
    
    if visualize ~= 0      
        for d = diagndx;
            if ndx == d;
                figure
                doDiagPlot(RSK,raw,'index',find(trimindex),'ndx',ndx,'channelidx',appliedchanCol(1),'fn',mfilename); 
            end
        end
    end 

end

% Log entry
logdata = logentrydata(RSK, profile, direction);
logentry = ['Data samples with ' reference ' between ' num2str(range(1)) '  and ' num2str(range(2)) ' trimmed by ' action ' on ' channel ' channels of ' logdata '.'];
RSK = RSKappendtolog(RSK, logentry);

end
