function RSK = RSKreadannotations(RSK)

% RSKreadannotations - Read annotations from Ruskin.
%
% Syntax:  [RSK] = RSKreadannotations(RSK)
%
% Reads in GPS and comment start and end time by combining information 
% from region, regionGeoData and regionComment tables and adds it to the 
% RSK structure.
%
% Inputs:
%    RSK - Structure containing logger metadata.
%
% Outputs:
%    RSK - Structure containing populated annotations, if available.
%
% See also: RSKgetprofiles.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2018-02-22

tables = doSelect(RSK, 'SELECT name FROM sqlite_master WHERE type="table"');

if any(strcmpi({tables.name}, 'region')) && any(strcmpi({tables.name}, 'regionGeoData')) && any(strcmpi({tables.name}, 'regionComment'))
    regioninfo = doSelect(RSK, 'PRAGMA table_info(region)');
    if any(strcmpi({regioninfo.name}, 'description')) % description column only exists after 1.13.8 
        RSK.region = doSelect(RSK, 'select regionID, type, tstamp1/1.0 as tstamp1, tstamp2/1.0 as tstamp2, description from region');
    else
        RSK.region = doSelect(RSK, 'select regionID, type, tstamp1/1.0 as tstamp1, tstamp2/1.0 as tstamp2 from region');
    end
    RSK.regionGeoData = doSelect(RSK, 'select * from regionGeoData');
    RSK.regionComment = doSelect(RSK, 'select * from regionComment');
else
    return
end

if ~isempty(RSK.regionGeoData) && isfield(RSK,'geodata');
    RSK = rmfield(RSK, 'geodata'); % delete cell gps if annotation gps exists
end

if any(cellfun(@isempty,{RSK.region.description}))
    RSK.region = rmfield(RSK.region, 'description');
end

ProfileRegionID = find(strcmpi({RSK.region.type},'PROFILE') == 1);
GPSRegionID = find(strcmpi({RSK.region.type},'GPS') == 1);
CommentRegionID = find(strcmpi({RSK.region.type},'COMMENT') == 1);

GPSAssignID = zeros(length(GPSRegionID),1);
CommentAssignID = zeros(length(CommentRegionID),1);

if isempty(RSK.regionGeoData)
    RSK = rmfield(RSK, 'regionGeoData');
else
    for g = 1:length(GPSRegionID)
        for p = 1:length(ProfileRegionID)
            if RSK.region(GPSRegionID(g)).tstamp1 >= RSK.region(ProfileRegionID(p)).tstamp1 && ...
               RSK.region(GPSRegionID(g)).tstamp1 <= RSK.region(ProfileRegionID(p)).tstamp2;
               GPSAssignID(g) = ProfileRegionID(p);
            end
        end
    end
    k = 1;
    for ndx = 1:length(ProfileRegionID)
        if ismember(ProfileRegionID(ndx), GPSAssignID)
            RSK.profiles.GPS.latitude(ndx,1) = RSK.regionGeoData(k).latitude;
            RSK.profiles.GPS.longitude(ndx,1) = RSK.regionGeoData(k).longitude;
            k = k + 1;
        else
            RSK.profiles.GPS.latitude(ndx,1) = nan;
            RSK.profiles.GPS.longitude(ndx,1) = nan;
        end
    end
end

if isempty(RSK.regionComment)
    RSK = rmfield(RSK, 'regionComment');
else
    for g = 1:length(CommentRegionID)
        for p = 1:length(ProfileRegionID)
            if RSK.region(CommentRegionID(g)).tstamp1 >= RSK.region(ProfileRegionID(p)).tstamp1 && ...
               RSK.region(CommentRegionID(g)).tstamp1 <= RSK.region(ProfileRegionID(p)).tstamp2;
               CommentAssignID(g) = ProfileRegionID(p);
            end
        end
    end
    k = 1;
    for ndx = 1:length(ProfileRegionID)
        if ismember(ProfileRegionID(ndx), CommentAssignID)        
            RSK.profiles.comment{ndx,1} = RSK.region(CommentRegionID(k)).description;
            k = k + 1;
        else
            RSK.profiles.comment{ndx,1} = nan;
        end
    end
end


end
