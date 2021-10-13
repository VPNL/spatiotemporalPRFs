function result = DNmodel(param, prfResponse)
% Function to predict neural response to time course using the Divisive
% Normalization (DN) model  
% 
%   result = DNmodel(param, stim, t)
%
% INPUTS  -----------------------------------------------------------------
% params      : (struct) should contain the following fields:
%               * tau1:   irf peak time, in unit of second
%               * weight: the weight in the biphasic irf function, set 
%                         weight to 0 if want to use uniphasic irf function.
%               * tau2:   time window of adaptation, in unit of second
%               * n:      exponent
%               * sigma:  semi-saturation constant
%               * shift:  time between stimulus onset and when the signal 
%                         reaches the cortex, in unit of second
%               * scale:  response gain.
%               * fs:     sampling rate (Hz)
% prfResponse : (double) pRF response to given stimulus, can also be the 
%                   stimulus contrast time course, if you assume a full field 
%                   stimulus that covers the entire pRF. Dimension are time 
%                   (ms) by number of pRFs. 
% OUTPUTS
% result     : (cell) predicted neural channel response.

% 04/05 I added parameter field "n", 

%% PRE-DEFINED /EXTRACTED VARIABLES
dt      = 1/param.fs;
t_lth   = size(prfResponse,1);

%% COMPUTE THE IMPULSE RESPONSE FUNCTION
% HERE I ASSUME THAT THE NEGATIVE PART OF THE IMPULSE RESPONSE HAS A TIME
% CONSTANT 1.5 TIMES THAT OF THE POSITIVE PART OF THE IMPULSE RESPONSE
if param.tau1 > 0.5, warning('tau1>1, the estimation for other parameters may not be accurate'); end
    
t_irf   = dt : dt : 5;

irf_pos = gammaPDF(t_irf, param.tau1, 2);
irf_neg = gammaPDF(t_irf, param.tau1*1.5, 2);
irf     = irf_pos - param.weight.* irf_neg;

%% COMPUTE THE DELAYED REPSONSE FOR THE NORMALIZATION POOL
irf_norm = normSum(exp(-t_irf/param.tau2));

%% COMPUTE THE NORMALIZATION RESPONSE

% Preallocate space
linrsp         = zeros(size(prfResponse, 1),size(prfResponse, 2));
numrsp         = linrsp; 
poolrsp        = linrsp; 
demrsp         = linrsp; 
finalneuralrsp = linrsp;

for ii = 1 : size(prfResponse, 2)
    % ADD SHIFT TO THE STIMULUS
    if param.shift > 0
        sft   = round(param.shift * (1/dt));
        tmp   = padarray(prfResponse(ii, :), [0, sft], 0, 'pre');
        prfResponse(:, ii) = tmp(1 : size(prfResponse, 1));
    end
    
    % COMPUTE THE NORMALIZATION NUMERATOR
    linrsp(:, ii)  = convCut(prfResponse(:, ii)', irf, t_lth);
    numrsp(:, ii)  = linrsp(:, ii).^param.n;
    
    % COMPUTE THE NORMALIZATION DENOMINATOR
    poolrsp(:, ii) = convCut(linrsp(:, ii), irf_norm, t_lth);
    demrsp(:, ii)  = param.sigma.^param.n + poolrsp(:, ii).^param.n;
    
    % COMPUTE THE NORMALIZATION RESPONSE
    finalneuralrsp(:, ii) = param.scale.*(numrsp(:, ii)./demrsp(:, ii));
    
end

% Store output in result variable
result = finalneuralrsp;


end