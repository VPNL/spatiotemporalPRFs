function st_prfResponse = getPRFStimResponse(stim, linearPRFFilters, params)
% Function to generate neural pRF time course for given pRF and stimulus.
%
% INPUTs:
% stim              : (double/logical matrix) 
%                     stimulus xy (pixels) by time (ms) by run
% linearPRFFilters  : (double vector/matrix) linear prf filters, 
%                       in space: xy (pixels) by voxels
%                       in time: t (ms) by voxels
%                       in spacetime: xy (pixels) by t (ms) by voxels                    
% params            : (struct) params to check sparsifyFlag 

% OUTPUT:
% st_prfResponse  :  (double vector or matrix) spatiotemporal neural pRF 
%                       timecourse for stimulus. 
%                   Dimensions are time (ms) by number of pRFs by, 
%                   corresponding to nr of neural channels,
%                   by run
%
% Written by ERK & IK 2021 @ VPNL Stanford U

%% First spatial
% Get predicted pRF time series: inner product between spatial rf and 3D stim
if  params.useGPU
    s_prfResponse = pagefun(@mtimes, full(linearPRFFilters.spatial.prfs)',stim);
    s_prfResponse = permute(s_prfResponse,[2 1 3]); % time X voxel X run
else
    s_prfResponse =zeros(size(stim,2),size(linearPRFFilters.spatial.prfs,2),size(stim,3));
    for r = 1:size(stim,3)
        s_prfResponse(:,:,r) = full(sparse(stim(:,:,r))'* sparse(double(linearPRFFilters.spatial.prfs))); % time x voxels
    end
end

%% Then temporal
% Get predicted pRF time series: convolve spatial pRF response
% and temporal filter
st_prfResponse = zeros(size(s_prfResponse,1),size(s_prfResponse,2), ... time x voxels x channels x stim
    length(linearPRFFilters.names),size(s_prfResponse,3)); 
if  params.useGPU
    st_prfResponse = gpuArray(st_prfResponse);
end
% st_prfResponse => time X voxel X channel X run
if ndims(linearPRFFilters.temporal)==3 % If each voxel has it's own custom IRF, then we have to loop
    for n = 1:length(linearPRFFilters.names)
        for ii = 1:size(s_prfResponse,2)
            tIRF = linearPRFFilters.temporal(:,n,ii);
            tIRF = tIRF(~isnan(tIRF));
            st_prfResponse(:,ii,n,:) = convCutn(s_prfResponse(:,ii), tIRF, size(s_prfResponse,1));
        end
    end
else % If every voxel is subject to the same 3 IRF channels
    for n = 1:length(linearPRFFilters.names)
        st_prfResponse(:,:,n,:) = convCutn(s_prfResponse, linearPRFFilters.temporal(:,n), size(s_prfResponse,1));
    end
end
% subplot(131); plot((squeeze(st_prfResponse(:,1,1,1)))); hold on;
% subplot(132); plot((squeeze(st_prfResponse(:,1,1,2)))); hold on;
% subplot(133); plot((squeeze(st_prfResponse(:,1,1,3)))); hold on;

return

