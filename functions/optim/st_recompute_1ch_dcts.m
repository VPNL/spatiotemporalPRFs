function [comp_ws, rsp, nb] = st_recompute_1ch_dcts(x,stim,data,Xv,Yv,keep,hrf,normStimRF)
% [comp_ws, conv_nb, pred_bs, obj_fun] = st_obj_fun_2ch_exp_sig(stim,data,Xv,Yv)
% Generates anonymous objective function that can be passed to fmincon for
% 2-channel model with optimized adapated sustained and sigmoid transient 
% channels).

%%function e = st_obj_fun_1ch_dcts(x,stim,data,Xv,Yv,keep)
% Generates anonymous objective function that can be passed to fmincon for
% the 1ch-dcts model (single channel with dynamtic CTS)
% 

%%
if notDefined('normStimRF')
    normStimRF = 0;
end

%%

% sample rate
fs = 1000;
% define TR
tr = Constants.getTemporalParams.tr; % seconds
% define runs
nruns = length(stim);

% define functions
normMax = @(x) x./max(x);
normSum = @(x) x./sum(x);


%% RF
rf = pmGaussian2d(Xv, Yv, x(3), x(3), [], x(1), x(2));
rf=rf(keep);

stimRF = @(s) cellfun(@(X, Y) full(X*Y), ...
    s,repmat({sparse(rf)}, nruns, 1), 'uni', false);

sRF = stimRF(stim);

if normStimRF
    sRF = cellfun(@(x) normMax(x), sRF, 'uni', false);
end

%%
t_irf = 1/fs : 1/fs : 1;
irf  = @(tau1,weight) gammaPDF(t_irf,tau1, 2) - weight.*gammaPDF(t_irf, tau1*1.5, 2);
irf_norm = @(tau2) normSum(exp(-t_irf/tau2));

% linear response: stim * IRF[tau1]
conv_sn = @(tau1,weight) cellfun(@(X, Y) convolve_vecs(X, Y, 1, 1), ...
    sRF, repmat({irf(tau1,weight)'}, nruns, 1), 'uni', false);

% Pooled normlization response: (linear response * low-pass filter[tau2])
conv_nf = @(tau1,weight,tau2) cellfun(@(X, F) convolve_vecs(X, F, fs, fs), ...
    conv_sn(tau1,weight) , repmat({irf_norm(tau2)'}, nruns, 1), 'uni', false);

% neural response: (linear response)^n / (sigma^n + filtered response^n)
comp_dn = @(tau1,weight,tau2,n,sigma) cellfun(@(N, F, Z) (N .^ n) ./ (F .^n + Z .^ n), ...
    conv_sn(tau1,weight), conv_nf(tau1,weight,tau2), repmat({sigma}, nruns, 1), 'uni', false);

% bold response: neural response * HRF
conv_nb = @(tau1,weight,tau2,n,sigma) cellfun(@(N) convolve_vecs(N, hrf, fs, 1 / tr), ...
    comp_dn(tau1,weight,tau2,n,sigma), 'uni', false);


%%
nb = conv_nb(x(4),x(5),x(6),x(7),x(8));

% % channel weights: channel predictors \ measured signal
comp_ws = cell2mat(nb) \ cell2mat(data);

% predicted signal: channel predictors x channel weights
rsp = cellfun(@(P, W) P .* repmat(W, size(P, 1), 1), ...
    nb, repmat({comp_ws'}, nruns, 1), 'uni', false);



end

