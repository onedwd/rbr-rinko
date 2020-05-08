function [im, data2D, X, Y] = RSKplot2D(RSK, channel, varargin)

% RSKplot2D - Plot profiles in a 2D plot.
%
% Syntax:  [im, data2D, X, Y] = RSKplot2D(RSK, channel, [OPTIONS])
% 
% Generates a plot of the profiles over time. The x-axis is time; the
% y-axis is a reference channel. All data elements must have identical
% reference channel samples. Use RSKbinaverage.m to achieve this. 
%
% Note: If installed, RSKplot2D will use the perceptually uniform oceanographic
%       colourmaps in the cmocean toolbox:
%       https://www.mathworks.com/matlabcentral/fileexchange/57773-cmocean-perceptually-uniform-colormaps
%        
%       http://dx.doi.org/10.5670/oceanog.2016.66        
%
% Inputs:
%   [Required] - RSK - Structure, with profiles as read using RSKreadprofiles.
%
%                channel - Longname of channel to plot (e.g. temperature,
%                      salinity, etc).
%
%   [Optional] - profile - Profile numbers to plot. Default is to use all
%                      available profiles.  
%
%                direction - 'up' for upcast, 'down' for downcast. Default
%                      is down.
%
%                reference - Channel that will be plotted as y. Default
%                      'Sea Pressure', can be any other channel.
%
%                interp - Plotting with interpolated profiles onto a 
%                       regular time grid, so that gaps between each
%                       profile can be shown when set as 1. Default is 0. 
%          
%                threshold - Time threshold in hours to determine the
%                            maximum  gap length shown on the plot. If the 
%                            gap is smaller than threshold, it will not show. 
%
% Output:
%     im - Image object created, use to set properties.
%
%     data2D - Plotted data matrix.
%
%     X - X axis vector in time.
%
%     Y - Y axis vector in sea pressure.
%
% Example: 
%     im = RSKplot2D(RSK,'Temperature','direction','down'); 
%     OR
%     [im, data2D, X, Y] = RSKplot2D(RSK,'Temperature','direction','down','interp',1,'threshold',1);
%
% See also: RSKbinaverage, RSKplotprofiles.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2018-05-09

validDirections = {'down', 'up'};
checkDirection = @(x) any(validatestring(x,validDirections));

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addRequired(p, 'channel');
addParameter(p, 'profile', [], @isnumeric);
addParameter(p, 'direction', 'down', checkDirection);
addParameter(p, 'reference', 'Sea Pressure', @ischar);
addParameter(p,'interp', 0, @isnumeric)
addParameter(p,'threshold', [], @isnumeric)
parse(p, RSK, channel, varargin{:})

RSK = p.Results.RSK;
channel = p.Results.channel;
profile = p.Results.profile;
direction = p.Results.direction;
reference = p.Results.reference;
interp = p.Results.interp;
threshold = p.Results.threshold;


castidx = getdataindex(RSK, profile, direction);
chanCol = getchannelindex(RSK, channel);
YCol = getchannelindex(RSK, reference);
for ndx = 1:length(castidx)-1
    if length(RSK.data(castidx(ndx)).values(:,YCol)) == length(RSK.data(castidx(ndx+1)).values(:,YCol));
        binCenter = RSK.data(castidx(ndx)).values(:,YCol);
    else 
        error('The reference channel data of all the selected profiles must be identical. Use RSKbinaverage.m for selected cast direction.')
    end
end
Y = binCenter;

binValues = NaN(length(binCenter), length(castidx));
for ndx = 1:length(castidx)
    binValues(:,ndx) = RSK.data(castidx(ndx)).values(:,chanCol);
end
t = cellfun( @(x)  min(x), {RSK.data(castidx).tstamp});

if interp == 0;
    data2D = binValues;
    X = t;
    im = pcolor(t, binCenter, binValues);
    shading interp
    set(im, 'AlphaData', isfinite(binValues)); % plot NaN values in white.
else
    unit_time = (t(2)-t(1)); 
    N = round((t(end)-t(1))/unit_time);
    t_itp = linspace(t(1), t(end), N);
    X = t_itp;
    
    ind_mt = bsxfun(@(x,y) abs(x-y), t(:), reshape(t_itp,1,[]));
    [~, ind_itp] = min(ind_mt,[],2); 
    ind_nan = setxor(ind_itp, 1:length(t_itp));

    binValues_itp = interp1(t,binValues',t_itp)';
    binValues_itp(:,ind_nan) = NaN;
    data2D = binValues_itp;
    
    if ~isempty(threshold);
        diff_idx = diff(ind_itp);
        gap_idx = find(diff_idx > 1);

        remove_gap_idx = [];
        for g = 1:length(gap_idx)
            temp_idx = ind_itp(gap_idx(g))+1 : ind_itp(gap_idx(g))+1+diff_idx(gap_idx(g))-2;
            if length(temp_idx)*unit_time*86400 < threshold * 3600; % seconds
                remove_gap_idx = [remove_gap_idx, temp_idx];
            end
        end

        binValues_itp(:,remove_gap_idx) = [];
        t_itp(remove_gap_idx) = [];
        
        im = pcolor(t_itp, binCenter, binValues_itp);
        shading interp
    else
        im = imagesc(t_itp, binCenter, binValues_itp);       
    end 
    set(im, 'AlphaData', isfinite(binValues_itp)); 
end

setcolormap(channel);
cb = colorbar;
ylabel(cb, RSK.channels(chanCol).units)
axis tight

ylabel(cb, RSK.channels(chanCol).units, 'FontSize', 12)
ylabel(sprintf('%s (%s)', RSK.channels(YCol).longName, RSK.channels(YCol).units));
set(gca, 'YDir', 'reverse')

h = title(RSK.channels(chanCol).longName);
p = get(h,'Position');

set(gcf, 'Renderer', 'painters')
set(h, 'EdgeColor', 'none');
datetick('x')

end

