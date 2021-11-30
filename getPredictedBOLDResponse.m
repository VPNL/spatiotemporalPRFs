function predBOLD = getPredictedBOLDResponse(params, predNeural, hrf)
% Convolve neural prediction with hrf to get predicted BOLD response 
% for each voxel

for n = 1:size(predNeural,2)
    chanResponse = predNeural{n};
    if size(chanResponse,1) < size(chanResponse,2)
        chanResponse = chanResponse';
    end
    cellhrf = repmat({hrf}, size(chanResponse,2),1);
    cellneural = num2cell(chanResponse,1)';
    predBOLD_tmp = cellfun(@(X, Y) convolve_vecs(X, Y, params.analysis.temporal.fs, 1 /params.analysis.temporal.tr), ...
            cellneural, cellhrf, 'uni', false);
    predBOLD_tmp = cellfun(@transpose,predBOLD_tmp,'UniformOutput',false);
    predBOLD{n} = cell2mat(predBOLD_tmp)';
end

return