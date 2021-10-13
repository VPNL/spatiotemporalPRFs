function params = getSpatialParams(params,optionNumber)
%% Get getSpatialParams

% Grabs default temporal params for each model (params.analysis.temporalModel) 

% The function first checks if there is a Constant file (user-defined temporal parameter values).
% if the function does not exist, default temporal parameters are loaded

% input:
% params: params to be updated
% optionNumber: pre-defined bundles of options

% output:
% %         * params.analysis.spatial.fieldSize  - (int) radius of FoV in deg, assuming square FoV
%           * params.analysis.spatial.sampleRate - (int) nr of grid points for entire FoV
%           * params.analysis.spatial.pRFModelType - (str) define if you want to use
%                  vistasoft's default 'unitHeight', or PRFModel 'unitVolume'
%           * params.analysis.spatial.trimRFFlag - (bool) if we want to
%                   truncate the RF at 5 SD or not, only for 'unitHeight' pRFs.
%           * params.analysis.spatial.keepPixels - (logical) matrix or vector with dimensions stim x by stim y.
%                   if a pixel is true, then it falls within our stimulus
%                   window and we keep it to generate pRF responses. If a
%                   pixel is false, it falls outside the stimulus window
%                   and we remove it to save computational resources.

%%
% load default temporal params
switch optionNumber
    case 1
        params.analysis.spatial.fieldSize = 12;
        params.analysis.spatial.sampleRate = 12/50;
        params.analysis.spatial.pRFModelType = 'unitVolume';
        params.analysis.spatial.keepPixels = [];
        params.analysis.spatial.sparsifyFlag = false;
       
    case 2
        params.analysis.spatial.fieldSize = 12;
        params.analysis.spatial.sampleRate = 12/30;
        params.analysis.spatialModel = 'onegaussianFit';
        params.analysis.spatial.pRFModelType = 'unitVolume';
%         params.analysis.spatial.normPRFStimPredFlag = true;
        params.analysis.spatial.keepPixels = [];
        params.analysis.spatial.sparsifyFlag = true;


end


end