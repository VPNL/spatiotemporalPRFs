function params = getExampleParams()
% Function to create example parameters to run spatiotemporal model
%
% INPUT:
%   None
%
% OUTPUT:
%   params    : (struct) struct with default, example pRF model parameters
%               
% Written by ERK & ISK 2021 @ VPNL Stanford U
%

%%
params = struct();
params.saveDataFlag             = true;
params.stim.sparsifyFlag        = false;
params.stim.framePeriod         = 1; % TR in seconds
params.recomputePredictionsFlag = true;
params.analysis.reluFlag        = true;
params.analysis.normNeuralChan  = true; % Normalize height of neural channels to 1
params.analysis.normAcrossRuns  = true; % Normalize across all runs, not within a single run
params.analysis.predFile        = 'tmp.mat';
params.analysis.spatialModel    = 'onegaussianFit';
params.analysis.temporalModel   = '3ch-stLN';
params.analysis.hrf.type        = 'spm'; % Two Gamma Canonical HRF
params.analysis.zeroPadPredNeuralFlag = true;

optionNr = 1; % high spatial sampling rate
params = getSpatialParams(params,optionNr);
params = getTemporalParams(params);

% Add 2 pRFs with center at [0,0] and sigmas [1,2];
params.analysis.spatial.x0 = [0 0];
params.analysis.spatial.y0 = [0 0];
params.analysis.spatial.sigmaMajor = [1 2];