function nChan = getChanNumber(params)

if isfield(params.analysis,'combineNeuralChan')
   nChan = length(unique(params.analysis.combineNeuralChan));
else
   nChan =  params.analysis.temporal.num_channels;
end

end