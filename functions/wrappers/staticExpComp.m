function Y = staticExpComp(X, n, verbose)

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