function dnum = RSKtime2datenum(rtime)

%RSKTIME2DATENUM - Convert RSK logger time to MATLAB datenum format.
%
% Syntax:  [dnum] = RSKTIME2DATENUM(rtime)
% 
% Converts 'rtime' as recorded by the logger to MATLAB datenum
% format. 
%
% Inputs:
%    rtime - Raw time read from the RSK file, corresponding to milliseconds
%            elapsed since January 1 1970 (i.e. unix time or POSIX time).  
%
% Outputs:
%    dnum - MATLAB datenum.
%
% Example: 
%    datestr(RSKtime2datenum(1.420070400000000e+12))
% 
%    ans =
%
%    01-Jan-2015
%
% See also: datenum2RSKtime, unixtime2datenum, datenum2unixtime.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-06-21

dnum=unixtime2datenum(rtime/1000);

end
