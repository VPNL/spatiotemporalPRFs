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
    case '3ch-stLN'
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
        
        % Get negative part and normalize sum
        irfT_neg = abs(irfTransient(neg_idx));
        irfT_neg = -scf*normSum(irfT_neg);
        
        % Combine positive and negative parts
        nrfT2 = NaN(size(irfTransient));
        nrfT2(pos_idx) = irfT_pos;
        nrfT2(neg_idx) = irfT_neg;
        
        f.temporal(1:length(nrfT2),2) = nrfT2;
        f.temporal(1:length(nrfT2),3) = -nrfT2;
        f.names = {'sustained','transient_odd','transient_even'};
        f.scaleFactorNormSumTransChan = scf;
        clear nrfT2 irfT_pos irfT_neg
        
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
        
    case 'Adelson-Bergen'
        f.spatial.prfs = prfs;
%         for n = 1:10
%             f.temporal(:,n) = 2*temp_imp_resp(n,22,[0:tsz]'/tsz);
%             f.names{n} = n;
%         end
        prf2D = reshape(prfs,sqrt(size(prfs,1)),sqrt(size(prfs,1)), []);
        
        sfilt = upBlur([0 0 0.107517 0.074893 -0.469550 0 ...
            0.469550 -0.074893 -0.107517 0 0]);
        sdfilt = upBlur([0 0 0.201624 -0.424658 -0.252747 0.940351 ...
            -0.252747 -0.424658 0.201624 0 0]/1.8);
        
        tsz = 20*1000;
        tfilt = 2*temp_imp_resp(5,22,[0:tsz]'/tsz);
        tdfilt = temp_imp_resp(2.5,22,[0:tsz]'/tsz)/2.5;
        
        f1= tfilt*prfs';
        f2= tdfilt*prfs';
        subplot(211); imagesc(f1);
        subplot(212); imagesc(f2);

%         even_slow = tfilt * sdfilt;
%         even_fast = tdfilt * sdfilt ;
%         odd_slow = tfilt * sfilt ;
%         odd_fast = tdfilt * sfilt ;

        f.temporal(:,1) = tfilt;
        f.temporal(:,2) = tdfilt;
        
%         leftward_1=odd_fast+even_slow;
%         leftward_2=-odd_slow+even_fast;
%         rightward_1=-odd_fast+even_slow;
%         rightward_2=odd_slow+even_fast;

        f.spatiotemporal()

%         f.names = {'fast','slow'};
        
    case '1ch-dcts'
        % Just keep spatial filter for now
        f.spatial.prfs = prfs;
        f.temporal(1) = 1;
        f.names = {'linear'};
        
    case '1ch-glm'
        % Just keep spatial filter for now
        f.spatial.prfs = prfs;
        f.temporal(1) = 1;
        f.names = {'linear'};
        
end

% deal with GPU
if params.useGPU == 1
    f.spatial.prfs  = gpuArray(full(f.spatial.prfs));
    f.temporal      = gpuArray(f.temporal);
end




end
