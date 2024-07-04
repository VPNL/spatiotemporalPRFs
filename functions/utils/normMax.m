function normedResponse = normMax(response)
% Function to set max height of response to 1
% 
% 	normedResponse = normMax(response). See also normSum.m
% 
% INPUT:
%   response        : (vector or matrix)  pRF time series (time points by pRFs) 
%
% OUTPUT:
%   normedResponse  : (vector or matrix)  normalized pRF time series (time points by pRFs)
%
% Written by ERK & ISK 2021 @ VPNL Stanford U
%
    normedResponse = response./max(response,[],'omitnan');
end