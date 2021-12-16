function [lm, sumChannelPrediction] = ...
        fitModelPredictionToDataWrapper(data, predictions, alpha, regressionType)
%% Fit model prediction to data at single voxel level
% INPUTS
% data           : (double) matrix with fMRI data (time points x voxels)
% predictions    : (double) array with predicted BOLD data (time points x voxels x channels)
% regressionType : (str) use 'OLS' for ordinary least squares
%                       or 'fracridge' for fractional ridge regression
% alpha          : (double) can be an integer or a vector or empty. If
%                   defined, it will use that particular alpha, if empty,
%                   it will use a range of alphas.
%
%
% OUTPUTS
% lm                    : (struct) linear model fit with fields; beta, R2,
%                           alphas (hyperparameter for ridge regression), 
%                           bestAlpha (choosen by splithalf-crossvalidation 
%                           if wasn't defined), standard error, dof
%                           (degrees of freedom)
% sumChannelPrediction  : (double) matrix with scaled predictions (betas *
%                           design matrix)

numTimePoints = size(data,1);
numVoxels     = size(data,2);
numChannels   = size(predictions,3);

% Preallocate space
sumChannelPrediction = NaN(numTimePoints,numVoxels);
lm = [];

% Rename full predictions and dataset
X = predictions;
Y = data;

switch regressionType
    
    case 'OLS'
        
        % Loop over voxels
        for n = 1:numVoxels

            if ~any(isnan(X(:,n,:)))
                % Regress predictions using ordinary least-squares
                tmp = tch_glm(Y(:,n),squeeze(X(:,n,:)));
            end
            
            % Get scaled predictions
            sumChannelPrediction(:,n) = squeeze(X(:,n,:))*tmp.betas;
             
            % Compute Coefficient of Determination (R2), store R2 and beta
            tmp.R2  = computeCoD(Y(:,n),sumChannelPrediction(:,n));
            
            % Store in struct
            lm = [lm, tmp];
        end
        
      case 'fracridge'
        splits{1} = 1:ceil(numTimePoints/2);
        splits{2} = (ceil(numTimePoints/2)+1):numTimePoints;
        if ~exist('alpha','var') || isempty(alpha)
            alpha = logspace(-2,2,30);
        end
        
        % Preallocate space
        R2_alpha = NaN(2,numVoxels,length(alpha));
        splithalfModelPrediction = cell(1,2);

        for spl = 1:length(splits)
            Xtrain = X(splits{spl},:,:);
            Xtest  = X(splits{setdiff([1:length(splits)],spl)},:,:);
            Ytrain = Y(splits{spl},:);
            Ytest  = Y(splits{setdiff([1:length(splits)],spl)},:);

            for n = 1:size(Xtrain,2)
                % Regress predictions using fractional ridge regression
                lm = tch_glm_fracridge(Ytrain(:,n),squeeze(Xtrain(:,n,:)), alpha);
                lm.alphas = alpha;
                
                for aa = 1:length(lm.alphas)
                    % Get predicted response from model
                    splithalfModelPrediction{spl}(:,n,aa) = squeeze(Xtest(:,n,:))*lm.betas(:,aa);
                    
                    R2_alpha(spl,n,aa)  = computeCoD(Ytest(:,n),splithalfModelPrediction{spl}(:,n,aa));
                end
            end
        end
        
    % Pick alpha that gives on average the highest R across the two splithalfs    
    [~, idx] = max(mean([max(R2_alpha(1,:,:),[],2), max(R2_alpha(2,:,:),[],2)]));
    bestAlpha = lm.alphas(idx);
    clear lm
    lm = [];
    % Refit entire dataset with chosen alpha
    for n = 1:numVoxels
        tmp = tch_glm_fracridge(Y(:,n),squeeze(X(:,n,:)), bestAlpha);

        % Get predicted response from model
        sumChannelPrediction(:,n) = squeeze(X(:,n,:))*tmp.betas;

        % Compute Coefficient of Determination (R2), store R2 and beta
        tmp.R2 = computeCoD(Y(:,n),sumChannelPrediction(:,n));

        % Store in struct
        tmp.alphas    = alpha;
        tmp.bestAlpha = bestAlpha;
        lm = [lm, tmp];
    end
end

return






