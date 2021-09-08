function predictions = stPredictBOLDFromStim(params)
% Wrapper function to predict BOLD time series (% change) from stimulus, 
% using a spatiotemporal pRF model
%
% INPUTS:
% params   : struct containing:
%            * params.saveDataFlag (bool): save predictions or not
%            * params.stim: struct with stimulus variables
%                - images_unconvolved (x,y,t)
%            * params.recomputePredictionsFlag: recompute (false) or
%              load from file (true), file name is defined in:
%              params.analysis.predFile
%            * params.analysis
%                - fieldSize (int): radius stimulus field of view (deg)
%                - sampleRate (int): nr of pixels from left to right
%                - predFile (str): where to save/load predictedBOLD file
%                - temporalModel (str): Choose from '1ch-glm','1ch-dcts',
%                '2ch-exp-sig' 
%                - spatial (struct): with pRF params x0, y0, sigma, 
%                varexplained, exponent, pRFModelType ('unitHeight' or
%                'unitVolume'), etc.
%
% OUTPUTS:
% predictions : struct containing:
%               * tktktktk
% 
%{ 
% Example:
params.saveDataFlag = true;
params.stim.images_unconvolved = ones(101*101,1000);
params.stim.sparsifyFlag = false;
params.recomputePredictionsFlag = true;
params.analysis.spatial.fieldSize = 12;
params.analysis.spatial.sampleRate = 12/50;
params.analysis.predFile = 'tmp.mat';
params.analysis.temporalModel = '1ch-glm';
params.analysis.spatialModel = 'onegaussianFit';
params.analysis.spatial.x0 = [0 0];
params.analysis.spatial.y0 = [0 0];
params.analysis.spatial.sigmaMajor = [1 2];
params.analysis.spatial.varexpl = [1 1];
params.analysis.spatial.sparsifyFlag = false;
params.analysis.spatial.normPRFStimPredFlag = true;
predictions = stPredictBOLDFromStim(params)
%}
%
%
% Written by IK and ERK 2021 @ VPNL Stanford U

%% 0. Get temporal parameters
% Take params and return back with the 5 t params, fs, numChannels, TR (s) 
% as fields of params.analysis.temporal.[...] 
params = getTemporalParams(params);

%% 1. Define hrf
hrf = canonical_hrf(1 / params.analysis.temporal.fs, [5 14 28]);

%% 2. Loop over stimulus files
predictions = struct();
for s = 1:length(params.stim)
    
    %% 2.1 Either load 
    if ~params.recomputePredictionsFlag
        fprintf('Loading saved predictions for %s model (stimulus = %d) \n', ...
            params.analysis.temporalModel, s); drawnow;
        
        [predPath,predFileName] = fileparts(params.analysis.predFile);
        fileToLoad = strcat(predFileName,'_r',num2str(s),'.mat');
           
        predictions(s).prediction = load(fullfile(predPath,fileToLoad));

    %% 2.2 ... or compute prediction
    else
         fprintf('Computing BOLD predictions for %s model (stimulus = %d) \n', ...
            params.analysis.temporalModel, s); drawnow;
        
        %% 3. Get stimulus
        % Load stimulus images later used by st_tModel.m, and define pixels
        % that fall within stimulus window (variable "keep") to save
        % computational resources
        [stim,keepPixels] = getSTStimulus(params, s);
        
        %% 5. Get pRFs
        % Take spatial model params as input to get either
        % standard 2D Gaussian or CSS 2D Gaussian. This requires:
        % * params.analysis.fieldSize
        % * params.analysis.sampleRate
        % * params.analysis.spatial.x0, y0, sigmaMajor, sigmaMinor, theta
        % prfs are [x-pixels by y-pixels (in deg)] by nrOfVoxels
        [prfs, params] = getPRFs(params, keepPixels);
        
        %% Setting up loop over voxels
        nVoxels = numel(params.analysis.spatial.x0);
        fprintf('[%s]: Making model samples for %d voxels/vertices:',mfilename,nVoxels);
        fprintf('[%s]: Generating irf for %s model...\n', mfilename, params.analysis.temporal.model)
        
        % Loop over grid
        tic
        for n=1:nVoxels
            % Print how far we are
            if mod(nVoxels,ceil(numel(params.analysis.spatial.x0)/10)) == 0
                fprintf('[%s]: Finished %d/%d voxels) \n',mfilename,nVoxels, ...
                    numel(params.analysis.spatial.x0));
            end
 
            %% 6. Compute RF X Stim
            % Get neural pRF time course for given pRF and stimulus
            prfResponse = getPRFStimResponse(stim, prfs, params);
          
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


