function [nonLinearResponse, params] = applyNonlinearity(params,prfResponse)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  SPATIAL NON LINEAR MODELS  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% CSS - compressive spatial summation (Kay et al. 2013 J Neurophys)
if strcmp(params.analysis.spatialModel,'cssFit')
    % Exponentiate predicted pRF stimulus time series
    nonLinearResponse = bsxfun(@power, prfResponse, params.spatial.exponent);
    params.analysis.nonlinearity = 'css';
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  TEMPORAL NON LINEAR MODELS  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% DCTS - divisive compressive temporal summation (Zhou et al. 2018 PLoS CB)
if strcmp(params.analysis.temporalModel,'1ch-dcts')
    % Derive temporal sample rate and time axis
    dt = 1/params.analysis.temporal.fs;
    t  = dt : dt : size(prfResponse,1)/params.analysis.temporal.fs;
    
    % Apply divisive normalization to pRF stimulus time series
    nonLinearResponse = DNmodel(params.temporal.params, prfResponse, t);
    params.analysis.nonlinearity = 'cts';
end

% Sustained and transient 3D spatiotemporal filter are subject to a relu 
% to combine the odd and even transient function
if strcmp(params.analysis.temporalModel,'3ch-linst')
    % define relu params
    params.analysis.relu.slope  = 1; % no scaling
    params.analysis.relu.thresh = 0; % keep everything above zero, set rest to zero.
    % apply it to each channel prf response
    for n = 1:length(prfResponse)
        nonLinearResponse{n} = relu(prfResponse{n}, params.analysis.relu.slope, params.analysis.relu.thresh);
    end
    params.analysis.nonlinearity = 'relu';
end





