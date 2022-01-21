function [comp_ws, rsp, conv_lin] = st_recompute_1ch_linear(x,stim,data,Xv,Yv,keep,hrf,normStimRF)
% [comp_ws, conv_nb, pred_bs, obj_fun] = st_obj_fun_2ch_exp_sig(stim,data,Xv,Yv)
% Generates anonymous objective function that can be passed to fmincon for
% 2-channel model with optimized adapated sustained and sigmoid transient 
% channels).

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

%% RF
rf = pmGaussian2d(Xv, Yv, x(3), x(3), [], x(1), x(2));
rf=rf(keep);

stimRF = @(s) cellfun(@(X, Y) full(X*Y), ...
    s,repmat({sparse(rf)}, nruns, 1), 'uni', false);

sRF = stimRF(stim);

if normStimRF
    sRF = cellfun(@(x) normMax(x), sRF, 'uni', false);
end

%% temporal
conv_lin = cellfun(@(LINS) convolve_vecs(LINS, hrf, fs, 1 / tr), sRF, 'uni', false);

%% 
comp_ws = cell2mat(conv_lin) \ cell2mat(data);

rsp = cellfun(@(P, W) P .* repmat(W, size(P, 1), 1), ...
    conv_lin, repmat({comp_ws'}, nruns, 1), 'uni', false);


end

