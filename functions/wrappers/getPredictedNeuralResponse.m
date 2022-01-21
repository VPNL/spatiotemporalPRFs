function [predNeural, params] = getPredictedNeuralResponse(params, prfResponse)           
% Function to get predicted neural response (n,time,space) given
% spatial pRF response and choice of temporal model
%
%   predNeural = time (ms) x space (xy collapsed)
%
% INPUTS:
% params   :  (struct) should contain the following fields:
%              * temporal.fs (int): sample rate of prfFesponse (in ms)
%              * temporal.model (str): name of temporal model
%              * temporal.param (int/vector): parameter value
%              * temporal.fields (cell str): corresponding names of
%              temporal.param (should be in the same order)
%              * temporal.zeroPadPredNeuralFlag (bool): pad predicted
%                neural response with zeros to a full TR.

% Derive temporal sample rate and time axis
dt = 1/params.analysis.temporal.fs;
t  = dt : dt : size(prfResponse,1)/params.analysis.temporal.fs;

% Get the temporal response
predNeural = st_tModel(params.analysis.temporal.model, params.analysis.temporal.param, prfResponse, t);

% And for simseq experiment, check if we need to add zeros,
% such that predNeural length are in integers of TRs
if params.analysis.zeroPadPredNeuralFlag    
    if mod(size(predNeural{1},1),params.analysis.temporal.fs)
        padZeros = zeros(params.analysis.temporal.fs-mod(size(predNeural{1},1),params.analysis.temporal.fs), size(predNeural{1},2));
        predNeural{1} = cat(1,predNeural{1}, padZeros);
        if length(predNeural)>1
            predNeural{2} = cat(1,predNeural{2}, padZeros);
        end
    end
end