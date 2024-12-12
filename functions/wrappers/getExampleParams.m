function params = getExampleParams()
% Function to create example parameters to run spatiotemporal model
%
% INPUT:
%   None
%
% OUTPUT:
%   params    : (struct) struct with default, example pRF model parameters
%                 saveDataFlag: boolean (default = true), store data or not
%                 useGPU: boolean (default = false), convert "regular" arrays into GPU compatible ones.
%                         stim: [1×1 struct]
%                            * sparsifyFlag: (boolan, default = false) 
%                               Do you want to sparsify the stimulus? This will remove zeros from each 2D stimulus frame,
%                               Helpful to safe time/lower computational cost. 
%                            * framePeriod: (int, default = 1 second)
%                               TR in seconds 
%     recomputePredictionsFlag: (boolean, default = true)
%                               Handy if you want to store predicted pRF responses and avoid recomputing predictions. 
%                     analysis: [1×1 struct]
%                            * reluFlag: (boolean, default = true)
%                               Do you want to apply a linear rectifier?
%                            * normNeuralChan: (boolean, default = true)
%                               Do you want to normalize the height of the predicted neural response amplitude to 1, for each channel, 
%                               before convolving with the HRF? The neural response is the response after point-wise multiplying 
%                               stim and pRF.
%                            * normAcrossRuns: (boolean, default = true)
%                               Do you want to normalize the predicted BOLD response across several stimulus "runs"?
%                            * predFile: (str, default = 'tmp.mat')
%                               Name of stored prediction file.
%                            * spatialModel: (str/cell, default = 'onegaussianFit')
%                               Spatial pRF model to use. Choose from
%                               'onegaussianFit' or 'cssFit'.
%                            * temporalModel: '3ch-stLN'
%                            * hrf: [1×1 struct]
%                               * type: (str, default 'spm').
%                                 Define type of hemodynamic response function (HRF). Default is SPM12's two Gamma Canonical HRF.
%                            * zeroPadPredNeuralFlag: (boolean, default = true)
%                               Padding neural response with zeros to match the number of volumes in integers of TRs
%                            * spatial: [1×1 struct]
%                               * fieldSize: (double, default = 12). Size of visual field in degrees visual angle (dva).
%                               * sampleRate: 0.2400
%                                 spatial sample rate of modeled visual field (dva): the width/height of each pixel in the stimulus
%                               * pRFModelType: (str, default = 'unitVolume')
%                                 After we construct a 2D pRF, do we normalize the are under the pRF (unitVolume) or its height (unitHeight). 
%                               * keepPixels: (int, default = [])
%                                 option to select certain pixels in the stimulus, e.g., if you want to set a stimulus window.
%                               * X: (double, default = 101x101 rectified to 10201×1)
%                                 Stimulus support window in horizontal dimension (in dva)
%                               * Y: (double, default = 101x101 rectified to 10201×1)
%                                 Stimulus support window in vertical dimension (in dva)
%                               * x0: (double, default = [0 0])
%                                 X pRF centers in dva (1xN pRFs)
%                               * y0: (double, default = [0 0])
%                                 Y pRF centers in dva (1xN pRFs)
%                               * sigmaMajor: [1 2]
%                                 1 stdv of pRF gaussian size in dva (1xN pRFs)
%                            * temporal: [1×1 struct] temporal model parameters
%                                 * type of temporal model: (str, default = '3ch-stLN'). 
%                                 Choose from: linear ('1ch-glm'), delayed normalization model ('1ch-dcts'), 
%                                 compressive spatiotemporal model ('3ch-stLN'), exponential spatiotemporal model ('2ch-exp-sig')  
%                                 * fs: 1000 (sampling rate, Hz)
%                                 * param: [1×1 struct] 
%                             * combineNeuralChan: (int, default = [1 2 2])
%                                 * determine how to combine on-transient and
%                                 off-transient channels into a single
%                                 transient channel.
%               
% Written by ERK & ISK 2021 @ VPNL Stanford U

%% Initialize parameter struct to store default
params = struct();

% General params
params.saveDataFlag             = true;
params.recomputePredictionsFlag = true;
params.useGPU                   = false;

% Stim params
params.stim.sparsifyFlag        = false;
params.stim.framePeriod         = 1; % TR in seconds

% Analysis/model params
params.analysis.reluFlag        = true;
params.analysis.normNeuralChan  = true; % Normalize height of neural channels to 1
params.analysis.normAcrossRuns  = true; % Normalize across all runs, not within a single run
params.analysis.predFile        = 'tmp.mat';
params.analysis.spatialModel    = 'onegaussianFit';
params.analysis.temporalModel   = '3ch-stLN';
params.analysis.hrf.type        = 'spm'; % Two Gamma Canonical HRF
params.analysis.zeroPadPredNeuralFlag = true;

% Get default stock pRF params
optionNr = 1; % high spatial sampling rate
params = getSpatialParams(params,optionNr);
params = getTemporalParams(params);

% Update stimulus params
params.analysis.sampleRate  = params.analysis.spatial.sampleRate; % (degrees per point)
params.analysis.fieldSize   = params.analysis.spatial.fieldSize; % (degrees, radius)
params.analysis.numberStimulusGridPoints = params.analysis.fieldSize/params.analysis.sampleRate; % (n points, radius)
params.analysis.keepAllPoints = true;

% Add 2 circular 2D Gaussian pRFs:
% PRF 1: center [x,y]=[0,0] deg with sigma std = 1 deg.
% PRF 2: center [x,y]=[1,2] deg with sigma std = 2 deg.
params.analysis.spatial.x0 = [0 1];
params.analysis.spatial.y0 = [0 2];
params.analysis.spatial.sigmaMajor = [1 2];

return