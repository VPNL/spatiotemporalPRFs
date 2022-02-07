function [nonLinearResponse, params] = applyNonlinearity(prfResponse,params)
% Wrapper function to apply different types of nonlinearities depending on
% the model type.
% 
% INPUT
% prfResponse       : (double) matrix or array with dimensions time by
%                       voxels [by channels]
% params            : (struct) parameter struct should have at least the
%                       follow fields for this wrapper function:
%                       - params.analysis.temporalModel
%                       - params.analysis.spatialModel
%                       - if CSSfit, params.analysis.spatial.(lh/rh).exponent
%                       - if 3ch-stLN, params.analysis.temporal.param.exp
%
% OUTPUT
% nonLinearResponse : (double) matrix or array with dimensions time by 
%                       voxels [by channels] 
% params            : (struct) parameter struct with updated fields for
%                       type of nonlinearity applied: params.analysis.nonlinearity


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      SKIP NON LINEARITY     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(params.analysis.temporalModel,'1ch-glm') || strcmp(params.analysis.temporalModel,'Adelson-Bergen')
    nonLinearResponse = prfResponse;
    params.analysis.nonlinearity = 'none';
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    SPATIAL NON LINEARITY    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% CSS - compressive spatial summation (Kay et al. 2013 J Neurophys)
if strcmp(params.analysis.spatialModel,'cssFit')
    params.analysis.nonlinearity = 'css';

    % Exponentiate predicted pRF stimulus time series
    if isfield(params.analysis.spatial,'lh') && isfield(params.analysis.spatial,'rh') 
        exponent = cat(2,params.analysis.spatial.lh.exponent,params.analysis.spatial.rh.exponent);
    elseif isfield(params.analysis.spatial,'lh') && ~isfield(params.analysis.spatial,'rh') 
         exponent = params.analysis.spatial.lh.exponent;
    elseif ~isfield(params.analysis.spatial,'lh') && isfield(params.analysis.spatial,'rh') 
         exponent = params.analysis.spatial.rh.exponent;
    else
        exponent = params.analysis.spatial.exponent;
    end
    nonLinearResponse = bsxfun(@power, prfResponse, exponent);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   TEMPORAL NON LINEARITY     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% DCTS - divisive compressive temporal summation (Zhou et al. 2018 PLoS CB)
if strcmp(params.analysis.temporalModel,'1ch-dcts')
    params.analysis.nonlinearity = 'dcts';
 
    % Apply divisive normalization to pRF stimulus time series
    nonLinearResponse = DNmodel(params.analysis.temporal.param, prfResponse);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  SPATIOTEMPORAL NON LINEARITY  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(params.analysis.temporalModel,'3ch-stLN')
    verbose = false;
    if params.useGPU
        nonLinearResponse = zeros(size(prfResponse),'gpuArray');
    else 
        nonLinearResponse = zeros(size(prfResponse));
    end
    for n = 1:size(prfResponse,3)
        nonLinearResponse(:,:,n,:) = tch_staticExpComp(prfResponse(:,:,n,:), params.analysis.temporal.param.exponent,verbose);
    end
    params.analysis.nonlinearity = 'staticExp';
end


return






