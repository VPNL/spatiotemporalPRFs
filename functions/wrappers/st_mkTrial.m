function [trial,nStim] = st_mkTrial(stimprm,fs)
% 
% function [stimulus, time] = st_fMRIStimulus(with0OrNot)

% INPUTS:
%   stimprm     : Stimulus struct [variations X prms]
%     - prms    : [on off trialDur framerate]
%           - on       : on duration (nFrame)
%           - off      : isi (unit: nFrame)
%           - trialDur : total trial duration (unit: second)
%           - framerate : refreshrate of trial (unit: Hz)
%   fs          : framerate of stimulus, unit: HZ
%
% OUTPUTS 
%   trial       : nTrial X time (ms)
%
% Written by IK 2021 @ VPNL Stanford U

%% Pre-defined variables
nStimulus = size(stimprm, 1);


%% Compute stimulus
trial = cell(nStimulus,1);

for istim = 1 : nStimulus
    prm = stimprm(istim,:);
    
    trial_dur = prm(3);
    stim_on = prm(1)/ prm(4);
    stim_off = prm(2)/ prm(4);
    stim_num =  trial_dur / ( stim_on +  stim_off);
    hz =  stim_num/ trial_dur;
    
    
    t = 0:1/fs:trial_dur; % time vector
    w =  stim_on;
    d = w/2:1/ hz:trial_dur ;% Delay starts at t = 0 and
    each_stim = pulstran(t,d,'rectpuls',w);
    each_stim = each_stim(1:end-1); % cut off the last bit
    
    if  hz == inf
        each_stim = ones(size(each_stim));
    end
    
    trial{istim} = each_stim;
    nStim{istim} = stim_num;    
end


end