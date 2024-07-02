function [f, params] = get3DSpatiotemporalpRFs(params)
% Description: Function that creates spatiotemporal pRF models
% to use as linear filters.
%
% INPUT:
% params  : (struct) Params struct should have the following fields:
%               tktktk
%
% OUTPUT:
% prfs    : (double) matrix with [x-pixels by y-pixels (in deg)] by nr of
%               pRFs
% Written by ERK 2021 @ VPNL Stanford U

%% Get spatial pRF filter
if  ~isfield(params.analysis.spatial, 'values') || isempty(params.analysis.spatial.values)
    [prfs, params] = getPRFs(params);
else
    prfs = params.analysis.spatial.values;
end

%% Get spatial or temporal pRF filter
switch params.analysis.temporalModel
    case {'3ch-stLN','CST'}
        x = params.analysis.temporal.param;
        if ~isfield(x,'tau_t')
           x.tau_t = x.tau_s;              
        end
        f.temporal = NaN(5000,3,size(prfs,2));
        for ii = 1:size(prfs,2)
            x_n = struct('exponent',x.exponent(ii), ...
                        'tau_s',x.tau_s(ii), ...
                        'tau_t',x.tau_t(ii), ...
                        'n1',x.n1, ...
                        'n2',x.n2, ...
                        'kappa', x.kappa, ...
                        'fs', x.fs); 
            
            f_n = createTemporalIRFs_sustained_transient(x_n);
            f.temporal(1:size(f_n.temporal,1),:,ii) = f_n.temporal;
            if ii == 1; f.scaleFactorNormSumTransChan = f_n.scaleFactorNormSumTransChan; end
        end
        f.names = {'sustained','transient_odd','transient_even'};
        % Get nr of filters
%         nfilters = length(f.names);
        
        %%%% commented out for now. To reduce computation time. %%%%%%%%

        % reshape pRFs from 1D to 2D
%         prf2D = reshape(prfs,sqrt(size(prfs,1)),sqrt(size(prfs,1)), []);
        
        
        % Convolve spatial and temporal filter to get spatiotemporal filter
        %         f.spatiotemporal = zeros(size(prf2D,1),size(prf2D,2),nfilters);
        
        % commented out for now. To reduce computation time.
        %         for ii = 1:size(prf2D,3)
        %
        %             % Get single spatial pRF
        %             currSpatialPRF = prf2D(:,:,ii);
        %
        %             % Convolve spatial pRF with each timepoint of temporal IRF
        %             for ff = 1:nfilters
        %                 currTemporalFilter = f.temporal(:,ff);
        %                 for tt = 1:length(currTemporalFilter)
        %                     tmp = convCut2(currSpatialPRF,currTemporalFilter(tt),size(currSpatialPRF,1));
        %                     f.spatiotemporal(:,:,tt,ff) = tmp;
        %                 end
        %             end
        %         end
        f.spatial.prfs = prfs;
    case '2ch-stLN'
        x = params.analysis.temporal.param;
        if ~isfield(x,'tau_t')
           x.tau_t = x.tau_s;              
        end
        % Create temporal IRFs for sustained and transient channel
        irfSustained = tch_irfs('S', x.tau_s, x.n1, x.n2, x.kappa, x.fs);
        irfTransient = tch_irfs('T', x.tau_t, x.n1, x.n2, x.kappa, x.fs);
        
        f.temporal = zeros(max([length(irfSustained),length(irfTransient)]),3);
        
        % Normalize such that area under the curve sums to 1
        f.temporal(1:length(irfSustained),1) = normSum(irfSustained);
        
        % For transient nrf, we do this separately for positive and negative parts:
        % First find indices
        pos_idx = irfTransient>=0;
        neg_idx = irfTransient<0;
        
        scf = 1;% 0.5; % sum of area under each pos/neg curve
        % Get positive part and normalize sum
        irfT_pos = irfTransient(pos_idx);
        irfT_pos = scf*normSum(irfT_pos);
    
        % Combine positive and negative parts
        nrfT2 = NaN(size(irfTransient));
        nrfT2(pos_idx) = irfT_pos;
        nrfT2(neg_idx) = irfT_neg;
        
        f.temporal(1:length(nrfT2),2) = nrfT2;
        f.names = {'sustained','transient_odd','transient_even'};
        f.scaleFactorNormSumTransChan = scf;
        clear nrfT2 irfT_pos irfT_neg
  
        f.spatial.prfs = prfs;

        
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
