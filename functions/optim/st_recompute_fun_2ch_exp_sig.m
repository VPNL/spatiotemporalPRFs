function [w, rsp, nb] = st_recompute_fun_2ch_exp_sig(x,stim,data,Xv,Yv,keep)
% [comp_ws, conv_nb, pred_bs, obj_fun] = st_obj_fun_2ch_exp_sig(stim,data,Xv,Yv)
% Generates anonymous objective function that can be passed to fmincon for
% 2-channel model with optimized adapated sustained and sigmoid transient 
% channels).

%%
% sample rate
fs = 1000;
% % define hrf
hrf = canonical_hrf(1 / fs, [5 14 28]);
% define TR
tr = Constants.getTemporalParams.tr; % seconds
% define runs
nruns = length(stim);


%% RF

rf = pmGaussian2d(Xv, Yv, x(3), x(3), [], x(1), x(2));
rf=rf(keep);

stimRF = @(s) cellfun(@(X, Y) full(X*Y), ...
    s,repmat({sparse(rf)}, nruns, 1), 'uni', false);

sRF = stimRF(stim);
onoffsets = cellfun(@(X) st_codestim_onoff(X,fs), sRF, 'uni', false);
%%
% RF_fun = @(Xv, Yv, x0, y0, rf_sigma) ...
%     exp( ((Yv - y0).*(Yv - y0) + (Xv - x0).*(Xv - x0)) ./ (-2.*(rf_sigma.^2)));
% 
% stimRF = @(s, x0, y0, rf_sigma) cellfun(@(X, Y) full(X*Y), ...
%     s,repmat({sparse(RF_fun(Xv, Yv, x0, y0, rf_sigma))}, nruns, 1), 'uni', false);

% sRF = stimRF(stim, x(1), x(2), x(3));
% onoffsets = cellfun(@(X) st_codestim_onoff(X,fs), sRF, 'uni', false);

%% temporal
normMax = @(x) x./max(x);


% generate IRFs/filters for optimization
nrfS_fun = @(tau_s) tch_irfs('S', tau_s);
nrfT_fun = @(tau_s) tch_irfs('T', tau_s);
adapt_fun = @(tau_ae) exp(-(1:60000) / (tau_ae * 10000));

% sustained response: (stimulus * sustained IRF) x exponential[tau_ae]
conv_snS = @(tau_s, tau_ae) cellfun(@(X, Y, ONOFF) code_exp_decay2(X, ONOFF, Y, fs), ...
    cellfun(@(XX, YY) convolve_vecs(XX, YY, 1, 1), sRF, repmat({nrfS_fun(tau_s)}, nruns, 1), 'uni', false), ...
    repmat({adapt_fun(tau_ae)}, nruns, 1), onoffsets, 'uni', false);
% transient response: tch_sigmoid(stimulus * transient IRF)
conv_snT = @(tau_s) cellfun(@(X, Y) convolve_vecs(X, Y, 1, 1), ...
    sRF, repmat({nrfT_fun(tau_s)}, nruns, 1), 'uni', false);
conv_snTs = @(tau_s, Lp, Kp, Kn) cellfun(@(X, lp, kp, kn) tch_sigmoid(X, lp, kp, lp, kn), ...
    conv_snT(tau_s), repmat({Lp}, nruns, 1), repmat({Kp}, nruns, 1), repmat({Kn}, nruns, 1), 'uni', false);
% sustained BOLD: sustained response * HRF
conv_nbS = @(tau_s, tau_ae) cellfun(@(NS2) convolve_vecs(NS2, hrf, fs, 1 / tr), ...
    cellfun(@(NS1) normMax(NS1), conv_snS(tau_s, tau_ae), 'UniformOutput', false), 'uni', false);
% transient BOLD: transient response * HRF
conv_nbT = @(tau_s, Lp, Kp, Kn) cellfun(@(NT2) convolve_vecs(NT2, hrf, fs, 1 / tr), ...
      cellfun(@(NT1) normMax(NT1), conv_snTs(tau_s, Lp, Kp, Kn), 'UniformOutput', false), 'uni', false);


 %%
 % tau_s (4), tau_ae(5), Lp(6), Kp(7), Kn(8)
nbS = cellfun(@(nbS) normMax(nbS), conv_nbS(x(4), x(5)), 'UniformOutput', false);
nbT = cellfun(@(nbT) normMax(nbT), conv_nbT(x(4), x(6), x(7), x(8)), 'UniformOutput', false);

% un-weighted channel predictors: [sustained BOLD, transient BOLD]
nb = cellfun(@(S, T) [S T], nbS, nbT, 'uni', false);
% 
% % channel weights: channel predictors \ measured signal
w = cell2mat(nb) \ cell2mat(data);
% 
% % predicted signal: channel predictors x channel weights
rsp = cellfun(@(P, W) P .* repmat(W, size(P, 1), 1), nb, repmat({w'}, nruns, 1), 'uni', false);


%%
% % tau_s (4), tau_ae(5), Lp(6), Kp(7), Kn(8)
% nbS = conv_nbS(x(4), x(5));
% nbT = conv_nbT(x(4), x(6), x(7), x(8));
% 
% % do normalization
% normT = max(cell2mat(nbS))/max(cell2mat(nbT));
% 
% % un-weighted channel predictors: [sustained BOLD, transient BOLD]
% nb = cellfun(@(S, T) [S T*normT], nbS, nbT, 'uni', false);
% % 
% % % channel weights: channel predictors \ measured signal
% w = cell2mat(nb) \ cell2mat(data);
% % 
% % % predicted signal: channel predictors x channel weights
% rsp = cellfun(@(P, W) P .* repmat(W, size(P, 1), 1), nb, repmat({w'}, nruns, 1), 'uni', false);


end

