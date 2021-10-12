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
        f.temporal{1} = tch_irfs('S', x.tau_s, x.n1, x.n2, x.kappa, x.fs);
        f.temporal{2} = tch_irfs('T', x.tau_s, x.n1, x.n2, x.kappa, x.fs);
        f.temporal{3} = -f.temporal{2};
        f.names = {'sustained','transient_odd','transient_even'};
        
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
        
    case '1ch-glm'
        % Just keep spatial filter for now
        f.spatial.prfs = prfs;
        f.main = f.spatial.prfs;
end





end
