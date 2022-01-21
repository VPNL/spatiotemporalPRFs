function e = st_obj_fun_2ch_exp_sig(x,stim,data,Xv,Yv,keep,hrf,normStimRF)
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


if notDefined('normStimRF')
    normStimRF = 0;
end

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

% % double check stim
% rfStim = full(cell2mat(stim)*sparse(rf));
% 
% 
% RF_fun = @(Xv, Yv, x0, y0, rf_sigma) ...
%     exp( ((Yv - y0).*(Yv - y0) + (Xv - x0).*(Xv - x0)) ./ (-2.*(rf_sigma.^2)));

% stimRF = @(s, x0, y0, rf_sigma) cellfun(@(X, Y) full(X*Y), ...
%     s,repmat({sparse(RF_fun(Xv, Yv, x0, y0, rf_sigma))}, nruns, 1), 'uni', false);
% stimRF = @(s, x0, y0, rf_sigma) cellfun(@(X, Y) X*Y, ...
%     s,repmat({sparse(RF_fun(Xv, Yv, x0, y0, rf_sigma))}, nruns, 1), 'uni', false);

% stimRF = @(s, x0, y0, rf_sigma) cellfun(@(X, Y) full(X*Y), ...
%     s,repmat({RF_fun(Xv, Yv, x0, y0, rf_sigma)}, nruns, 1), 'uni', false);

sRF = stimRF(stim);

if normStimRF
    sRF = cellfun(@(x) normMax(x), sRF, 'uni', false);
end

% sRF = stimRF(stim, x(1), x(2), x(3));
onoffsets = cellfun(@(X) st_codestim_onoff(X,fs), sRF, 'uni', false);

%% temporal

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


% sustained BOLD: sustained response * HRF
% conv_nbS = @(tau_s, tau_ae) cellfun(@(NS) convolve_vecs(NS, hrf, fs, 1 / tr), ...
%     conv_snS(tau_s, tau_ae), 'uni', false);
% transient BOLD: transient response * HRF
% conv_nbT = @(tau_s, Lp, Kp, Kn) cellfun(@(NT) convolve_vecs(NT, hrf, fs, 1 / tr), ...
%     conv_snTs(tau_s, Lp, Kp, Kn), 'uni', false);
% 

%%
% channel predictors: [sustained BOLD, transient BOLD]

nbS = conv_nbS(x(4), x(5));
nbT = conv_nbT(x(4), x(6), x(7), x(8));

maxNorm = num2cell(cellfun(@max, nbS) ./ cellfun(@max, nbT));
norm_nbT = cellfun(@(x,y) x*y,maxNorm,nbT,'uni',false);

% un-weighted channel predictors: [sustained BOLD, transient BOLD]
conv_nb = cellfun(@(S, T) [S T], nbS, norm_nbT , 'uni', false);

% % channel weights: channel predictors \ measured signal
comp_ws = cell2mat(conv_nb) \ cell2mat(data);

% predicted signal: channel predictors x channel weights
pred_bs = cellfun(@(P, W) P .* repmat(W, size(P, 1), 1), ...
    conv_nb, repmat({comp_ws'}, nruns, 1), 'uni', false);
% model residuals: (predicted signal - measured signal)^2
calc_br = cellfun(@(S, M) (sum(S, 2) - M) .^ 2, pred_bs, data, 'uni', false);
% model error: summed squared residuals for all run time series
e = sum(cell2mat(calc_br));


%%
% conv_nb = @(tau_s, tau_ae, Lp, Kp, Kn) cellfun(@(S, T) [S T], ...
%     conv_nbS(tau_s, tau_ae), conv_nbT(tau_s, Lp, Kp, Kn) , 'uni', false);

% conv_nb = @(tau_s, tau_ae, Lp, Kp, Kn, weight) cellfun(@(S, T) [S*weight T*(1-weight)], ...
%     conv_nbS(tau_s, tau_ae), conv_nbT(tau_s, Lp, Kp, Kn) , 'uni', false);

% conv_nb = @(tau_s, tau_ae, Lp, Kp, Kn) cellfun(@(S, T) [S T], ...
%      cellfun(@(nbS) normMax(nbS), conv_nbS(tau_s, tau_ae), 'UniformOutput', false), ...
%      cellfun(@(nbT) normMax(nbT), conv_nbT(tau_s, Lp, Kp, Kn), 'UniformOutput', false), 'uni', false);

 
% measured signal: time series - baseline estimates
% comp_bs = @(m, b0) cellfun(@(M, B0) M - repmat(B0, size(M, 1), 1), ...
%     m, b0, 'uni', false);
% channel weights: channel predictors \ measured signal
% comp_ws = @(tau_s, tau_ae, Lp, Kp, Kn, m) ...
%     cell2mat(conv_nb(tau_s, tau_ae, Lp, Kp, Kn)) \ cell2mat(m);
% % predicted signal: channel predictors x channel weights
% pred_bs = @(tau_s, tau_ae, Lp, Kp, Kn, m) cellfun(@(P, W) P .* repmat(W, size(P, 1), 1), ...
%     conv_nb(tau_s, tau_ae, Lp, Kp, Kn), repmat({comp_ws(tau_s, tau_ae, Lp, Kp, Kn, m)'}, nruns, 1), 'uni', false);
% % model residuals: (predicted signal - measured signal)^2
% calc_br = @(tau_s, tau_ae, Lp, Kp, Kn, m) cellfun(@(S, M) (sum(S, 2) - M) .^ 2, ...
%     pred_bs(tau_s, tau_ae, Lp, Kp, Kn, m), m, 'uni', false);
% % model error: summed squared residuals for all run time series
% calc_me = @(tau_s, tau_ae, Lp, Kp, Kn, m) ...
%     sum(cell2mat(calc_br(tau_s, tau_ae, Lp, Kp, Kn, m)));

% % tau_s, tau_ae, Lp, Kp, Kn, data
% sig = conv_nb(x(4), x(5), x(6), x(7), x(8));
% e = calc_me(x(4), x(5), x(6), x(7), x(8), data);
% obj_fun = @(x) calc_me(x(1), x(2), x(3), x(4), x(5), x(6), x(7), x(8), x(9),data);

%%
% % 
% Yv =Y;
% Xv = X;
% % % 
% tau_s = 4.9;
% tau_ae = 1;
% Lp = 0.1;
% Kp = 3;
% Kn = 3;

% x0 = 0;
% y0 = 0;
% rf_sigma = 1;
% weight = 0.5;
% s=stim; m = data;
% m = vData_all{ii};
% x(1) = x0; x(2)=y0; x(3)=rf_sigma; x(4)=tau_s; x(5)=tau_ae; x(6)=Lp; x(7)=Kp; x(8)=Kn; x(9)=weight;
end

