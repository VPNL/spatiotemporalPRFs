function st_prfResponse = getPRFStimResponse(stim, prf, params)
% Function to generate neural pRF time course for given pRF and stimulus.
%
% INPUTs:
% stim         : (double/logical matrix) stimulus xy (pixels) by time (ms)
% prf          : (double vector/matrix) pRFs xy (pixels) by voxels/vertices
% 
% OUTPUT:
% prfResponse  :  (double vector or matrix) neural pRF timecourse for
%                   stimulus. Dimensions are number of pRFs by time (ms)
%
%% First spatial
% Get predicted pRF time series: inner product between spatial rf and 3D stim
if params.analysis.spatial.sparsifyFlag
    s_prfResponse = full(stim'*sparse(prf.spatial.prfs));
else
    s_prfResponse = stim'*prf.spatial.prfs; % time x voxels
end

%% Then temporal
% Get predicted pRF time series: convolve spatial pRF response
% and temporal filter

st_prfResponse = [];
for n = 1:length(prf.names)
    tmp = conv2(prf.temporal{n},s_prfResponse, 'full');
    st_prfResponse{n} = tmp(1:size(s_prfResponse,1),:);
end

return
        
    