function params = getParamsSTPRF()
% Function to get additional, default spatiotemporal pRF model parameters 
%
%   params = getParamsSTPRF()
%
% INPUTS
%   none
%
% OUTPUTS
%   params  : (struct) default parameters, including:
%             - params.spatialModel       : 'onegaussianFit'
%             - params.temporalModel      : '1ch-glm'
%             - params.analysis.pRFmodel  : {'st'};
%             - params.analysis.spatial.option : 2;
%             - params.analysis.keepAllPoints  : false;
%             - params.analysis.sparsifyFlag   : true;
%             - params.analysis.spatial & params.analysis.temporal defaultd
%               
%
% Written by ISK 2021 @ VPNL Stanford U

%% Parse inputs
p = inputParser;
p.addRequired('', @isnumeric);
p.addRequired('',@ischar);
p.addRequired('',@ischar);
p.addParameter('','', @ischar);
p.addParameter('spatialModel','onegaussianFit', ...
    @(x) any(validatestring(x,{'cssFit','onegaussianFit', 'differenceOfGaussiansFit'})));
p.addParameter('temporalModel','1ch-glm', ...
    @(x) any(validatestring(x,{'1ch-glm','1ch-dcts','2ch-exp-sig', '2ch-css-sig'})));
p.parse([],[],[],varargin{:});


%% 0. Get spatial and temporal parameters
% Take params and return back with the 5 t params, fs, numChannels, TR (s) 
% as fields of params.analysis.temporal.[...] 
params.analysis.pRFmodel = {'st'};
params.analysis.spatial.option  = 2;
params.analysis.temporalModel = '1ch-glm';
params.analysis.keepAllPoints = false;
params.analysis.sparsifyFlag = true;

params = getSpatialParams(params, params.analysis.spatial.option);
params = getTemporalParams(params);


