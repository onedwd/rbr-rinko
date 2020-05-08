function [axes,handles] = RSKplotdata(RSK, varargin)

% RSKplotdata - Plot a time series of logger data.
%
% Syntax:  [handles] = RSKplotdata(RSK, [OPTIONS])
% 
% Generates a plot displaying the logger data as a time series. If data 
% field has been arranged as profiles (using RSKreadprofiles), then 
% RSKplotdata will plot a time series of a (user selectable) profile upcast
% or downcast. When a particular profile is chosen, but not a cast 
% direction, the function will plot the first direction (downcast or 
% upcast) of the profile only. It also allows plotting cast direction
% (using start and end time from profile field) as patches on top of the
% time series to double check if the profile detection algorithm is working
% properly. 
%
% Inputs:
%    [Required] - RSK - Structure containing the logger metadata and data.
%
%    [Optional] - channel - Longname of channel to plot, can be multiple in
%                       a cell, if no value is given it will plot all
%                       channels.
%
%                 profile - Profile number. Default is 1.
% 
%                 direction - 'up' for upcast, 'down' for downcast. Default
%                       is the first string in RSK.profiles.order; the
%                       first cast.
%
%                 showcast - 1 or 0 to show cast direction or not. Default
%                       is 0. It is recommended to show the cast direction 
%                       patch for time series data only.
%
% Output:
%     axes - Axes object of the plot.
%
%     handles - Line object of the plot.
%
% Example: 
%    RSK = RSKopen('sample.rsk');   
%    RSK = RSKreaddata(RSK);  
%    RSKplotdata(RSK);
%    -OR-
%    handles = RSKplotdata(RSK, 'channel', {'Temperature', 'Conductivity'})
%    -OR-
%    handles = RSKplotdata(RSK, 'channel', 'Pressure', 'showcast', 1);
%
% See also: RSKreadprofiles, RSKplotprofiles, RSKplotdownsample.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2018-05-03

validDirections = {'down', 'up'};
checkDirection = @(x) any(validatestring(x,validDirections));

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addParameter(p, 'channel', 'all');
addParameter(p, 'profile', [], @isnumeric);
addParameter(p, 'direction', [], checkDirection);
addParameter(p, 'showcast', 0, @isnumeric);
parse(p, RSK, varargin{:})

RSK = p.Results.RSK;
channel = p.Results.channel;
profile = p.Results.profile;
direction = p.Results.direction;
showcast = p.Results.showcast;


if ~isfield(RSK,'data')
    error('You must read a section of data in first! Use RSKreaddata...')
end

if length(RSK.data) == 1 && ~isempty(profile)
    error('RSK structure does not contain any profiles, use RSKreadprofiles.')
end

if isempty(profile); profile = 1; end

if showcast == 1;  
    if length(RSK.data) ~= 1;
        error('RSK structure must be time series for showcast, use RSKreaddata.')
    end
    if ~isfield(RSK,'regionCast') || ~isfield(RSK,'profiles')
        error('RSK does not have cast events for profiles, use RSKfindprofiles.')
    end
end

castidx = getdataindex(RSK, profile, direction);
if isfield(RSK, 'profiles') && isfield(RSK.profiles, 'order') && any(strcmp(p.UsingDefaults, 'direction'))
    direction = RSK.profiles.order{1};
    castidx = getdataindex(RSK, profile, direction);
end
if size(castidx,2) ~= 1 
    error('RSKplotdata can only plot one cast and direction. To plot multiple casts or directions, use RSKplotprofiles.')
end
    

pCol = getchannelindex(RSK,'Pressure');
chanCol = [];
channels = cellchannelnames(RSK, channel);
for chan = channels
    chanCol = [chanCol getchannelindex(RSK, chan{1})];
end

if ~ismember(pCol, chanCol) && showcast == 1;
    error('No pressure channel found for showcast, please specify pressure in channel input.')
end

[axes,handles] = channelsubplots(RSK, 'data', 'chanCol', chanCol, 'castidx', castidx);

if isfield(RSK.data,'profilenumber') && isfield(RSK.data,'direction');
    legend(['Profile ' num2str(RSK.data(castidx).profilenumber) ' ' RSK.data(castidx).direction 'cast']);
end

if showcast == 1;      
    pCol = getchannelindex(RSK,'Pressure');
    pmax = max(RSK.data.values(:,pCol));
    
    % Construct vectors of patch vertices from RSK.profiles
    dstart = [RSK.profiles.downcast.tstart]';
    dend   = [RSK.profiles.downcast.tend]';
    ustart = [RSK.profiles.upcast.tstart]';
    uend   = [RSK.profiles.upcast.tend]';
    dpmax = repmat(1.01*pmax,1,length(dstart));
    dpmin = zeros(1,length(dstart));
    upmax = repmat(1.01*pmax,1,length(ustart));
    upmin = zeros(1,length(ustart));

    % Add the patches
    hold on
    hPatch(1) = patch([dstart ; dend ; dend ; dstart],[dpmin ; dpmin ; dpmax ; dpmax],0.9*ones(1,3),'parent',axes(pCol == chanCol));
    hPatch(2) = patch([ustart ; uend ; uend ; ustart],[upmin ; upmin ; upmax ; upmax],0.6*ones(1,3),'parent',axes(pCol == chanCol));
    alpha(hPatch(1),0.2);
    alpha(hPatch(2),0.2);
    [~, L] = legend(hPatch,'downcast','upcast');
    PatchInLegend = findobj(L, 'type', 'patch');
    set(PatchInLegend, 'facea', 0.2);
    zoom on
end

end


