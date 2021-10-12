function predBOLD = getPredictedBOLDResponse(params, predNeural, hrf)
% Convolve neural prediction with hrf to get predicted BOLD response 
% for each voxel

for n = 1:size(predNeural,2)
    chanResponse = num2cell(predNeural{n},1)';
    
    cellhrf = repmat({hrf}, size(chanResponse,1), 1);
    predBOLD = cellfun(@(X, Y) convolve_vecs(X, Y, params.analysis.temporal.fs, 1 /params.analysis.temporal.tr), ...
            chanResponse, cellhrf, 'uni', false);
    predBOLD = cellfun(@transpose,predBOLD,'UniformOutput',false);
    predBOLD = cell2mat(predBOLD)';
    
end

return