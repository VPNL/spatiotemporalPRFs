function params = setSeachParams(x,params)
% Function to set starting parameters for fine search fit optimization
% Note that we assume the same time constant for sustained and transient
% IRF channels of CST pRF model.
%
% INPUTS
%   x           : (vector) starting pRF parameter
%                   1. x0 (deg0
%                   2. y0 (deg)
%                   3. sigma (deg)
%                   4. CST exponent 
%                   5. CST sustained IRF channel time constant (ms)
%                   6. CST transient IRF channel time constant (ms) a
%   params      : (struct) pRF parameters, requires the following fields:
%                   params.analysis.temporalModel: 
%                   '1ch-glm','3ch-stLN','CST', '1ch-dcts','DN-ST'               
%
% OUTPUTS
%   params      : (struct) pRF parameters with set parameters 
%
% Written by ERK & ISK 2021 @ VPNL Stanford U

params.analysis.spatial.x0 = x(1);
params.analysis.spatial.y0 = x(2);
params.analysis.spatial.sigmaMajor = x(3);
params.analysis.spatial.sigmaMinor = x(3);

switch params.analysis.temporalModel
    case {'1ch-glm'} % None (LSS or CSS)
    case {'3ch-stLN','CST'}
        % 3 temporal params to solve:
        % 1) sustained delay 2) transient delay  3) exponent         
        params.analysis.temporal.param.exponent = x(4);
        params.analysis.temporal.param.tau_s    = x(5);
        params.analysis.temporal.param.tau_t    = x(5);
 
    case {'1ch-dcts','DN-ST'}
        % 4 temporal params to solve:
        %  ["tau1", weight, "tau2", "n", "delay/sigma"]
        %  [0.05      0       0.1    2     0.1  ]
        params.analysis.temporal.param.tau1   = x(4);
        params.analysis.temporal.param.weight = x(5);
        params.analysis.temporal.param.tau2   = x(6);
        params.analysis.temporal.param.n      = x(7);
        params.analysis.temporal.param.sigma  = x(8);
        
end  

end