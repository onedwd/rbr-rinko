%% RSKtools for Matlab access to RBR data
% RSKtools v2.3.0;
% RBR Ltd. Ottawa ON, Canada;
% support@rbr-global.com;
% 2018-05-09

%% Introduction 
% |RSKtools| is RBR's open source Matlab tool box for visualizing and
% post-processing RBR logger data. It provides high-speed access to
% large RSK data files. Users may plot data as a time series or as
% depth profiles using tailored plotting utilities. Time-depth heat
% maps can be plotted easily for repeated profiles. A full suite of
% data post-processing functions, such as functions to match sensor
% time constants and bin average, are available to enhance data
% quality.  RBR is continually expanding RSKtools, and we value
% feedback from users so that we can make it better.

        
%% Installing
% The latest stable version of |RSKtools| can be found at
% <http://www.rbr-global.com/support/matlab-tools>.
% 
% * Download and unzip the archive (to |~/matlab/RSKtools|, for instance) 
% * Add the folder to your path from the command line (|addpath ~/matlab/RSKtools|) or launch the path editor gui (|pathtool|). 
% * type |help RSKtools| to get an overview and take a look at the examples.

  
%% Examples of use
% <html><h3>Loading files</h3></html>
% 
% The first step is to make a connection to the RSK file with
% |RSKopen|. Note that |RSKopen| does not actually read the data;
% instead it reads a "thumbnail" of the data, which is up to 4000
% samples long. 

file = '../sample.rsk';
rsk = RSKopen(file);


%%
% The structure returned after opening an RSK looks something like:
disp(rsk)

%%
% To read the full dataset, use the |RSKreaddata| function.
% RSKreaddata will read the full dataset by default.  Because RSK
% files can store a large amount of data, it may be preferable to read
% a subset of the data, specified using a start and end time (in
% Matlab |datenum| format, which is defined as the number of days
% since January 0, 0000).

t1 = datenum(2014, 05, 03);
t2 = datenum(2014, 05, 04);
rsk = RSKreaddata(rsk, 't1', t1, 't2', t2);

%%
% Note that the logger data can be found in the structure at:

rsk.data        

%%
% where |rsk.data.tstamp| contains the sample timestamps in Matlab
% datenum format, and |rsk.data.values| contains the data.  Each
% column in |rsk.data.values| contains data from a different channel.
% The channel names and units for each column in |data| are:

[{rsk.channels.longName}' {rsk.channels.units}']


%% Working with profiles
% Profiling loggers with recent versions of firmware can detect and
% record profile upcast and downcast "events" automatically. The
% function |RSKreadprofiles| uses the profile event time stamps to
% organize the data into profiles. Then, a plot of the profiles can be
% made very easily using the |RSKplotprofiles| function.  For
% example, to read the upcast and downcast of profiles 6 to 8 from
% the sample data set, run:
rsk = RSKreadprofiles(rsk, 'profile', 6:8, 'direction', 'both');

%%
% RSKtools includes a convenient plotting option to overlay the
% pressure data with information about the profile events. For details
% please read the RSKplotdata page in the
% <https://docs.rbr-global.com/rsktools/plotting/rskplotdata-m
% RSKtools on-line user manual>.
%
% Note: If profiles have not been detected by the logger or Ruskin, or
% if the profile time stamps do not correctly parse the data into
% profiles, the function |RSKfindprofiles| can be used. The
% |pressureThreshold| argument, which determines the pressure reversal
% required to trigger a new profile, and the |conductivityThreshold|
% argument, which determines if the logger is out of the water, can be
% adjusted to improve profile detection when the profiles were very
% shallow, or if the water was very fresh.


%% Deriving new channels from measured channels
% In this particular example, Practical Salinity can be derived from
% conductivity, temperature, and pressure because the file comes from
% a CTD-type instrument.  |RSKderivesalinity| is a wrapper for the
% TEOS-10 GSW function |gsw_SP_from_C|, and it adds a new channel
% called |Salinity| as a column in |rsk.data.values|.  The TEOS-10 GSW
% Matlab toolbox is freely available from
% <http://teos-10.org/software.htm>.  Salinity is a function of sea
% pressure, and sea pressure must be derived from the measured total
% pressure before computing salinity.  In the following example, the
% default value of atmospheric pressure at sea level, 10.1325 dbar, is
% used.
rsk = RSKderiveseapressure(rsk);
rsk = RSKderivesalinity(rsk);


%%
% Note: Salinity, sea pressure, and other channels added by RSKtools
% should be derived after using |RSKreadprofiles| because in some
% circumstances |RSKreadprofiles| will read raw data from the Ruskin
% RSK data _file_, instead of referring to the data in the Matlab RSK
% _structure_.

%% Plotting
% RSKtools contains a number of convenient plotting utilities.  To
% plot profiles, use |RSKplotprofiles|.  For example, to plot the
% upcasts of temperature, salinity, and chlorophyll, from this
% example, run:
handles = RSKplotprofiles(rsk, 'channel', {'temperature','salinity','chlorophyll'}, 'direction', 'up');


%% Customising plots
% The plotting functions returns graphics handles enabling access to
% the line objects. The output is a matrix containing a column for
% each channel subplot and a row for each profile.
disp(handles)

%% 
% To increase the line width of the first profile in all subplots,
% run:
set(handles(1,:),{'linewidth'},{3});


%% Accessing individual channels and profiles
% The channel data is stored in |rsk.data|.  If the data was parsed
% into profiles, |data| is a 1xN structure array, where each element
% is an upcast or downcast from a single profile containing an array
% of time stamps and a matrix of channel data.  |RSKtools| has
% functions to access the data from particular channels and profiles.
% For example, to access the time stamps, sea pressure, temperature,
% and dissolved O2 from the upcast of the 1st profile, run:

profind = getdataindex(rsk,'direction','up','profile',1);
tempcol = getchannelindex(rsk,'temperature');
o2col   = getchannelindex(rsk,'dissolved o2');
prescol = getchannelindex(rsk,'sea pressure');

time        = rsk.data(profind).tstamp;
seapressure = rsk.data(profind).values(:,prescol);
temperature = rsk.data(profind).values(:,tempcol);
o2          = rsk.data(profind).values(:,o2col);


%% Other Resources
% We recommend reading:
%
% * The <https://docs.rbr-global.com/rsktools RSKtools on-line user
% manual> for detailed RSKtools function documentation.
%
% * The
% <http://rbr-global.com/wp-content/uploads/2018/05/PostProcessing.pdf
% RSKtools post-processing guide> for an introduction on how to
% process RBR profiles with RSKtools.  The post-processing suite
% contains, among other things, functions to low-pass filter, align,
% de-spike, trim, and bin average the data.  It also contains
% functions to export the data to ODV and CSV files.


%% About this document
% This document was created using
% <http://www.mathworks.com/help/matlab/matlab_prog/marking-up-matlab-comments-for-publishing.html
% Matlab(TM) Markup Publishing>. To publish it as an HTML page, run the
% command:
%%
% 
%   publish('Standard.m');

%%
% See |help publish| for more document export options.