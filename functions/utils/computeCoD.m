function CoD = computeCoD(data,prediction)
% Function to compute coefficient of determination (also known as variance
% explained or R^2).
% We define CoD as the RESIDUAL sum of squares / TOTAL sum of squares. 
%
% Compared to computing the ordinary R^2 (which does not care about 
% predicting the mean correctly):
%   defined as 1 - (var(data - prediction, 'omitnan') ./ var(data, 'omitnan')));
%
% INPUTS
%   data        : (vector or matrix) observed time series (time by voxels) 
%   prediction  : (vector or matrix) predicted time series (time by voxels)           
%
% OUTPUTS
%   CoD         : (double) coefficient of determination (R^2)
%
% Written by ERK & ISK 2021 @ VPNL Stanford U

% Using sum of squares residuals to compute R2
CoD = 1 - (  sum( (data - prediction).^2, 'omitnan') ...
            ./ sum( (data-nanmean(data)).^2, 'omitnan') );

end