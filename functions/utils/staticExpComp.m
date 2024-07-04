function Y = staticExpComp(X, n, verbose)
% Function to apply static nonlinearity (power-law) to pRF timeseries
% 
%   Y = staticExpComp(X, n, verbose)
% 
% INPUTS
%   X           : (vector) predicted time series (1 x time points)
%   n           : (scalar) power law exponent (n<1 implies comppression)
%   verbose     : print debug figure or not
%
% OUTPUTS
%   Y           : (double) output of compressed predicted time series  
%
% Written by ERK & ISK 2021 @ VPNL Stanford U

if nargin < 3
    verbose = false;
end

if  isempty(verbose)
    verbose = false; 
end

if ~isrow(n)
    n = n';
end

stNonlin = @(x,n) x.^n;
Y = stNonlin(X,n);

if verbose
    figure(101); clf; 
    x0 = [0:0.01:1];
    Y = bsxfun(@power,X,n(1));
    plot(x0, Y,'r', 'lineWidth',2);
    xlim([0 1]); ylim([0 1]);
    title('Static exponential nonlinearity')
end
end