function st_prfResponse = getPRFStimResponse(stim, linearPRFFilters, params)
% Function to generate neural pRF time course for given pRF and stimulus.
%
% INPUTs:
% stim              : (double/logical matrix) stimulus xy (pixels) by time (ms)
% linearPRFFilters  : (double vector/matrix) linear prf filters, 
%                       in space: xy (pixels) by voxels
%                       in time: t (ms) by voxels
%                       in spacetime: xy (pixels) by t (ms) by voxels                    
% params            : (struct) params to check sparsifyFlag 

% OUTPUT:
% st_prfResponse  :  (double vector or matrix) spatiotemporal neural pRF 
%                       timecourse for stimulus. 
%                   Dimensions are time (ms) by number of pRFs by, 
%                   nr of cells are corresponding to nr of neural channels

%% First spatial
% Get predicted pRF time series: inner product between spatial rf and 3D stim
if params.analysis.spatial.sparsifyFlag
    s_prfResponse = full(stim'*sparse(linearPRFFilters.spatial.prfs));
else
    s_prfResponse = stim'*linearPRFFilters.spatial.prfs; % time x voxels
end

%% Then temporal
% Get predicted pRF time series: convolve spatial pRF response
% and temporal filter

st_prfResponse = {};
for n = 1:length(linearPRFFilters.names)
    st_prfResponse{n} = convCut2(s_prfResponse, linearPRFFilters.temporal{n}, size(s_prfResponse,1));
end

return
        
    