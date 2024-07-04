function normedResponse = normSum(response)
% Function to set sum of response to 1
% 
% 	normedResponse = normSum(response). See also normMax.m
% 
% INPUT:
%   response        : (vector or matrix)  pRF time series (time points by pRFs) 
%
% OUTPUT:
%   normedResponse  : (vector or matrix)  normalized pRF time series (time points by pRFs)
%
% Written by ERK & ISK 2021 @ VPNL Stanford U
%

normedResponse = bsxfun(@rdivide, response, sum(response,[],'omitnan'));

end