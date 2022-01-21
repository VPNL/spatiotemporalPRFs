function CoD = computeCoD(data,prediction)
% Function to compute coefficient of determination (also known are R2)
% We define CoD as the RESIDUAL sum of squares / TOTAL sum of squares. 
%
% One could also use the ordinary R2 (which does not care about predicting
% the mean correctly):
%   defined as 1 - (var(data - prediction, 'omitnan') ./ var(data, 'omitnan')));

% Using sum of squares residuals to compute R2
CoD = 1 - (  sum( (data - prediction).^2, 'omitnan') ...
            ./ sum( (data-nanmean(data)).^2, 'omitnan') );

end