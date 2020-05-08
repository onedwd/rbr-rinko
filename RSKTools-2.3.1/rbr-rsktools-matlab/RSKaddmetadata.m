function [RSK] = RSKaddmetadata(RSK, varargin)

% RSKaddmetadata - Add metadata information for specified profile(s).
%
% Syntax:  [RSK] = RSKaddmetadata(RSK, [OPTIONS])
% 
% Append station metadata to data structure with profiles, including
% latitude, longitude, station, cruise, vessel, depth, date, weather, crew,
% comment and description. The function is vectorized, which allows 
% multiple metadata inputs for multiple profiles. But when there is only 
% one metadata input for multiple profiles, all profiles will be assigned 
% with the same value.
%
% Inputs: 
%   [Required] - RSK - Structure containing data. 
% 
%   [Optional] - One or more of the following:
%
%                profile - Profile number(s) to which metadata should
%                          be assigned. Defaults to all profiles             
%                latitude - must be of data type numerical
%                longitude - must be of data type numerical
%                station - Nx1 character array or cell array of strings with
%                          length equal to the number of profiles 
%                cruise - character array or cell array of strings
%                vessel - character array or cell array of strings
%                depth - must be of data type numerical
%                date - character array or cell array of strings
%                weather - character array or cell array of strings
%                crew - character array or cell array of strings
%                comment - character array or cell array of strings
%                description - character array or cell array of strings
%        
%
% Outputs:
%    RSK - Updated structure containing metadata for specified profile(s).
%
% Example:
%    RSK = RSKaddmetadata(RSK,'latitude',45,'longitude',-25,...
%                             'station',{'SK1'},'vessel',{'R/V RBR'},...
%                             'cruise',{'Skootamatta Lake 1'})
%    -OR-
%    RSK = RSKaddmetadata(RSK,'profile',4:6,'latitude',[45,44,46],'longitude',...
%    [-25,-24,-23],'comment',{'Comment1','Comment2','Comment3'});
% 
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2018-05-09


p = inputParser;
addRequired(p, 'RSK', @isstruct);
addParameter(p, 'profile', [], @isnumeric);
addParameter(p, 'latitude', [], @isnumeric);
addParameter(p, 'longitude', [], @isnumeric);
addParameter(p, 'station', '');
addParameter(p, 'cruise', '');
addParameter(p, 'vessel', '');
addParameter(p, 'depth', [], @isnumeric);
addParameter(p, 'date', '');
addParameter(p, 'weather', '');
addParameter(p, 'crew', '');
addParameter(p, 'comment', '');
addParameter(p, 'description', '');
parse(p, RSK, varargin{:})

RSK = p.Results.RSK;
profile = p.Results.profile;
latitude = p.Results.latitude;
longitude = p.Results.longitude;
station = p.Results.station;
cruise = p.Results.cruise;
vessel = p.Results.vessel;
depth = p.Results.depth;
date = p.Results.date;
weather = p.Results.weather;
crew = p.Results.crew;
comment = p.Results.comment;
description = p.Results.description;

station = checkcell(station);
cruise = checkcell(cruise);
vessel = checkcell(vessel);
date = checkcell(date);
weather = checkcell(weather);
crew = checkcell(crew);
comment = checkcell(comment);
description = checkcell(description);


if isempty([latitude longitude station comment description])
    warning('No metadata input is found. Please specify at least one metadata field.')
    return
end
    
if length(RSK.data) == 1; RSK = RSKreadprofiles(RSK); end 

castidx = getdataindex(RSK, profile);

directions = 1;
if isfield(RSK.profiles,'order') && length(RSK.profiles.order) ~= 1 
    directions = 2;
end

k = 1;
for i = 1:directions:length(castidx);    
    RSK = assign_metadata(RSK, latitude, castidx, i, directions, k, 'latitude');
    RSK = assign_metadata(RSK, longitude, castidx, i, directions, k, 'longitude');
    RSK = assign_metadata(RSK, station, castidx, i, directions, k, 'station');
    RSK = assign_metadata(RSK, cruise,  castidx, i, directions, k,'cruise');
    RSK = assign_metadata(RSK, vessel,  castidx, i, directions, k,'vessel');
    RSK = assign_metadata(RSK, depth,   castidx, i, directions, k,'depth');
    RSK = assign_metadata(RSK, date,    castidx, i, directions, k,'date');
    RSK = assign_metadata(RSK, weather, castidx, i, directions, k,'weather');
    RSK = assign_metadata(RSK, crew,    castidx, i, directions, k,'crew');
    RSK = assign_metadata(RSK, comment, castidx, i, directions, k, 'comment');
    RSK = assign_metadata(RSK, description, castidx, i, directions, k, 'description');
    k = k + 1;    
end

    %% Nested Functions
    function out = checkcell(in) 
        if isempty(in) || (~isempty(in) && iscell(in))
            out = in;
        else
            out = {in};    
        end
    end

    %% Nested Functions
    function RSK = assign_metadata(RSK, meta, castidx, i, directions, k, name)
    % Assign metadata to data structure
    if ~isempty(meta) && length(meta) == 1; 
        RSK.data(castidx(i)).(name) = meta;
        if directions == 2
            RSK.data(castidx(i+1)).(name) = meta;
        end        
    elseif ~isempty(meta) && length(meta) ~= 1 && length(meta) == length(castidx)/directions;
        RSK.data(castidx(i)).(name) = meta(k);
        if directions == 2
            RSK.data(castidx(i+1)).(name) = meta(k);
        end
    elseif isempty(meta)
        % do nothing
    else
        error('Input vectors must be either single value or the same length with profile.');
    end
    
    end
end