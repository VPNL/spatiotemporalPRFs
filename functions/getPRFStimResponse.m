function prfResponse = getPRFStimResponse(stim, prf, params)
% Function to generate neural pRF time course for given pRF and stimulus.
%
% INPUTs:
% stim         : (double/logical matrix) stimulus xy (pixels) by time (ms)
% prf          : (double vector/matrix) pRFs xy (pixels) by voxels/vertices
% 
% OUTPUT:
% prfResponse  :  (double vector or matrix) neural pRF timecourse for
%                   stimulus. Dimensions are number of pRFs by time (ms)

% Get predicted pRF time series: dot product between rf and 3D stim
if params.analysis.spatial.sparsifyFlag            
    prfResponse = full(stim'*sparse(prf));
else
    prfResponse = stim'*prf;
end

% Exponentiate predicted pRF stimulus time series when CSS
if strcmp(params.analysis.spatialModel,'cssFit')
    prfResponse = bsxfun(@power, prfResponse, params.spatial.exponent);
end

if isfield(params.analysis.spatial,'normPRFStimPredFlag')
    if params.analysis.spatial.normPRFStimPredFlag
        for ii = 1:size(prfResponse,2)
            prfResponse(:,ii) = normMax(prfResponse(:,ii));
        end
    end
end
        
    