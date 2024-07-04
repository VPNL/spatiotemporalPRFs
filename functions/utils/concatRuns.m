function output = concatRuns(input)
% Function to permute and concatenate runs of fMRI time series
%
% INPUTS
%   input       : (matrix or array) observed time series (time by voxels by unique stimuli by runs) 
%   prediction  : (vector or matrix) predicted time series (time by runs by voxels) <-- double check          
%
% OUTPUTS
%   output         : (double) coefficient of determination (R^2)
%
% Written by ISK 2021 @ VPNL Stanford U

%% removes the last dimension and puts it back to 
if ndims(input) == 4
    ordered_input = permute(input, [1 4 2 3]);
    output = reshape(ordered_input,[], size(input,2),size(input,3));
elseif ndims(input) == 3
    ordered_input = permute(input, [1 3 2]);
    output = reshape(ordered_input,[], size(input,2));
elseif  ndims(input) == 2 % only one run
    output = input;
end

end