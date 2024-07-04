function predBOLD = getPredictedBOLDResponse(predNeural, hrf, params)
% Function to convolve neural prediction with hrf to get predicted BOLD
% response for each voxel
% 
%   predBOLD = getPredictedBOLDResponse(predNeural, hrf, params)
%
% INPUTS
% predNeural        : (double) matrix or array with dimensions time by
%                       voxels [by channels]
% hrf               : (double) hemodynamic response function (time x 1),
%                       should be sampled at same rate as predNeural.
% params            : (struct) parameter struct should have at least the
%                       follow fields for this wrapper function:
%                       - params.analysis.temporal.fs: sample rate of
%                           neural response (hz)
%                       - params.analysis.temporal.tr: repetition time of
%                           BOLD response (s)
%                       - params.useGPU: If we use a GPU, then make it a
%                       GPU array
%
% Written by ERK & IK 2021 @ VPNL Stanford U

%% Preallocate space
predBOLD = zeros(size(predNeural,1)/(params.analysis.temporal.tr*params.analysis.temporal.fs), ...
    size(predNeural,2),size(predNeural,3),size(predNeural,4));

if params.useGPU
    predBOLD = gpuArray(predBOLD);
end

for n = 1:size(predNeural,3)
    predBOLD_tmp = convCutn(predNeural(:,:,n,:),hrf,size(predNeural,1));
    predBOLD(:,:,n,:) = downsample(predBOLD_tmp,  params.analysis.temporal.tr*params.analysis.temporal.fs);
end

return