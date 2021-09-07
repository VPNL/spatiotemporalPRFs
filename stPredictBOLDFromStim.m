function predictions = stPredictBOLDFromStim(params)
%% INPUTS:
% params      : struct containing:
%               * params.saveDataFlag -- save predictions (true) or not (false)
%               * params.stim -- struct with stimulus variables
%                   - images_unconvolved (x,y,t)
%               * params.recomputePredictionsFlag -- recompute (false) or load
%                    from file (true), file name is defined in:
%               * params.analysis
%                   - fieldSize  -- stimulus Field of View (deg)
%                   - sampleRate -- nr of pixels from left to right 
%                   - predFile -- where to save or load predictedBOLD file (str)
%                   - temporalModel (string) Choose from:
%                      '1ch-glm','1ch-dcts','2ch-exp-sig'
%                   - spatial -- struct with pRF params: x0,y0,sigma,
%                       variance explained, exponent, etc.

%% 0. Get temporal parameters
% load temporal params,
params = getTemporalParams(params);

% TODO: params = getTemporalParams(params)

% Subfunction description: Take params and return back with the 5 t params,
% fs, numChannels, TR (seconds) as fields of params.analysis.temporal.[...] 

%% 1. Define hrf
hrf = canonical_hrf(1 / fs, [5 14 28]);

%% 2. Loop over stimulus files
for s = 1:length(params.stim)
    
    %% 2.1 Either load 
    if ~params.recomputePredictionsFlag
        fprintf('Loading saved predictions for %s model (stimulus = %d) \n', ...
            params.analysis.temporalModel, s); drawnow;
        
        [predPath,predFileName] = fileparts(params.analysis.predFile);
        fileToLoad = strcat(predFileName,'_r',num2str(s),'.mat');
           
        a = load(fullfile(predPath,fileToLoad));
        predictions(s).prediction = a.prediction; clear a;
    
    %% 2.2 ... or compute prediction
    else
         fprintf('Computing BOLD predictions for %s model (stimulus = %d) \n', ...
            params.analysis.temporalModel, s); drawnow;
        
        %% 3. Get stimulus
        % TODO: [stim, keep] = getStimulus(params); % see old code params.stim(s).images_unconvolved';
        [stim,keep] = getSTStimulus(params,stimulusNumber);
        
        % Subfunction description: load stimulus images later used by
        % st_tModel.m, and define pixels that have a stimulus to save computational resources
        % see old code: keep = params.stim.instimwindow;
        
        %% Setting up loop over voxels
        nVoxels = numel(params.analysis.x0);
        fprintf('[%s]:Making %d model samples:',mfilename,nVoxels);
        fprintf('Generating irf for %s model...\n', params.temporal.model)
        
        % Loop over grid
        tic
        for n=1:nVoxels
            % Print how far we are
            if mod(nVoxels,ceil(numel(params.analysis.x0)/10)) == 0
                fprintf('[%s]: Finished %d/%d) \n',mfilename,nVoxels,numel(params.analysis.x0));
            end
            
            %% 5. Get RF
            % Requires: 
            % * params.analysis.fieldSize
            % * params.analysis.sampleRate
            % * params.analysis.spatial.x, y, sigmaMajor, sigmaMinor, theta
            [prfs, params] = getPRF(params); % rf is x-pixels by y-pixels (in deg)

            %% 6. Compute RF X Stim
            % TODO: rfResponse = getPRFResponse(stim, prf);
            
            % Subfunction description: get time course for given pRF and
            % stimulus
            % see old code: full(stim*sparse(rf));
          
            %% 7. Compute spatiotemporal response in milliseconds
            % TODO: predNeural(n,time,space) = getPredictedNeuralResponse(params, rfResponse)
            
            % Subfunction description: get predicted neural response given
            % spatial pRF response and choice of temporal model
            
            % Within this function we need to get dt, t, call st_tModel,
            % see old code:
%             dt = 1/params.temporal.fs;
%             t = dt : dt : size(rfResponse,1)/params.temporal.fs;
            % predNeural = time (ms) x space (xy collapsed)
%             predNeural = st_tModel(params.temporal.model,params.temporal, rfResponse', t);
%             
%           And we need to set height to one!
              % Define norm max function
              % normMax = @(x) x./max(x);
              
            % And for simseq experiment, check if we need to add zeros,
            % such that predNeural length are in integers of TRs
%             if mod(size(predNeural{1},1),params.temporal.fs)
%                 addZeros = zeros(params.temporal.fs-mod(size(predNeural{1},1),params.temporal.fs), size(predNeural{1},2));
%                 predNeural{1} = cat(1,predNeural{1}, addZeros);
%                 if length(predNeural)>1
%                     predNeural{2} = cat(1,predNeural{2}, addZeros);
%                 end
%             end
              
            %% 8. Compute spatiotemporal BOLD response in TRs
            % TODO: predBOLD(n,channels,time) = getPredictedBOLDResponse(params, predNeural(n,:,:), hrf)

             % Subfunction description: Convolve neural prediction with hrf
             % to get predicted BOLD response for voxel
             
            % see old code:
%             predBOLD = cellfun(@(X, Y) convolve_vecs(X, Y, params.temporal.fs, 1 /params.temporal.tr), ...
%                 rsp, repmat({hrf}, size(predNeural)), 'uni', false);
%             predBOLD = cell2mat(predBOLD);
            

        end
        
        %% 9. Store predictions in struct
        predictions(s).predBOLD = predBOLD; clear predBOLD
        predictions(s).predNeural = predNeural; clear predNeural

        fprintf('[%s]: Finished simulus = %d. Time: %d min.\t(%s)\n', ...
            mfilename, s, round(toc/60), datestr(now));
            drawnow;       
    end
end

%% 10. Save predictions if requested
if params.saveDataFlag
    fprintf('[%s]: Saving data.. \n', mfilename)
    save(params.analysis.predFile, 'predictions','-v7.3')
    fprintf('[%s]: Done!\n', mfilename) 
end

end


