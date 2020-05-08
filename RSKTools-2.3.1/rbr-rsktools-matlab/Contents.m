% RSKTOOLS
% Version 2.3.1 2018-06-20
%
% 1.  This toolbox depends on the presence of a functional mksqlite
% library.  We have included a couple of versions here for Windows (32 bit/
% 64 bit), Linux (64 bit) and Mac (64 bit).  If you might need to compile
% another version, the source code can be downloaded from 
% https://sourceforge.net/projects/mksqlite/files/. RSKtools currently uses
% mksqlite Version 2.5.
%
% 2.  Opening an RSK file.  Use RSKopen with a filename as the argument:
%
% RSK = RSKopen('sample.rsk');  
%
% This generates an RSK structure with all the metadata from the database, 
% and a downsampled version of the data.  The downsampled version is useful
% for generating figures of very large data sets.
%
% 3.  Use RSKreaddata to read data from the RSK file:
%
% RSK = RSKreaddata(RSK, 't1', <starttime>, 't2', <endtime>); 
%
% This reads a portion of the 'data' table into the RSK structure
% (replacing any previous data that was read this way).  The <starttime>
% and <endtime> values are the range of data to be read.  Depending on the
% amount of data in your dataset, and the amount of memory in your
% computer, you can read bigger or smaller chunks before Matlab will
% run out of memory.  The times are specified using the Matlab 'datenum' 
% format. You will find the start and end times of the deployment useful
% reference points - these are contained in the RSK structure as the
% RSK.epochs.starttime and RSK.epochs.endtime fields.
%
% 4.  Plot the data!
%
% RSKplotdata(RSK)
%
% This generates a time series plot using the full 'data' that you read in,
% rather than just the downsampled version.  It labels each sublot with the 
% appropriate channel name, so you can get an idea of how to do
% better processing.
%
%
% User files
%   RSKopen              - Open an RBR RSK file and read metadata and downsampled data
%   RSKreaddata          - read full dataset from database
%   RSKplotdata          - plot data as a time series
%   RSKplot2D            - display bin averaged data in a time-depth heat map
%   RSKreadwavetxt       - reads wave data from a Ruskin .txt export
%   RSKgetprofiles       - read profile start and end times from RSK
%   RSKfindprofiles      - detect profile start and end times using pressure and conductivity
%   RSKreadprofiles      - reads and organized data into a series of profiles
%   RSKplotprofiles      - plot depth profiles for each channel
%   RSKreaddownsample    - read downsample data from database
%   RSKplotdownsample    - plot downsample data
%   RSKselectdowncast    - keep only the down casts in the RSK structure
%   RSKselectupcast      - keep only the up casts in the RSK structure
%   RSKreadburstdata     - read burst data from database
%   RSKplotburstdata     - plot burst data
%   RSKsamplingperiod    - read logger sampling period information from RSK file
%   RSKreadevents        - read events from database
%   RSKreadgeodata       - read geodata
%   RSKreadcalibrations  - read the calibrations table of an RSK file
%   RSKderivesalinity    - derive salinity from conductivity, temperature, and sea pressure
%   RSKderiveseapressure - derive sea pressure from pressure
%   RSKderivedepth       - derive depth from pressure
%   RSKderivevelocity    - derive profiling rate from depth and time
%   RSKderiveC25         - derive specific conductivity at 25 degree Celsius
%   RSKderiveBPR         - derive temperature and pressure from bottom pressure recorder (BPR) period data
%   RSKsmooth            - apply low-pass filter to data
%   RSKdespike           - statistically identify and treat spikes in data
%   RSKcorrecthold       - identify, and then remove or replace zero-order hold points in data
%   RSKcalculateCTlag    - estimate optimal conductivity shift relative to temperature
%   RSKalignchannel      - align a channel in time using a specified lag
%   RSKremoveloops       - remove values exceeding a threshold profiling rate and pressure reversals
%   RSKbinaverage        - bin average the profile data by reference channel intervals
%   RSKtrim              - remove or NaN channel data fitting specified criteria
%   RSKaddchannel        - add a new channel to existing RSK structure
%   RSKaddmetadata       - add station meta data to RSK data structure
%   RSK2MAT              - convert RSK structure to legacy RUSKIN .mat format
%   RSK2CSV              - write channel data and metadata to one or more CSV files
%   RSK2ODV              - write channel data and metadata to one or more ODV files
%
%
% Additional useful files
%   getchannelindex    - returns column index to the data table given a channel name
%   getdataindex       - returns index into the RSK data array given profile numbers and cast directions
%
%
% For more information, check out documents in QuickStart folder and our
% online user manual: https://docs.rbr-global.com/rsktools
%
%
