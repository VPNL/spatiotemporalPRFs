function predBOLD = getPredictedBOLDResponse(predNeural, hrf, params)
% % Functoin to convolve neural prediction with hrf to get predicted BOLD 
% response for each voxel
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
% 
for n = 1:size(predNeural,3) 
    predBOLD_tmp = convCut2(predNeural(:,:,n,:),hrf,size(predNeural,1));
    predBOLD(:,:,n,:) = downsample(predBOLD_tmp,  params.analysis.temporal.tr*params.analysis.temporal.fs);
end

return