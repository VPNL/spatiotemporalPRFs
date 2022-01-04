function result = linearModel(param, prfResponse, t)
% Function to compute linear model response to given pRF response
%
%   result = linearModel(param, prfResponse, t)
%
% INPUTS:
% params      : (struct) should contain the following fields:
%               * shift: time between stimulus onset and when the signal 
%                   reaches the cortex, in units of second
%               * scale: response gain
% prfResponse : (double) pRF response to given stimulus, can also be the 
%                   stimulus contrast time course, if you assume a full field 
%                   stimulus that covers the entire pRF. Dimension are number 
%                   of time points (ms) by nr of pRFs
% t           : (double) corresponding time axis of prfResponse (1xtime
%                   points in ms)
%
% OUTPUT:
% result    : (cell) with shifted and scaled linear channel response.

%% Derive and set up model params
x       = []; % a struct of model parameteres
dt      = t(2) - t(1);

fields = {'shift', 'scale'};
x      = toSetField(x, fields, param);

%% COMPUTE THE NORMALIZATION RESPONSE
neuralrsp = zeros(size(prfResponse, 1),size(prfResponse, 2));

for ii = 1 : size(prfResponse, 2)
    
    % Add shift to rfResponse if value is larger than 0
    if x.shift > 0
        sft   = round(x.shift * (1/dt));
        tmp   = padarray(prfResponse(:, ii), [0, sft], 0, 'pre');
        prfResponse(:, ii) = tmp(1 : size(prfResponse, 1));
    end
    
    % Scale the predicted response
    neuralrsp(:, ii) = x.scale.*prfResponse(:, ii);
    
end

% Add neural response to result variable
result{1} = neuralrsp;


end