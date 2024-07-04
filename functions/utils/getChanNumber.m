function nChan = getChanNumber(params)
% Function to get number of unique spatiotemporal channels (CST pRF model)
% 
%   nChan = getChanNumber(params)
% 
% INPUTS
%   params      : (struct) pRF parameter struct, requires the field:
%                   params.analysis.combineNeuralChan
%                   if set to [1 2 2], then the last two channels are
%                   considered the same
%
% OUTPUTS
%   nChan        : (double) number of channels  
%
% Written by ERK & ISK 2021 @ VPNL Stanford U

if isfield(params.analysis,'combineNeuralChan')
   nChan = length(unique(params.analysis.combineNeuralChan));
else
   nChan =  params.analysis.temporal.num_channels;
end

end