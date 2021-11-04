function [reluResponse, params] = applyReLU(prfResponse,params)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  RECTIFIED LINEAR UNIT (ReLU)  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% All spatiotemporal filters are subject to a rectified linear unit (reLU).
% This should only affect models with negative predicted neural responses, 
% such as the 3ch-linst. In that case, when we apply a relu we technically
% combine the odd and even transient functions.

% define relu params
params.analysis.relu.slope  = 1; % no scaling
params.analysis.relu.thresh = 0; % keep everything above zero, set rest to zero.
params.analysis.reluFlag    = 1; % note that we applied a relu

% apply it to each channel prf response
for n = 1:length(prfResponse)
    reluResponse{n} = relu(prfResponse{n}, params.analysis.relu.slope, params.analysis.relu.thresh);
end