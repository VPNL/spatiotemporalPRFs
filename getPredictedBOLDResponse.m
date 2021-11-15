function predBOLD = getPredictedBOLDResponse(params, predNeural, hrf)
% Convolve neural prediction with hrf to get predicted BOLD response 
% for each voxel

for n = 1:size(predNeural,2)
    if size(predNeural{n},1) < size(predNeural{n},2)
        predNeural{n} = predNeural{n}';
    end
    chanResponse = num2cell(predNeural{n},1)';
    cellhrf = repmat({hrf}, size(chanResponse,1), 1);
    predBOLD1 = cellfun(@(X, Y) convolve_vecs(X, Y, params.analysis.temporal.fs, 1 /params.analysis.temporal.tr), ...
            chanResponse, cellhrf, 'uni', false);
    predBOLD2 = cellfun(@transpose,predBOLD1,'UniformOutput',false);
    predBOLD{n} = cell2mat(predBOLD2)';
    
end

return