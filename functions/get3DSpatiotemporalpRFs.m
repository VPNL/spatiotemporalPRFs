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
[prfs, params] = getPRFs(params);

%% Get spatial or temporal pRF filter
switch params.analysis.temporalModel
    case '3ch-linst'
        x = params.analysis.temporal.param;
        % Create temporal IRFs for sustained and transient channel
        irfSustained = tch_irfs('S', x.tau_s, x.n1, x.n2, x.kappa, x.fs);
        irfTransient = tch_irfs('T', x.tau_s, x.n1, x.n2, x.kappa, x.fs);
        
        % Normalize such that area under the curve sums to 1 
        f.temporal{1} = normSum(irfSustained);
 
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

        f.temporal{2} = nrfT2;
        f.temporal{3} = -f.temporal{2};
        f.names = {'sustained','transient_odd','transient_even'};
        f.scaleFactorNormSumTransChan = scf;
        clear nrfT2 irfT_pos irfT_neg
        
        % Get nr of filters      
        nfilters = length(f.names);

        % Convolve spatial and temporal filter to get spatiotemporal filter
        f.spatiotemporal = {};
        
        % reshape pRFs from 1D to 2D
        prf2D = reshape(prfs,sqrt(size(prfs,1)),sqrt(size(prfs,1)), []);
        for ii = 1:size(prf2D,3)
            
            % Get single spatial pRF
            currSpatialPRF = prf2D(:,:,ii);
            
            % Convolve spatial pRF with each timepoint of temporal IRF
            for ff = 1:nfilters
                currTemporalFilter = f.temporal{ff};
                for tt = 1:length(currTemporalFilter)
                    tmp = conv2(currSpatialPRF,currTemporalFilter(tt),'same');
                    f.spatiotemporal{ff}(:,tt) = tmp(:);
                end
            end
        end
        f.spatial.prfs = prfs;
        f.main = f.spatiotemporal;
        
    case '1ch-dcts'
        % Just keep spatial filter for now
        f.spatial.prfs = prfs;
        f.main = f.spatial.prfs;
        f.temporal{1} = 1;
        f.names = {'linear'};

    case '1ch-glm'
        % Just keep spatial filter for now
        f.spatial.prfs = prfs;
        f.main = f.spatial.prfs;
        f.temporal{1} = 1;
        f.names = {'linear'};

end





end
