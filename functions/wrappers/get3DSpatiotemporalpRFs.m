function [f, params] = get3DSpatiotemporalpRFs(params)
% Description: Function that creates spatiotemporal pRF models
% to use as linear filters.
%
% INPUT:
% params  : (struct) Params struct should have the following fields:
%               params.saveDataFlag            
%               params.recomputePredictionsFlag
%               params.useGPU
%               params.stim.sparsifyFlag
%               params.stim.framePeriod (TR in seconds)
%               params.analysis.reluFlag
%               params.analysis.normNeuralChan
%               params.analysis.normAcrossRuns
%               params.analysis.predFile
%               params.analysis.spatialModel
%               params.analysis.temporalModel
%               params.analysis.hrf.type
%               params.analysis.zeroPadPredNeuralFlag
%               params.analysis.spatial.x0
%               params.analysis.spatial.y0
%               params.analysis.spatial.sigmaMajor
%               See "getSpatialParams.m", "getTemporalParams.m",
%               "getExampleParams.m" for descriptions and details
%
% OUTPUT:
% f       : (struct) spatial and/or temporal pRF filters:
%            * spatial: (double) 2D matrix: x,y-grid (deg) by nr of pRFs 
% params  : (struct) same as input params, but with updated/added parameters
%
% Written by ERK 2021 @ VPNL Stanford U
%
% History:
% 2024.12.10: Add flexibility for the nr of pRFs vs nr of provided
% parameters.

%% Get spatial pRF parameters
if  ~isfield(params.analysis.spatial, 'values') || isempty(params.analysis.spatial.values)
    [prfs, params] = getPRFs(params);
else
    prfs = params.analysis.spatial.values;
end

%% Check if nr of parameters match nr of expected pRFs to generate. 
% If we only get one parameter value for either x, y, or sigma, we
% replicate the parameter value for all the pRFs. 
if size(prfs,2) ~= size(params.analysis.spatial.x0,2)
    params.analysis.spatial.x0 = repmat(params.analysis.spatial.x0,[1,size(prfs,2)]);
end
if size(prfs,2) ~= size(params.analysis.spatial.y0,2)
    params.analysis.spatial.y0 = repmat(params.analysis.spatial.y0,[1,size(prfs,2)]);
end
if size(prfs,2) ~= size(params.analysis.spatial.sigmaMajor,2)
    params.analysis.spatial.sigmaMajor = repmat(params.analysis.spatial.sigmaMajor,[1,size(prfs,2)]);
end
if isfield(params.analysis.spatial, 'sigmaMinor') && size(prfs,2) ~= size(params.analysis.spatial.sigmaMinor,2)
    params.analysis.spatial.sigmaMinor = repmat(params.analysis.spatial.sigmaMinor,[1,size(prfs,2)]);
end
if isfield(params.analysis.spatial, 'theta') && size(prfs,2) ~= size(params.analysis.spatial.theta,2)
    params.analysis.spatial.theta = repmat(params.analysis.spatial.theta,[1,size(prfs,2)]);
end

%% Get spatial or temporal pRF filter
switch params.analysis.temporalModel
    case {'3ch-stLN','CST'}
        
        % If there is no transient time constant, we use the same time constant as sustained.
        if ~isfield(params.analysis.temporal.param,'tau_t')
           params.analysis.temporal.param.tau_t = params.analysis.temporal.param.tau_s;              
        end
        
        % check correspondance between nr of pRFs and defined params,
        % don't loop if we use the same set of IRF params for all pRFs
        if length(params.analysis.temporal.param.tau_s) == 1 && ...
                length(params.analysis.temporal.param.tau_s) < size(prfs,2)
            
            x_n = struct('exponent',params.analysis.temporal.param.exponent, ...
                    'tau_s',params.analysis.temporal.param.tau_s, ...
                    'tau_t',params.analysis.temporal.param.tau_t, ...
                    'n1',params.analysis.temporal.param.n1, ...
                    'n2',params.analysis.temporal.param.n2, ...
                    'kappa', params.analysis.temporal.param.kappa, ...
                    'fs', params.analysis.temporal.param.fs);
            
            % Create temporal impulse response functions
            f_n = createTemporalIRFs_sustained_transient(x_n);
           
            % Add scaleFactorNormSumTransChan param to general struct
            f.scaleFactorNormSumTransChan = f_n.scaleFactorNormSumTransChan;
            
            % Inset the IRF into the "temporal" field 
            f.temporal = f_n.temporal; % time x channels x num prfs.
        
        else % loop over voxels
            
            for ii = 1:size(prfs,2)
                % Grab single pRF params to make temporal IRF
                x_n = struct('exponent',params.analysis.temporal.param.exponent(ii), ...
                    'tau_s',params.analysis.temporal.param.tau_s(ii), ...
                    'tau_t',params.analysis.temporal.param.tau_t(ii), ...
                    'n1',params.analysis.temporal.param.n1(ii), ...
                    'n2',params.analysis.temporal.param.n2(ii), ...
                    'kappa', params.analysis.temporal.param.kappa(ii), ...
                    'fs', params.analysis.temporal.param.fs);
                
                % Create temporal impulse response functions
                f_n = createTemporalIRFs_sustained_transient(x_n);
                
                % Add scaleFactorNormSumTransChan param to general struct
                if ii == 1
                    f.scaleFactorNormSumTransChan = f_n.scaleFactorNormSumTransChan;
                    
                    % Preallocate space.
                    f.temporal = zeros(size(f_n.temporal,1),3,size(prfs,2)); % time x channels x num prfs.
                end
                
                % Inset the IRF into the "temporal" field
                f.temporal(1:size(f_n.temporal,1),:,ii) = f_n.temporal;
            end
        end
        f.names = {'sustained','transient_on','transient_off'};
        f.spatial.prfs = prfs;
        
        %%%% For visual debugging %%%%%%%% commented out for now to reduce computation time.
        % % reshape pRFs from 1D to 2D 
        % prf2D = reshape(prfs,sqrt(size(prfs,1)),sqrt(size(prfs,1)), []);
        
        % % Convolve spatial and temporal filter to get spatiotemporal filter
        % f.spatiotemporal = zeros(size(prf2D,1),size(prf2D,2),nfilters);
        % for ii = 1:size(prf2D,3)
        %
        %   % Get single spatial pRF
        %   currSpatialPRF = prf2D(:,:,ii);
        %
        %   % Convolve spatial pRF with each timepoint of temporal IRF
        %   for ff = 1:nfilters
        %       currTemporalFilter = f.temporal(:,ff);
        %       for tt = 1:length(currTemporalFilter)
        %           tmp = convCut2(currSpatialPRF,currTemporalFilter(tt),size(currSpatialPRF,1));
        %           f.spatiotemporal(:,:,tt,ff) = tmp;
        %       end
        %    end
        % end
        
    case {'1ch-dcts','DN-ST'}
        % Just keep spatial filter for now
        f.spatial.prfs = prfs;
        f.temporal(1) = 1;
        f.names = {'linear'};
        
    case {'1ch-glm','spatial'}
        % Just keep spatial filter for now
        f.spatial.prfs = prfs;
        f.temporal(1) = 1;
        f.names = {'linear'};
        
end

% deal with GPU
if params.useGPU
    f.spatial.prfs  = gpuArray(full(f.spatial.prfs));
    f.temporal      = gpuArray(f.temporal);
end




end
