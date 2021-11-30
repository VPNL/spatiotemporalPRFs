function [nonLinearResponse, params] = applyNonlinearity(prfResponse,params)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      SKIP NON LINEARITY     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(params.analysis.temporalModel,'1ch-glm')
    nonLinearResponse = prfResponse;
    params.analysis.nonlinearity = [];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    SPATIAL NON LINEARITY    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% CSS - compressive spatial summation (Kay et al. 2013 J Neurophys)
if strcmp(params.analysis.spatialModel,'cssFit')
    params.analysis.nonlinearity = 'css';

    % Exponentiate predicted pRF stimulus time series
    if isfield(params.analysis.spatial,'lh') || isfield(params.analysis.spatial,'rh') 
        exponent = cat(2,params.analysis.spatial.lh.exponent,params.analysis.spatial.rh.exponent);
    else
        exponent = params.analysis.spatial.exponent;
    end
    nonLinearResponse{1} = bsxfun(@power, cell2mat(prfResponse), exponent);
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
if strcmp(params.analysis.temporalModel,'3ch-stLN')
    verbose = false;
    for n = 1:length(prfResponse)
        nonLinearResponse{n} = tch_staticExpComp(prfResponse{n}, params.analysis.temporal.param.exp, verbose);
    end
    params.analysis.nonlinearity = 'staticExp';
end


return






