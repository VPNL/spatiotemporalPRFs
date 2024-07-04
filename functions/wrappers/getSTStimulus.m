function [stim,keepPixels] = getSTStimulus(params,stimulusNumber,stimFile)
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
% stimFile                       :   if you specify the stimulus file, the
%                                    function computes ms Stim
%
% OUTPUT:
% stim: [Time(ms) X pixels]
% keep: [pixels]
%
% [ISK NOTE]: for more information check rmMakeStimulus.m get stimulus and
% keep values
%
% Written by ERK & IK 2021 @ VPNL Stanford U

if notDefined('stimFile')
    createFromStimFile = 0;
end


% get stimulus files
if isfile(stimFile)
    params.stim(stimulusNumber).imFile = stimFile;
    params.stim(stimulusNumber).paramsFile = stimFile;
    createFromStimFile = 1;

else
    error("no stim file found!")
end


if ~isfield(params.stim,'prescanDuration')
    params.stim(stimulusNumber).prescanDuration = 10;
    warning('setting prescanDuration to be %d secs  \n', ...
        params.stim(stimulusNumber).prescanDuration)
end 
        
if createFromStimFile
    % compute 
    params = makeStiminMS(params,stimulusNumber);
    params.stim(1).stimwindow = nansum(params.stim(1).images,2);
    
    if params.analysis.keepAllPoints
        % mark all pixels as pixels to keep
        params.stim(1).stimwindow(:) = 1;
        params.stim(1).instimwindow = find(params.stim(1).stimwindow==1);
    else
        params.stim(1).stimwindow = params.stim(1).stimwindow > 0;
        params.stim(1).stimwindow = params.stim(1).stimwindow(:);
        params.stim(1).instimwindow = find(params.stim(1).stimwindow==1);
    end
    
    keepPixels = params.stim(1).instimwindow;
    params.stim(stimulusNumber).images = params.stim(stimulusNumber).images(keepPixels,:);   
    params.stim(stimulusNumber).images_unconvolved = params.stim(stimulusNumber).images;
    stim = params.stim(stimulusNumber).images_unconvolved;
    
else
    
    stim = params.stim(stimulusNumber).images_unconvolved;
    if params.analysis.keepAllPoints
        keepPixels = true(1,size(stim,1));
    else
        keepPixels = params.stim.instimwindow;
    end

end
    




end