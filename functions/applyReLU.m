function [reluResponse, params] = applyReLU(prfResponse,params)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  RECTIFIED LINEAR UNIT (ReLU)  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% All spatiotemporal filters are subject to a rectified linear unit (reLU).
% This should only affect models with negative predicted neural responses, 
% such as the 3ch-linst. In that case, when we apply a relu we technically
% combine the odd and even transient functions.
%
% INPUTS
% prfResponse       : arry with dimensions time x pRFs x filters
% params            : struct with parameters, needs the following fields:
%                       params.analysis.reluFlag = True, and will look for
%                       defined slope: params.analysis.relu.slope
%                       and threshold: params.analysis.relu.thresh
% OUTPUTS
% reluResponse      : (double) matrix or array with response after applying
%                       the ReLU, with dimensions time x pRFs x filters
% params            : struct with parameters, and if needed, updated fields
%                       for params.analysis.relu.slope and threshold
%
% 
% define relu params
if ~isfield(params.analysis, 'relu') || ...
        ~isfield(params.analysis.relu,'slope') || ...
        isempty(params.analysis.relu.slope)
    params.analysis.relu.slope  = 1; % no scaling
end
if ~isfield(params.analysis, 'relu') || ...
        ~isfield(params.analysis.relu,'thresh') || ...
         isempty(params.analysis.relu.slope)
    params.analysis.relu.thresh = 0; % keep everything above zero, set rest to zero.
end

if params.analysis.reluFlag
    % apply it to each channel prf response
    reluResponse = NaN(size(prfResponse));
    for n = 1:size(prfResponse,3)
        reluResponse(:,:,n,:) = relu(prfResponse(:,:,n,:), params.analysis.relu.slope, params.analysis.relu.thresh);
    end
else
    fprintf(sprintf('[%s]: No ReLU applied!',mfilename))
    reluResponse = prfResponse;
end