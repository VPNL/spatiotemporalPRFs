function [nonLinearResponse, params] = applyNonlinearity(params,prfResponse)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  SPATIAL NON LINEAR MODELS  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% CSS - compressive spatial summation (Kay et al. 2013 J Neurophys)
if strcmp(params.analysis.spatialModel,'cssFit')
    params.analysis.nonlinearity = 'css';

    % Exponentiate predicted pRF stimulus time series
    nonLinearResponse{1} = bsxfun(@power, cell2mat(prfResponse), params.analysis.spatial.exponent);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  TEMPORAL NON LINEAR MODELS  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% DCTS - divisive compressive temporal summation (Zhou et al. 2018 PLoS CB)
if strcmp(params.analysis.temporalModel,'1ch-dcts')
    params.analysis.nonlinearity = 'dcts';
 
    % Apply divisive normalization to pRF stimulus time series
    nonLinearResponse{1} = DNmodel(params.analysis.temporal.param, cell2mat(prfResponse));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  RECTIFIED LINEAR UNIT (ReLU)  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% All spatiotemporal filters are subject to a rectified linear unit (reLU).
% This should only affect models with negative predicted neural responses, 
% such as the 3ch-linst. In that case, when we apply a relu we technically
% combine the odd and even transient functions.
if strcmp(params.analysis.temporalModel,'3ch-linst') || strcmp(params.analysis.temporalModel,'1ch-glm')
    nonLinearResponse = prfResponse;
    params.analysis.nonlinearity = [];
end

% define relu params
params.analysis.relu.slope  = 1; % no scaling
params.analysis.relu.thresh = 0; % keep everything above zero, set rest to zero.
params.analysis.reluFlag = 1;

% apply it to each channel prf response
for n = 1:length(nonLinearResponse)
    nonLinearResponse{n} = relu(nonLinearResponse{n}, params.analysis.relu.slope, params.analysis.relu.thresh);
end

return






