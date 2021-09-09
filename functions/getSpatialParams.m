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
%           * params.analysis.spatial.x0 - (int or vector) x-center position of pRFs (deg)
%           * params.analysis.spatial.y0 - (int or vector) y-center position of pRFs (deg)
%           * params.analysis.spatial.sigmaMajor - (int or vector) If linear or css pRF, 1
%                  std of circular 2D Gaussian. If elliptical pRF, 1 std for major axes (deg)
%           * params.analysis.spatial.sigmaMinor - (int or vector) If linear or css pRF, same
%                  as sigmaMajor. If elliptical pRF, sigma for minor axes (deg)
%           * params.analysis.spatial.theta - (int or vector) If linear or css pRF, theta
%                  can be empty or 0. If elliptical pRF, theta is angle (radians, 0=vertical)
%           * [params.analysis.spatial.X] - (matrix) X-axis of 2D support
%                  grid (deg), if not defined, we'll make it
%           * [params.analysis.spatial.Y] - (matrix) Y-axis of 2D support
%                  grid (deg), if not defined, we'll make it
%           * [params.analysis.spatial.pRFModelType] - (str) define if you want to use
%                  vistasoft's default 'unitHeight', or PRFModel
%                  'unitVolume' (default).
%           * [params.analysis.spatial.trimRFFlag] - (bool) if we want to
%                   truncate the RF at 5 SD or not, only for 'unitHeight' pRFs.
%           * [params.analysis.keepAllPoints] - (bool)  if we want to
%                   keep all the pixel points or not
%           * [keepPixels] - (logical) matrix or vector with dimensions stim x by stim y.
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
        params.analysis.spatialModel = 'onegaussianFit';
        params.analysis.spatial.x0 = [0 0];
        params.analysis.spatial.y0 = [0 0];
        params.analysis.spatial.sigmaMajor = [1 2];
        params.analysis.spatial.varexpl = [1 1];
        params.analysis.spatial.normPRFStimPredFlag = true;
       
    case 2
        params.analysis.spatial.fieldSize = 12;
        params.analysis.spatial.sampleRate = 12/30;
        params.analysis.spatialModel = 'onegaussianFit';
        params.analysis.spatial.x0 = [0 0];
        params.analysis.spatial.y0 = [0 0];
        params.analysis.spatial.sigmaMajor = [1 2];
        params.analysis.spatial.varexpl = [1 1];
        params.analysis.spatial.normPRFStimPredFlag = true;

end


end