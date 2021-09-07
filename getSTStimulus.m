%% Get spatiotemporal Stimulus parameters (getSTStimulus)

% Grabs stimulus and  params for each model (params.analysis.temporalModel)

% input:
% params.stim.images_unconvolved: This is the output of the mrVista rmMakeStimulus.m function
% params.stim.instimwindow: Grab pixels where stimulus was actully presented
% this is to only compute pixels where the stimulus was presented (saves computational resources)
% stimulusNumber: index of the stimulus that is being grabbed

% Return values:
% stim: [Time(ms) X pixels]
% keep: [pixels]

% note: for more information check rmMakeStimulus.m

function [stim,keep] = getSTStimulus(params,stimulusNumber)

% get stimulus and keep values
stim = params.stim(stimulusNumber).images_unconvolved'; 
keep = params.stim.instimwindow;


end