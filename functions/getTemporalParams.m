function params = getTemporalParams(params)
% Function that grabs default temporal params for specified temporal pRF 
% model and puts it in params.analysis.temporalModel.
%
%   params = getTemporalParams(params)
%
% The function first checks if there is a Constant file (user-defined
% temporal parameter values). if the function does not exist, default
% temporal parameters are loaded.
%
% INPUT:
% params.analysis.temporalModel: '1ch-dcts', '2ch-exp-sig','1ch-glm'
%
% OUTPUT:
% params.analysis.temporal.fields:          parameter names
% params.analysis.temporal.temporal_param:  parameter values
% params.analysis.temporal.fs:              sampling rate (ms)
% params.analysis.temporal.tr:              TR (sec)
% params.analysis.temporal.num_channels:    number of temporal channels
%
% [ISK] note: st_getTemporalAttributes is the previous function name

%% Check if Constant file is there. 
% If there is a constant file load params from the Constants file
if exist('Constants','var') == 2
    c = Constants.getTemporalParams.temporalParams;
    for i = 1:length(c)
        if strcmp(c{i}.type, params.analysis.temporalModel)
            idx = i;
        end
    end
    temporal_param = c{idx}.prm;
    fs             = c{idx}.fs;
    num_channels   = c{idx}.num_channels;
    tr = Constants.getTemporalParams.tr; % seconds
    
    % Pass values to params
    params.analysis.temporal.model        = params.analysis.temporalModel;
    params.analysis.temporal.fields       = fields;
    params.analysis.temporal.fs           = fs;
    params.analysis.temporal.param        = temporal_param;
    params.analysis.temporal.num_channels = num_channels;
    params.analysis.temporal.tr           = tr;
    
else % load default temporal params if Constant file is not there   
    % default TR is 1 sec
    tr = 1; % sec
    switch params.analysis.temporalModel
        case '1ch-dcts' % load 1ch-dcts (DN) model params
            params.num_channels = 1;
            params.fs           = 1000; % sample rate (Hz)
            params.tau1         = 0.05; % time constant for initial gamma IRF
            params.weight       = 0;    % positive vs negative IRF weight (0 means basically no negative IRF)
            params.tau2         = 0.1;  % time constant for delayed normalization
            params.n            = 2;    % exponent
            params.sigma        = 0.1;  % constant to avoid dividing by zero
            params.shift        = 0;    % shift onset of start response (in ms?)
            params.scale        = 1;    % scale factor of final neural response
            
        case '2ch-exp-sig' % load 2ch-exp-sig (2ch) model params
            params.num_channels = 2;
            params.fs           = 1000;  % sample rate (Hz)
            params.tau_s        = 4.93;  % time constant for excitatory mechanism (ms) to create sustained gamma IRF
            params.n1           = 9;     % number of stages in excitatory mechanism
            params.n2           = 10;    % number of stages in inhibitory mechanism
            params.kappa        = 1.33;  % ratio of time constants for primary/secondary filters
            params.tau_ae       = 10000; % time constant for adaptive exponential decay (ms)
            params.Lp           = 0.1;   % Sigmoid Lambda for positive part of transient response (i.e. mid saturation point)
            params.Kp           = 3;     % Sigmoid Kappa for positive part of transient response (i.e. the slope)
            params.Kn           = 3;     % Sigmoid Kappa for negative part of transient response (i.e. the slope)
            params.weight       = 0.5;   % relative weight sustained vs transient (0.5 = equal weight for either channel)
            params.shift        = 0;     % shift of onset response (in ms?)
            
        case '1ch-glm' % load 1ch-glm (linear) model params
            params.num_channels = 2;
            params.fs           = 1000; % sample rate (Hz)
            params.shift        = 0;    % shift of onset response (in ms?)
            params.scale        = 1;    % scale factor of final neural response
          
        case '3ch-linst' % load linear 3-channel model, with a sustained, transient-odd, transient-even channel
            params.num_channels = 3;
            params.fs           = 1000; % sample rate (Hz)
            params.tau_s        = 4.93; % time constant for excitatory mechanism (ms) to create sustained gamma IRF
            params.n1           = 9;    % number of stages in excitatory mechanism
            params.n2           = 10;   % number of stages in inhibitory mechanism
            params.kappa        = 1.33; % ratio of time constants for primary/secondary filters
    end
    
    % Pass values to params
    params.analysis.temporal.model        = params.analysis.temporalModel;
    params.analysis.temporal.fs           = params.fs;
    params.analysis.temporal.param        = params;
    params.analysis.temporal.num_channels = params.num_channels;
    params.analysis.temporal.tr           = tr;
end




end