function [raw, diagndx] = checkDiagPlot(RSK, diagnostic, direction, castidx)

raw = RSK; 
diagndx = getdataindex(RSK, diagnostic, direction);

if any(~ismember(diagndx, castidx))
    error('Requested profile for diagnostic plot is not processed.')
end

end