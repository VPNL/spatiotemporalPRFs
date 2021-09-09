function predictions = stPredictBOLDFromStim(params, stim)
% Wrapper function to predict BOLD time series (% change) from stimulus,
% using a spatiotemporal pRF model
%
% INPUTS:
% params   : struct containing:
%            * params.saveDataFlag (bool): save predictions or not
%            * params.stim: struct with stimulus variables
%                - images_unconvolved (x,y,t)
%            * params.recomputePredictionsFlag: recompute (false) or
%              load from file (true), file name is defined in:
%              params.analysis.predFile
%            * params.analysis
%                - fieldSize (int): radius stimulus field of view (deg)
%                - sampleRate (int): nr of pixels from left to right
%                - predFile (str): where to save/load predictedBOLD file
%                - temporalModel (str): Choose from '1ch-glm','1ch-dcts',
%                '2ch-exp-sig'
%                - spatial (struct): with pRF params x0, y0, sigma,
%                varexplained, exponent, pRFModelType ('unitHeight' or
%                'unitVolume'), etc.
%  stimulus     : tktktk
%
% OUTPUTS:
% predictions : struct containing:
%               * tktktktk
%
%{
% Example:
params.saveDataFlag = true;
params.stim.sparsifyFlag = false;
params.recomputePredictionsFlag = true;
params.analysis.spatial.fieldSize = 12;
params.analysis.spatial.sampleRate = 12/50;
params.analysis.keepAllPoints = true;
params.analysis.predFile = 'tmp.mat';
params.analysis.temporalModel = '1ch-dcts';
params.analysis.spatialModel = 'onegaussianFit';
params.analysis.spatial.x0 = [0 0];
params.analysis.spatial.y0 = [0 0];
params.analysis.spatial.sigmaMajor = [1 2];
params.analysis.spatial.varexpl = [1 1];
params.analysis.spatial.sparsifyFlag = false;
params.analysis.zeroPadPredNeuralFlag = true;
params.analysis.spatial.normPRFStimPredFlag = true;
predictions = stPredictBOLDFromStim(params)
%}
%
%
% Written by IK and ERK 2021 @ VPNL Stanford U

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

%% 1. Define hrf
hrf = canonical_hrf(1 / params.analysis.temporal.fs, [5 14 28]);

predictions = struct();
fprintf('Computing BOLD predictions for %s model \n', ...
    params.analysis.temporalModel); drawnow;

%% 2. Get pRFs
% Take spatial model params as input to get either
% standard 2D Gaussian or CSS 2D Gaussian. This requires:
% * params.analysis.fieldSize
% * params.analysis.sampleRate
% * params.analysis.spatial.x0, y0, sigmaMajor, sigmaMinor, theta
% prfs are [x-pixels by y-pixels (in deg)] by nrOfVoxels
[prfs, params] = getPRFs(params);
 
nVoxels = numel(params.analysis.spatial.x0);
fprintf('[%s]: Making model samples for %d voxels/vertices:',mfilename,nVoxels);
fprintf('[%s]: Generating irf for %s model...\n', mfilename, params.analysis.temporal.model)

%% 6. Compute RF X Stim
% Get neural pRF time course for given pRF xy (pixels) by voxels
% and stimulus xy (pixels) by time (ms)
prfResponse = getPRFStimResponse(stim, prfs, params);
    
%% 7. Compute spatiotemporal response in milliseconds
[predNeural, params] = getPredictedNeuralResponse(params, prfResponse);

%% 8. Compute spatiotemporal BOLD response in TRs
% TODO: predBOLD(n,channels,time) = getPredictedBOLDResponse(params, predNeural(n,:,:), hrf)

% Subfunction description: Convolve neural prediction with hrf
% to get predicted BOLD response for voxel

% see old code:
%             predBOLD = cellfun(@(X, Y) convolve_vecs(X, Y, params.temporal.fs, 1 /params.temporal.tr), ...
%                 rsp, repmat({hrf}, size(predNeural)), 'uni', false);
%             predBOLD = cell2mat(predBOLD);
    


%% 9. Store predictions in struct
predictions(s).predBOLD = predBOLD; clear predBOLD
predictions(s).predNeural = predNeural; clear predNeural

fprintf('[%s]: Finished simulus = %d. Time: %d min.\t(%s)\n', ...
    mfilename, s, round(toc/60), datestr(now));
drawnow;



%% 10. Save predictions if requested
if params.saveDataFlag
    fprintf('[%s]: Saving data.. \n', mfilename)
    save(params.analysis.predFile, 'predictions','-v7.3')
    fprintf('[%s]: Done!\n', mfilename)
end

end


