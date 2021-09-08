function prfResponse = getPRFStimResponse(stim, prf, params)
% Function to generate neural pRF time course for given pRF and stimulus

% Get predicted pRF time series: dot product between rf and 3D stim
if params.analysis.spatial.sparsifyFlag            
    prfResponse = full(sparse(prf)'*stim);
else
    prfResponse = prf'*stim;
end

% Exponentiate predicted pRF stimulus time series when CSS
if strcmp(params.analysis.spatialModel,'cssFit')
    prfResponse = bsxfun(@power, prfResponse, params.spatial.exponent);
end

if isfield(params.analysis.spatial,'normPRFStimPredFlag')
    if params.analysis.spatial.normPRFStimPredFlag
        for ii = 1:size(prfResponse,1)
            prfResponse(ii,:) = normMax(prfResponse(ii,:));
        end
    end
end
        
    