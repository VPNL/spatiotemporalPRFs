function [nonLinearResponse, params] = applyNonlinearity(prfResponse,params)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      SKIP NON LINEARITY     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(params.analysis.temporalModel,'1ch-glm')
    nonLinearResponse{1} = prfResponse;
    params.analysis.nonlinearity = [];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    SPATIAL NON LINEARITY    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% CSS - compressive spatial summation (Kay et al. 2013 J Neurophys)
if strcmp(params.analysis.spatialModel,'cssFit')
    params.analysis.nonlinearity = 'css';

    % Exponentiate predicted pRF stimulus time series
    nonLinearResponse{1} = bsxfun(@power, cell2mat(prfResponse), params.analysis.spatial.exponent);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   TEMPORAL NON LINEARITY     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% DCTS - divisive compressive temporal summation (Zhou et al. 2018 PLoS CB)
if strcmp(params.analysis.temporalModel,'1ch-dcts')
    params.analysis.nonlinearity = 'dcts';
 
    % Apply divisive normalization to pRF stimulus time series
    nonLinearResponse{1} = DNmodel(params.analysis.temporal.param, cell2mat(prfResponse));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  SPATIOTEMPORAL NON LINEARITY  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(params.analysis.temporalModel,'3ch-linst')
    verbose = false
    for n = 1:length(prfResponse)
        nonLinearResponse{n} = tch_staticExp(prfResponse{n}, params.analysis.spatiotemporal.exp, verbose);
    end
    params.analysis.nonlinearity = 'staticExp';
end


return






