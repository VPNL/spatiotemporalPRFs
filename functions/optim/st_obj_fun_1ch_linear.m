function e = st_obj_fun_1ch_linear(x,stim,data,Xv,Yv,keep,hrf,normStimRF)
% [comp_ws, conv_nb, pred_bs, obj_fun] = st_obj_fun_2ch_exp_sig(stim,data,Xv,Yv)
% Generates anonymous objective function that can be passed to fmincon for
% 2-channel model with optimized adapated sustained and sigmoid transient 
% channels).
% 
% INPUTS:
%   1) roi: tchROI object containing single session
%   2) model: tchModel object for the same session
% 
% OUTPUTS:
%   obj_fun: anonymous objective function in the form of y = f(x0), where
%   x0 is a vector of parameters to evaluate and y is the sum of squared
%   residual error between model predictions and run response time series
% 
% AS 1/2018

% if ~strcmp(model.type, '2ch-exp-sig'); error('Incompatible model type'); end

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
comp_ws = @(m) cell2mat(conv_lin) \ cell2mat(m);
pred_bs = @(m) cellfun(@(P, W) P .* repmat(W, size(P, 1), 1), ...
    conv_lin, repmat({comp_ws(m)'}, nruns, 1), 'uni', false);

calc_br = @(m) cellfun(@(S, M) (sum(S, 2) - M) .^ 2, ...
    pred_bs(m), m, 'uni', false);
% model error: summed squared residuals for all run time series
calc_me = @(m) ...
    sum(cell2mat(calc_br(m)));

e = calc_me(data);

end

