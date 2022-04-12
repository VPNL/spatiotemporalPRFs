
function [lb,ub] = reSetBound(params,tmpP,mi)

input = tmpP(:,mi)';

% x,y,sigma
lb(1:3) =  input(1:3) - 3;
ub(1:3) =  input(1:3) + 3;

% lb(3) =  input(3) - 2;
% ub(3) =  input(3) + 2;

% set minumum ranges
lb(3) = max(lb(3),0.015); % min sigma size is 0.015

switch lower(params.analysis.temporalModel)
    case {'glm','1ch-glm'}
    case {'dn','1ch-dcts'}
    case {'3ch','3ch-stln'}
                        lb(4)   =  input(4) - 0.3;
                        ub(4)   =  input(4) + 0.3;
%         lb(4)   =  input(4) * 0.6;
%         ub(4)   =  input(4) * 1.4;
        
        
        %                 lb(5)   =  input(5) - 10;
        %                 ub(5)   =  input(5) + 10;
        lb(5)   =  input(5) * 0.6;
        ub(5)   =  input(5) * 1.4;
        
        lb(4) = max(lb(4),0.01); % min exponent size is 0.015
        ub(4) = min(ub(4),1);    % max exponent size is 1
        lb(5) = max(lb(5),4);     % min tau is 4
        ub(5) = min(ub(5),100);    % max tau is 100
        
        
end
end
