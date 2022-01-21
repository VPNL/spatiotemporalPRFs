function [hrf,params] = getHRF(params)

% Description: Grabs HRF according to the optionNumber
% 1. SPM HRF
% 2. vistasoft HRF
% 
% INPUT:
% params  : (struct) Params struct should have the following fields:
%           * params.analysis.temporal.fs - temporal sampling rate
 %          * params.analysis.hrf = specify HRF type
% OUTPUT:
% hrf    : (double) 
%               
% Written by ISK 2021 @ VPNL Stanford U

if ~isfield(params.analysis,'hrf')
    params.analysis.hrf.type = 'spm';
end

switch params.analysis.hrf.type
    case {1,'spm'}
        hrf = canonical_hrf(1 / params.analysis.temporal.fs, [5 14 28]);
    case {2,'vista'}
        vistaParams     = [5.4 5.2 10.8 7.35 0.35];
        tSteps = 0:1/params.analysis.temporal.fs:28;
        values = rmHrfTwogammas(tSteps, vistaParams);
        hrf = values' / sum(values);
end


params.analysis.hrf.values = hrf;




end