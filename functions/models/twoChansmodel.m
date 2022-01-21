function result = twoChansmodel(param, prfResponse, t)
% Function to predict neural response to time course using the 2-channel
% temporal model with a sustained channel (using a exponential decay) and
% a transient channel (using a nonlinear on/off sigmoidal function)  
% 
%   result = twoChansmodel(params, stimulus, t)
%
% INPUTS  -----------------------------------------------------------------
% params      : (struct) should contain the following fields:
%               * tau_s:    exponential time constant, in units of second
%               * tau_ae:   exponential decay
%               * lambda_p: sigmoidal ???
%               * kappa_p:  positive sigmoidal ???
%               * kappa_n:  negative sigmoidal ???
%               * weight:   how much weight to put on sustained vs transient channel
%               * shift:    time between stimulus onset and when the signal 
%                           reaches the cortex, in unit of second
% prfResponse : (double) pRF response to given stimulus, can also be the 
%                   stimulus contrast time course, if you assume a full field 
%                   stimulus that covers the entire pRF. Dimension are number 
%                   time points (ms) by nr of pRFs 
% t           : (double) corresponding time axis of prfResponse (1xtime
%                   points in ms)
% OUTPUTS
% result     : (cell) predicted neural channel response.
% 
%% Derive model parameters 
dt      = t(2) - t(1);
x       = [];
fields  = {'tau_s', 'tau_ae', 'lambda_p', 'kappa_p', 'kappa_n', 'weight','shift'};
x       = toSetField(x, fields, param);

%% Default parameters for impulse response functions
if nargin ~= 3; error('Unexpected input arguments.'); end

% default paramters for channel IRFs
n1 = 9; n2 = 10; kappa = 1.33; fs = 1000;

%% Create IRFs for sustained and transient channel
nrfS = tch_irfs('S', x.tau_s, n1, n2, kappa, fs);
nrfT = tch_irfs('T', x.tau_s, n1, n2, kappa, fs);

adapt_exp = exp(-(1:60000) / x.tau_ae);

% preallocate space
adapt_acts = zeros(size(prfResponse, 1),size(prfResponse, 2));
predTs     = adapt_acts; 
output     = adapt_acts;

for ii = 1 : size(prfResponse, 2)
    
    % ADD SHIFT TO THE STIMULUS -------------------------------------------
    if x.shift > 0
        sft       = round(x.shift * (1/dt));
        tmp       = padarray(prfResponse(:, ii), [0, sft], 0, 'pre');
        prfResponse(:, ii) = tmp(1 : size(prfResponse, 1));
    end
    
    % code stimulus on and offs -------------------------------------------
    [onsets,offsets, ~] = st_codestim(prfResponse(:, ii));
   
    % sustained with adaptation
    adapts = convCut(nrfS, prfResponse(:, ii), size(prfResponse,1));
    adapt_acts(:, ii) = code_exp_decay(adapts, onsets,offsets,adapt_exp,fs);
    adapt_acts(:, ii) = x.weight * adapt_acts(:, ii);
    adapt_acts(:, ii) = normMax(adapt_acts(:, ii));

    % transient with sigmoid
    predT = convCut(nrfT, prfResponse(:, ii), size(prfResponse,1));
    predTs(:, ii) = tch_sigmoid(predT, x.lambda_p, x.kappa_p, x.lambda_p, x.kappa_n);
    predTs(:, ii) = (1-x.weight) * predTs(:,ii);
    predTs(:, ii) = normMax(predTs(:,ii));

    % Combine the two channels
    output(:, ii) = adapt_acts(:,ii) + predTs(:,ii);

end

% sustained, transient, resp (weighted sum)
result{1}  = adapt_acts;
result{2}  = predTs;
% result{3}  = output;





end