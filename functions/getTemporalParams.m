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
    
else % load default temporal params if Constant file is not there   
    % default TR is 1 sec
    tr = 1; % sec
    switch params.analysis.temporalModel
        case '1ch-dcts' % load 1ch-dcts (DN) model params
            num_channels = 1;
            fs = 1000;
            fields = ["tau1", "weight", "tau2", "nn", "delay", "shift", "scale"];
            temporal_param = [0.05 0 0.1 2 0.1 0 1];
        case '2ch-exp-sig'  % load 2ch-exp-sig (2ch) model params
            num_channels = 2;
            fs = 1000;
            fields = ["tau_s", "tau_ae", "Lp", "Kp", "Kn", "weight","shift"];
            temporal_param = [4.93 10000 0.1 3 3 0.5 0];
        case '1ch-glm' % load 1ch-glm (linear) model params
            num_channels = 1;
            fs = 1000;
            fields = ["shift", "scale"];
            temporal_param = [0 1];
    end
end

% Pass values to params
params.analysis.temporal.model        = params.analysis.temporalModel;
params.analysis.temporal.fields       = fields;
params.analysis.temporal.fs           = fs;
params.analysis.temporal.param        = temporal_param;
params.analysis.temporal.num_channels = num_channels;
params.analysis.temporal.tr           = tr;

end