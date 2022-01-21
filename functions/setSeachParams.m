function params = setSeachParams(x,params)


params.analysis.spatial.x0 = x(1);
params.analysis.spatial.y0 = x(2);
params.analysis.spatial.sigmaMajor = x(3);
params.analysis.spatial.sigmaMinor = x(3);

switch params.analysis.temporalModel
    case '1ch-glm'
    case '3ch-stLN'
        % 3 temporal params to solve:
        % 1) sustained delay 2) transient delay  3) exponent
%         params.analysis.temporal.param.exponent = x(4);
%         params.analysis.temporal.param.tau_s    = x(5);
%         params.analysis.temporal.param.tau_t    = x(6);
%         
        params.analysis.temporal.param.exponent = x(4);
        params.analysis.temporal.param.tau_s    = x(5);
        params.analysis.temporal.param.tau_t    = x(5);

% 
    case '1ch-dcts'
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