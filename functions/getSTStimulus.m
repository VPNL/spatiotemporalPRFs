function [stim,keepPixels] = getSTStimulus(params,stimulusNumber)
%% Function to get spatiotemporal stimulus images and parameters
%
%   [stim,keepPixels] = getSTStimulus(params,stimulusNumber)
%
% Grabs stimulus and params for each stimulus file
%
% INPUT: 
% params.stim.images_unconvolved :   Aperture images [x,y,t]. Can be made
%                                    by mrVista rmMakeStimulus.m function
% [params.stim.instimwindow]     :   Pixels where stimulus was actually
%                                    presented. This window is used to 
%                                    save computational resources when 
%                                    generating predictions given the
%                                    stimulus.
% stimulusNumber                 :   index of the stimulus being used
%
% OUTPUT:
% stim: [Time(ms) X pixels]
% keep: [pixels]
%
% [ISK NOTE]: for more information check rmMakeStimulus.m get stimulus and
% keep values

stim = params.stim(stimulusNumber).images_unconvolved; % [EK]: why transpose if we can just input the correct dimension? 

if params.stim.sparsifyFlag
    keepPixels = params.stim.instimwindow;
else
    keepPixels = true(1,size(stim,1));
end

end