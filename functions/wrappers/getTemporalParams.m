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
% params.analysis.temporalModel:  Type of temporal model. Choose from:
%                                  - '1ch-dcts' or 'DN-ST':  1-channel Delayed normalization model (Zhou et al. 2019. PLoS CB)
%                                  - '2ch-exp-sig': 2-channel Exponent-sigmoidal model, with a sustained and transient channel (Stigliani et al. 2019 PLoS CB)
%                                  - '1ch-glm' or 'spatial: 1-channel Linear model (basically a spatial-only model with a box car, no nonlinearities). 
%                                  - '3ch-stLN' or 'CST': 3-channel Linear-nonlinear model, with a sustained, transient-odd, transient-even channel (Kim et al. 2024 JNeurosci)
%                                  - 'Adelson-Bergen': spatiotemporal motion energy model (even/uneven paired gabor filter + exponential)
%                                     as described by Adelson & Bergen in 1985 JOSAA paper
% OUTPUT:
% params.analysis.temporal.fields:          parameter names
% params.analysis.temporal.temporal_param:  parameter values
% params.analysis.temporal.fs:              sampling rate (ms)
% params.analysis.temporal.tr:              TR (sec)
% params.analysis.temporal.num_channels:    number of temporal channels
%
% [ISK] note: st_getTemporalAttributes is the previous function name
%
% Written by ERK & IK 2021 @ VPNL Stanford U

%% Check if Constant file is there.

% default TR is 1 sec
if isfield(params,'stim')
    tr = params.stim.framePeriod;
else
    tr = 1; % sec
end

switch params.analysis.temporalModel
    case {'1ch-dcts', 'DN-ST'} % load 1ch-dcts (DN) model params
        p.num_channels = 1;
        p.fs           = 1000; % sample rate (Hz)
        p.tau1         = 0.05; % time constant for initial gamma IRF
        p.weight       = 0;    % positive vs negative IRF weight (0 means basically no negative IRF)
        p.tau2         = 0.1;  % time constant for delayed normalization
        p.n            = 2;    % exponent
        p.sigma        = 0.1;  % constant to avoid dividing by zero
        p.shift        = 0;    % shift onset of start response (in ms?)
        p.scale        = 1;    % scale factor of final neural response
        
    case '2ch-exp-sig' % load 2ch-exp-sig (2ch) model params
        p.num_channels = 2;
        p.fs           = 1000;  % sample rate (Hz)
        p.tau_s        = 4.93;  % time constant for excitatory mechanism (ms) to create sustained gamma IRF
        p.n1           = 9;     % number of stages in excitatory mechanism
        p.n2           = 10;    % number of stages in inhibitory mechanism
        p.kappa        = 1.33;  % ratio of time constants for primary/secondary filters
        p.tau_ae       = 10000; % time constant for adaptive exponential decay (ms)
        p.Lp           = 0.1;   % Sigmoid Lambda for positive part of transient response (i.e. mid saturation point)
        p.Kp           = 3;     % Sigmoid Kappa for positive part of transient response (i.e. the slope)
        p.Kn           = 3;     % Sigmoid Kappa for negative part of transient response (i.e. the slope)
        p.weight       = 0.5;   % relative weight sustained vs transient (0.5 = equal weight for either channel)
        p.shift        = 0;     % shift of onset response (in ms?)
        
    case {'1ch-glm','spatial'} % load 1ch-glm (linear) model params
        p.num_channels = 1;
        p.fs           = 1000; % sample rate (Hz)
        p.shift        = 0;    % shift of onset response (in ms?)
        p.scale        = 1;    % scale factor of final neural response


    case {'3ch-stLN', 'CST' }% load linear-nonlinear 3-channel model, with a sustained, transient-odd, transient-even channel
        p.num_channels = 3;
        p.fs           = 1000; % sample rate (Hz)
        p.tau_s        = 4.93; % time constant for excitatory mechanism (ms) to create sustained gamma IRF
        p.tau_t        = 4.93; % time constant for excitatory mechanism (ms) to create transient gamma IRF
        p.n1           = 9;    % number of stages in excitatory mechanism
        p.n2           = 10;   % number of stages in inhibitory mechanism
        p.kappa        = 1.33; % ratio of time constants for primary/secondary filters
        %             if isfield(params.analysis.temporal.param,'exponent')
        %                 p.exp = params.analysis.temporal.param.exponent;
        %             else % go with default
        p.exponent          = 0.5;  % nonlinear compressive exponent for spatiotemporal nonlinearity
        %             end
        p.combineNeuralChan =  [1 2 2]; % keep sustained channel and combine the on and off-transient channels
%         params.analysis.combineNeuralChan = [1 2 2]; 
        
    case 'Adelson-Bergen'
        p.num_channels = 2;
        p.fs           = 1000; % sample rate (Hz)
        
end

% Pass values to params
params.analysis.temporal.model        = params.analysis.temporalModel;
params.analysis.temporal.fs           = p.fs;
params.analysis.temporal.param        = p;
params.analysis.temporal.num_channels = p.num_channels;
params.analysis.temporal.tr           = tr;

if isfield(p,'combineNeuralChan')
    params.analysis.combineNeuralChan     = p.combineNeuralChan;
end
% load default temporal params if Constant file is not there
% % If there is a constant file load params from the Constants file
% if exist('Constants','var') == 2
%     c = Constants.getTemporalParams.temporalParams;
%     for i = 1:length(c)
%         if strcmp(c{i}.type, params.analysis.temporalModel)
%             idx = i;
%         end
%     end
%     temporal_param = c{idx}.prm;
%     fs             = c{idx}.fs;
%     num_channels   = c{idx}.num_channels;
%     tr = Constants.getTemporalParams.tr; % seconds
%
%     % Pass values to params
%     params.analysis.temporal.model        = params.analysis.temporalModel;
%     params.analysis.temporal.fields       = fields;
%     params.analysis.temporal.fs           = fs; % todo: make one fs for both neural and HRF sampling rate
%     params.analysis.temporal.param        = temporal_param;
%     params.analysis.temporal.num_channels = num_channels;
%     params.analysis.temporal.tr           = tr;


end