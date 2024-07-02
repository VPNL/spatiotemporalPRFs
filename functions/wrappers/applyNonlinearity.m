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
if ismember(params.analysis.temporalModel,{'1ch-glm','spatial'})
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
if ismember(params.analysis.temporalModel,{'1ch-dcts','DN-ST'}) 
    params.analysis.nonlinearity = 'dcts';
    if params.useGPU
        nonLinearResponse = zeros(size(prfResponse),'gpuArray');
    else 
        nonLinearResponse = zeros(size(prfResponse));
    end
    if length(params.analysis.temporal.param.tau1) > 1 &&  size(prfResponse,2) > 1
        % We assume fs, shift and scale do not vary across pRFs within a
        % visual area
        p.fs = params.analysis.temporal.param.fs;
        p.shift  = params.analysis.temporal.param.shift;
        p.scale  = params.analysis.temporal.param.scale;
        for n = 1:size(prfResponse,2)
            p.tau1   = params.analysis.temporal.param.tau1(n);
            p.weight = params.analysis.temporal.param.weight(n);
            p.tau2   = params.analysis.temporal.param.tau2(n);
            p.n      = params.analysis.temporal.param.n(n);
            p.sigma  = params.analysis.temporal.param.sigma(n); 
            % Apply divisive normalization to pRF stimulus time series
            nonLinearResponse(:,n) = DNmodel(p, prfResponse(:,n), params.useGPU);
        end
    else
        nonLinearResponse = DNmodel(params.analysis.temporal.param, ...
            prfResponse, params.useGPU);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  SPATIOTEMPORAL NON LINEARITY  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ismember(params.analysis.temporalModel,{'3ch-stLN','CST'})   
    verbose = false;
    if params.useGPU
        nonLinearResponse = zeros(size(prfResponse),'gpuArray');
    else 
        nonLinearResponse = zeros(size(prfResponse));
    end
    for n = 1:size(prfResponse,3)
        nonLinearResponse(:,:,n,:) = staticExpComp(squeeze(prfResponse(:,:,n,:)), params.analysis.temporal.param.exponent,verbose);
    end
    params.analysis.nonlinearity = 'staticExp';
end


return






