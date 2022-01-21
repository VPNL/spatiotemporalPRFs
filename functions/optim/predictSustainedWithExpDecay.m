function [sustainedWithDecay,prfResponseSustained] = ...
    predictSustainedWithExpDecay(stimulus, nrfS, params)
% Function to code stimulus-specific exponential decay response. 
%
% INPUTS
%  stimulus     : stimulus time course (1x time frames (ms))
%  nrfS         : neural impulse response for sustained channel (in ms)
%  params       : temporal params with tau_ae (time constant for decay),
%                 temporal sampling rate of stimulus (in Hz) and weight
%                 (fraction) to scale final response, since we combine it
%                 with a transient channel response.
%
% OUTPUT
%  sustainedWithDecay : sustained response with exponential decay (1x time frames in ms)
%  prfResponseAdaptSustained : sustained response without exp decay *only
%                               convolved* (1xframes in ms)

% Get on/offsets of stimulus
if all(isnan(stimulus))
    sustainedWithDecay = NaN(size(stimulus));
    prfResponseSustained = NaN(size(stimulus));

else
    
    [onsets,offsets, ~] = st_codestim(stimulus');

    % Get adaptation exponent
    adaptationExp = exp(-(1:60000) / params.tau_ae);

    % Compute stage 1 of sustained response: full pRF response convolved with IRF
    prfResponseSustained = convCut(stimulus,nrfS, length(stimulus));

    % Preallocate space for decay function
    decayFun = zeros(1,size(prfResponseSustained,2));

    for ss = 1:length(onsets)

        start_idx = round(onsets(ss) * params.fs);
        stop_idx  = round(offsets(ss) * params.fs);
        if ss < length(onsets)
            start_next_idx = round(onsets(ss+1) * params.fs);
        else
            start_next_idx = size(stimulus,1);
        end

        % Define a separate time course for the single stimulus, we do this in
        % case ISIs are small and convolved responses are overlapping. 
        singleStimOnOff       = zeros(size(stimulus));
        if stop_idx == length(stimulus)
            stop_idx2 = stop_idx;
        else
            stop_idx2 = stop_idx+1;
        end
        singleStimOnOff(start_idx:stop_idx2) = stimulus(start_idx:(stop_idx+1));
        singleStimConvIRF(ss,:) = convCut(singleStimOnOff,nrfS,length(singleStimOnOff)); %#ok<AGROW>

        % Define decay time from stimulus onset until offset 
        idxDecayOnset = (start_idx+1):stop_idx;

        % If length of indices is larger than the exponential decay
        % function, then we just take the entire function.
        maxLength   = min([length(idxDecayOnset) length(adaptationExp)]);
        idxDecayOnset = idxDecayOnset(1:maxLength);

        % Keeping time points of decay function, that overlap with stimulus
        % being on the screen (or a non zero pRF response to stimulus).
        decayFun(idxDecayOnset) = adaptationExp(1:maxLength);

        % Define decay time from stop until next stimulus onset
        idxPostStim   = (stop_idx+1):(start_next_idx-1);

        % Then remove decay time between offset and onset of next stim
        decayFun(idxPostStim)   = zeros(1,length(idxPostStim));
    end

    % Pointwise multiply decayFun with sustained channel pRF response to get
    % a sustained response with exponential decay.
    sustainedWithDecay0 = prfResponseSustained .* repmat(decayFun, 1, size(prfResponseSustained, 1));

    % IF response is not zero before stimulus onset, it is likely to have some
    % left over convolved response from the previous stimulus display leaking
    % into the next response. Because we model the offset response with a
    % separate function (transient respnse), we assume that everything after 
    % stimulus offset is zero, until the next stimulus onset. If we don't do
    % that, stimuli with short ISIs (50ms or less) cause artifacts in our
    % sustained exponential decay response (i.e., a little saw tooth before
    % the next stimulus response rises).
    closeToZero = 10^-5;
    if any(sustainedWithDecay0(round(onsets*1000)+1)> closeToZero)
        stimIdx = find( sustainedWithDecay0(round(onsets*1000)+1) > closeToZero);
        sustainedWithDecay = sustainedWithDecay0;
        singleStimConvIRF(singleStimConvIRF==0)=NaN;

        for ii = stimIdx
            mask = singleStimConvIRF(ii,:);
            offIdx = 1+round(offsets(ii)*params.fs);
            mask(offIdx:end)=NaN;
            sustainedWithDecay(sustainedWithDecay>mask) = mask(sustainedWithDecay>mask);
        end
    else % just rename
        sustainedWithDecay = sustainedWithDecay0;
    end

    % Re-weight (since this response will be combined with a transient channel
    % response, one can decide to scale to put more/less weight on it).
    % Transient weight is 1-params.weight.
    sustainedWithDecay = params.weight * sustainedWithDecay;
end
return