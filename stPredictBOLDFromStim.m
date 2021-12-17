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
stim = cat(2,zeros(101*101,1000), ones(101*101,5000), zeros(101*101,1000));
params.saveDataFlag = true;
params.stim.sparsifyFlag = false;
params.recomputePredictionsFlag = true;
params.analysis.predFile = 'tmp.mat';
params.analysis.temporalModel = '3ch-linst';
params.analysis.spatialModel = 'onegaussianFit';
params.analysis.zeroPadPredNeuralFlag = true;
params = getSpatialParams(params,1);
params = getTemporalParams(params);
params.analysis.spatial.x0 = [0 0];
params.analysis.spatial.y0 = [0 0];
params.analysis.spatial.sigmaMajor = [1 2];
predictions = stPredictBOLDFromStim(params,stim)
%}
%
%
% Written by IK and ERK 2021 @ VPNL Stanford U

%% 0. Print status
tic
predictions = struct();
fprintf('[%s]: Computing BOLD predictions for %s %s model \n', ...
    mfilename,params.analysis.spatialModel, params.analysis.temporalModel); drawnow;

%% 1. Create initial linear filters (spatio-, temporal-, or spatiotemporal pRFs)
% Depending on model params, we either reconstruct a standard 2D Gaussian, 
% CSS 2D Gaussian, or 3D spatiotemporal filter:
% 1D Temporal pRFs filters are in time (ms) by nr of voxels/vertices
% 2D Spatial pRF filters are in xy (pixels) by time (ms) by nr of voxels/vertices
% 3D Spatiotemporal pRFs filters are in  xy (pixels) by time (ms) by nr of voxels/vertices
[linearPRFModel, params] = get3DSpatiotemporalpRFs(params);
 
nVoxels = size(linearPRFModel.spatial.prfs,2);
fprintf('[%s]: Making model predictions for %d voxels/vertices \n',mfilename,nVoxels);

%% 2. Compute spatiotemporal response in milliseconds (pRF X Stim)
% Get pRF time course (time in ms by voxels), for given pRF filter (xy in
% pixels by voxels) and stimulus (xy in pixels  by time in ms)
prfResponse = getPRFStimResponse(stim, linearPRFModel, params);

%% 3. Apply ReLU 
[relu_prfResponse, params] = applyReLU(prfResponse,params);

%% 3. Apply nonlinearity (spatial compression, temporal compression)
% pRF time course array remains the same size: time (ms) by voxels
[predNeural, params] = applyNonlinearity(relu_prfResponse, params);

%% 4. Check if we need to add zeros, if we want predNeural length in integers of TRs
if params.analysis.zeroPadPredNeuralFlag    
    if mod(size(predNeural,1),params.analysis.temporal.fs)
        padZeros = zeros(params.analysis.temporal.fs-mod(size(predNeural,1),params.analysis.temporal.fs), size(predNeural,2),size(predNeural,3)); 
        predNeural = cat(1,predNeural, padZeros);
    end
end

%% 5. Check if want to combine neural channels
% combineNeuralChan should be a vector that list the order and summing of
% runs. If all runs are unique, we would have a vector of [1:N channels].
% If you want to combine the last two channels, you can write e.g. [1 2 2].
if isfield(params.analysis,'combineNeuralChan') && ...
        (length(params.analysis.combineNeuralChan) ~= length(unique(params.analysis.combineNeuralChan)))
    uniqueRuns = unique(params.analysis.combineNeuralChan);
    % Get new array, use same size to ensure dimensions are correct.
    predNeuralComb = zeros(size(predNeural));
    % Then truncate the 3 dimension (with channels) to the number of unique
    % runs:
    predNeuralComb = predNeuralComb(:,:,1:length(uniqueRuns),:);
    for cb = 1:length(uniqueRuns)
        predNeuralComb(:,:,uniqueRuns(cb)) = sum(predNeural(:,:,params.analysis.combineNeuralChan==uniqueRuns(cb)),3);
    end
    predNeural = predNeuralComb;
end

%% 7. Check if we want to normalize the max height of the neural channels
if params.analysis.normNeuralChan
    for ii = 1:size(predNeural,3)
        predNeural(:,:,ii) = normMax(predNeural(:,:,ii));
    end
end

%% 8. Compute spatiotemporal BOLD response in TRs
% Define hrf
hrf = getHRF(params);

% Convolve neural response with HRF per channel, and downsample to TR
predBOLD = getPredictedBOLDResponse(predNeural, hrf, params);

%% 9. Store predictions in struct
predictions.predBOLD    = predBOLD; 
predictions.predNeural  = predNeural;
predictions.params      = params;
predictions.prfs        = linearPRFModel.spatial.prfs;
predictions.prfResponse = prfResponse;
predictions.hrf         = hrf;

%% 10. Save predictions if requested
if params.saveDataFlag
    fprintf('[%s]: Saving data.. \n', mfilename)
    save(params.analysis.predFile, '-struct', 'predictions', 'predBOLD','predNeural','params','prfs','prfResponse','hrf','-v7.3')
    fprintf('[%s]: Done!\n', mfilename)
end

%% 11. Print status
fprintf('[%s]: Finished! Time: %d min.\t(%s)\n', ...
    mfilename, round(toc/60), datestr(now));

return


