function outputFiles = selectFile(inputfiles,filter,InputFileDelimit)
% Function to select pRF model fit file (?)
% 
%   outputFiles = selectFile(inputfiles,filter,InputFileDelimit)
% 
% INPUTS
%   inputfiles      : (str) path to input files 
%   filter          : (str) name to search for in files
%   InputFileDelimit: (str) where to split file names (e.g., '/')
%
% OUTPUTS
%   outputFiles     : (double) selected file names
%
% Written by ISK 2021 @ VPNL Stanford U
%

filter = convertCharsToStrings(filter);

idx = [];
for ii= 1:length(inputfiles)
    s = strsplit(inputfiles{ii}, InputFileDelimit);

    if length(filter) == sum(contains(s,filter))
        idx(ii) = 1;
    else
        idx(ii) = 0;
    end
end

 outputFiles =  cell(size(find(idx')));
 [outputFiles{:}]=inputfiles{find(idx)};


end