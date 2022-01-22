function e = solve_spatiotemporal(x,params, stim, data)

% Generates anonymous objective function that can be passed to fmincon

% nruns = size(stim,3);

params.analysis.spatial.x0 = x(1);
params.analysis.spatial.y0 = x(2);
params.analysis.spatial.sigmaMajor = x(3);
params.analysis.spatial.sigmaMinor = x(3);

switch params.analysis.temporalModel
    case '1ch-glm'
    case '3ch-stLN'
        % 3 temporal params to solve:
        % 1) sustained delay 2) transient delay  3) exponent
%         params.analysis.temporal.param.exponent = x(4);
%         params.analysis.temporal.param.tau_s    = x(5);
%         params.analysis.temporal.param.tau_t    = x(6);

        params.analysis.temporal.param.exponent = x(4);
        params.analysis.temporal.param.tau_s    = x(5);
        params.analysis.temporal.param.tau_t    = x(5);

    case '1ch-dcts'
        % 4 temporal params to solve:
        %  ["tau1", weight, "tau2", "n", "delay/sigma"]
        %  [0.05      0       0.1    2     0.1  ]
        params.analysis.temporal.param.tau1   = x(4);
        params.analysis.temporal.param.weight = x(5);
        params.analysis.temporal.param.tau2   = x(6);
        params.analysis.temporal.param.n      = x(7);
        params.analysis.temporal.param.sigma  = x(8);
        
end    

predictions = stPredictBOLDFromStim(params, stim);
predictions = predictions.predBOLD;
predictions = squeeze(concatRuns(predictions));
% predictions = reshape(predictions,[size(predictions,1)*nruns,size(predictions,3)]);

data = data(:);
% 
% pred_bs = cellfun(@(P, W) P .* repmat(W, size(P, 1), 1), ...
%     conv_nb, repmat({comp_ws'}, nruns, 1), 'uni', false);
% % model residuals: (predicted signal - measured signal)^2
% calc_br = cellfun(@(S, M) (sum(S, 2) - M) .^ 2, pred_bs, data, 'uni', false);
% 
if params.analysis.optim.decimate> 1
    if isfinite(predictions(:))
        data = rmDecimate(gather(data),params.analysis.optim.decimate);
        predictions = rmDecimate(gather(predictions),params.analysis.optim.decimate);
        predictions = gpuArray(predictions);
        data = gpuArray(data);
    end
end

if params.analysis.optim.ridge == 0
    % % channel weights: channel predictors \ measured signal
    comp_ws = predictions \ data;
elseif  params.analysis.optim.ridge == 1
    fracAlpha = params.analysis.optim.ridgeAlpha;
    if ~isfinite(predictions(:))
        comp_ws = predictions \ data;
    else
        [comp_ws,~,~] = fracridge(predictions,fracAlpha,data,[],1);
    end
        
end

predictions = bsxfun(@times, predictions,comp_ws');

% model residuals: (predicted signal - measured signal)^2
calc_br = bsxfun(@power,(sum(predictions,2) - data), 2);

% model error: summed squared residuals for all run time series
e = gather(sum(calc_br));


%%

figure(1)
clf;
plot(sum(predictions(:,:),2),'r'); hold on; plot(data(:),'k'); hold off;
title(calccod(gather((sum(predictions,2))),gather(data)))

% 
% [23.7,0.58,0.259,4.14,14.0,0.9996]


% designMat = [];
% for ii = 1:nruns
%     runEffect_base = reshape(zeros(size(data)),[],6);
%     runEffect_base(:,ii) = 1;
%     runEffect_base = runEffect_base(:);
%     designMat = [designMat runEffect_base];
% end
% predictions = [predictions designMat];

%%
%
% %% RF
%
% rf = pmGaussian2d(Xv, Yv, x(3), x(3), [], x(1), x(2));
% rf=rf(keep);
%
% stimRF = @(s) cellfun(@(X, Y) full(X*Y), ...
%     s,repmat({sparse(rf)}, nruns, 1), 'uni', false);
%
% sRF = stimRF(stim);
%
% if normStimRF
%     sRF = cellfun(@(x) normMax(x), sRF, 'uni', false);
% end
%
% %%
% %
% % ["tau1", "weight", "tau2", "n", "sigma", "shift", "scale"]
% % tau1 = x(4);
% % weight = x(5);
% % [0.05 0 0.1 2 0.1 0 1];
% %
% % tau1 = 0.05;
% % weight = 0;
% % n = 2;
%
%
% t_irf = 1/fs : 1/fs : 5;
% irf  = @(tau1,weight) gammaPDF(t_irf,tau1, 2) - weight.*gammaPDF(t_irf, tau1*1.5, 2);
% irf_norm = @(tau2) normSum(exp(-t_irf/tau2));
%
% % linear response: stim * IRF[tau1]
% conv_sn = @(tau1,weight) cellfun(@(X, Y) convolve_vecs(X, Y, 1, 1), ...
%     sRF, repmat({irf(tau1,weight)'}, nruns, 1), 'uni', false);
%
% % Pooled normlization response: (linear response * low-pass filter[tau2])
% conv_nf = @(tau1,weight,tau2) cellfun(@(X, F) convolve_vecs(X, F, fs, fs), ...
%     conv_sn(tau1,weight) , repmat({irf_norm(tau2)'}, nruns, 1), 'uni', false);
%
% % neural response: (linear response)^n / (sigma^n + filtered response^n)
% comp_dn = @(tau1,weight,tau2,n,sigma) cellfun(@(N, F, Z) (N .^ n) ./ (F .^n + Z .^ n), ...
%     conv_sn(tau1,weight), conv_nf(tau1,weight,tau2), repmat({sigma}, nruns, 1), 'uni', false);
%
% % bold response: neural response * HRF
% conv_nb = @(tau1,weight,tau2,n,sigma) cellfun(@(N) convolve_vecs(N, hrf, fs, 1 / tr), ...
%     comp_dn(tau1,weight,tau2,n,sigma), 'uni', false);
%
%
% %%
% nb = conv_nb(x(4),x(5),x(6),x(7),x(8));
%
% % % channel weights: channel predictors \ measured signal
% comp_ws = cell2mat(nb) \ cell2mat(data);
%
% % predicted signal: channel predictors x channel weights
% pred_bs = cellfun(@(P, W) P .* repmat(W, size(P, 1), 1), ...
%     nb, repmat({comp_ws'}, nruns, 1), 'uni', false);
%
% % model residuals: (predicted signal - measured signal)^2
% calc_br = cellfun(@(S, M) (sum(S, 2) - M) .^ 2, pred_bs, data, 'uni', false);
%
% % model error: summed squared residuals for all run time series
% e = sum(cell2mat(calc_br));
        
        
end