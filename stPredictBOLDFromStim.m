function predictions = stPredictBOLDFromStim(params, stim)
% Main wrapper function to predict BOLD time series (% change) from visual 
% stimulus array, using a spatiotemporal pRF model. This pRF model is used
% in the following papers:
%  * Characteristics of spatiotemporal population receptive fields across
%      human visual streams. By Kim, Kupers, Grill-Spector (2024).
%      J Neurosci. DOI: https://doi.org/10.1523/JNEUROSCI.0803-23.2023
%  * Rethinking simultaneous suppression in visual cortex via compressive 
%      spatiotemporal population receptive fields. By Kupers, Kim, 
%       Grill-Spector (2024). Nature Communications. DOI: XXX
% 
% TOOLBOX DEPENDENCIES: 
% * Vistasoft: https://github.com/vistalab/vistasoft
%
% INPUTS:
% params      : (struct) list of stored parameters, including
%               * params.saveDataFlag (bool): save predictions or not
%               * params.stim: struct with stimulus variables
%                - images_unconvolved [x (pixels) × y (pixels) × time (ms)]
%               * params.recomputePredictionsFlag: recompute (false) or
%                   load from file (true), file name is defined in:
%                   params.analysis.predFile
%               * params.analysis
%                - fieldSize (int)    : radius stimulus field of view (deg)
%                - sampleRate (int)   : nr of pixels from left to right
%                - predFile (str)     : where to save/load predictedBOLD file
%                - temporalModel (str): Choose from '1ch-glm','1ch-dcts',
%                                       '3ch-stLN'
%                - spatial (struct)   : with pRF params [x0,y0,sigma,
%                                       varexplained,exponent],pRFModelType
%                                       ('unitHeight' or 'unitVolume'), etc.
%  stimulus   : (array or matrix) stimulus [xy (pixels) × time (ms)]
%
% OUTPUTS:
% predictions : struct containing:
%               * prfResponse : (double) time series when computing pRF*stim
%                               [time (ms) × voxels × channels (× runs)]
%               * predNeural  : (double) predicted neural time series, i.e.
%               prfResponse subjected to all nonlinearities/relu/combining channels
%                               [time (ms) × voxels × channels (× runs)]
%               * predBOLD    : (double) predicted BOLD time series 
%                               [time (TR) × voxels × channels (× runs)]
%               * params      : (struct) defined parameters, including
%                               stim, analysis and general.
%               * prfs        : (double) spatial component of pRFs 
%                               [xy (pixels) × voxels]
%               * hrf         : (double) vector or matrix with hemodynamic
%                               response function(s) [time (ms) × voxels]
%
%
% Written by IK and ERK 2021 @ VPNL Stanford U
%
%{
% Example:
 barStim = zeros(101,101); barStim(50:70,:) = 1; 
 stim   = cat(3,zeros(101,101,1000), repmat(barStim,[1,1,250]), zeros(101,101,10000));
 stim   = reshape(stim,101*101,[]);
 params = getExampleParams;
 predictions = stPredictBOLDFromStim(params,stim)
%}


%% 0. Check input variables and print status
tic

% Preallocate struct for output predictions
predictions = struct();

% Print status if left undefined
if ~isfield(params,'verbose')
    params.verbose = 1;
end
% Don't use GPU arrays if left undefined
if ~isfield(params,'useGPU')
    params.useGPU = 0;
end

if params.verbose
    fprintf('[%s]: Computing BOLD predictions for %s %s model \n', ...
        mfilename,params.analysis.spatialModel, params.analysis.temporalModel); drawnow;
end

%% 1. Create initial linear filters (spatio-, temporal-, or spatiotemporal pRFs)
% Depending on model params, we either reconstruct a standard 2D Gaussian, 
% CSS 2D Gaussian, or 3D spatiotemporal filter:
% 1D Temporal pRFs filters are in time (ms) by nr of voxels/vertices
% 2D Spatial pRF filters are in xy (pixels) by time (ms) by nr of voxels/vertices
% 3D Spatiotemporal pRFs filters are in  xy (pixels) by time (ms) by nr of voxels/vertices
[linearPRFModel, params] = get3DSpatiotemporalpRFs(params);

nVoxels = size(linearPRFModel.spatial.prfs,2);

if params.verbose
    fprintf('[%s]: Making model predictions for %d voxels/vertices \n',mfilename,nVoxels);
end
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
    if params.useGPU
        predNeuralComb = zeros(size(predNeural),'gpuArray');
    else
        predNeuralComb = zeros(size(predNeural));
    end
    % Then truncate the 3 dimension (with channels) to the number of unique
    % runs:
    predNeuralComb = predNeuralComb(:,:,1:length(uniqueRuns),:);
    for cb = 1:length(uniqueRuns)
        predNeuralComb(:,:,uniqueRuns(cb),:) = sum(predNeural(:,:,params.analysis.combineNeuralChan==uniqueRuns(cb),:),3, 'omitnan');
    end
    predNeural = predNeuralComb;
end

%% 7. Check if we want to normalize the max height of the neural channels
if params.analysis.normNeuralChan
    if  ndims(predNeural) == 4 && params.analysis.normAcrossRuns
        predNeural = concatRuns(predNeural);
    end
    for ii = 1:size(predNeural,3)
        predNeural(:,:,ii,:) = normMax(predNeural(:,:,ii,:));
    end
    if params.analysis.normAcrossRuns ==1
        predNeural = reshape(predNeural, ...
            [size(predNeural,1)/size(stim,3),size(stim,3), size(predNeural,2), size(predNeural,3)]);
        predNeural = permute(predNeural,[1 3 4 2]); 
    end
end

%% 8. Compute spatiotemporal BOLD response in TRs
% Define hrf
if ~isfield(params.analysis.hrf, 'func') || isempty(params.analysis.hrf.func)
    [hrf,params] = getHRF(params);
else
    hrf = params.analysis.hrf.func;
end
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
if params.verbose == 1 
    fprintf('[%s]: Finished! Time: %d min.\t(%s)\n', ...
        mfilename, round(toc/60), datestr(now));
end

return


