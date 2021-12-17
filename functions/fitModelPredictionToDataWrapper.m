function [lm, sumChannelPrediction] = ...
        fitModelPredictionToDataWrapper(data, predictions, varargin)
%% Fit model prediction to data at single voxel level
% INPUTS 
% data                  : (double) matrix with fMRI data (time points x
%                           voxels) 
% predictions           : (double) array with predicted BOLD data (time
%                           points x voxels x channels)
% [alpha]               : (double) can be an integer or a vector or empty. 
%                           If defined, it will use that particular alpha, 
%                           if empty, it will use a default range of alphas
%                           logspace(-2,2,30).
% [regressionType]      : (str) use 'OLS' for ordinary least squares
%                           or 'fracridge' for fractional ridge regression
% [kFolds]              : (int) number of crossvalidated folds to determine 
%                           best alpha (i.e. the one giving the highest R2),
%                           when using ridge regression. Folds are within
%                           run in a single voxel (for now).
%
% OUTPUTS
% lm                    : (struct) linear model fit with fields; beta, R2,
%                           alphas (hyperparameter for ridge regression), 
%                           bestAlpha (choosen by splithalf-crossvalidation 
%                           if wasn't defined), standard error, dof
%                           (degrees of freedom)
% sumChannelPrediction  : (double) matrix with scaled predictions (betas *
%                           design matrix)
% 

%% Parse inputs
p = inputParser;
p.addRequired('data', @isnumeric);
p.addRequired('predictions',@isnumeric);
p.addParameter('alpha', logspace(-2,2,30), @isnumeric);
p.addParameter('regressionType','OLS', @(x) any(validatestring(x,{'OLS','fracridge'})));
p.addParameter('kFolds',10, @isnumeric);
p.parse(data,predictions,varargin{:});

% Rename variables
data            = p.Results.data;
predictions     = p.Results.predictions;
alpha           = p.Results.alpha;
regressionType  = p.Results.regressionType;
kFolds          = p.Results.kFolds;

% Derive dimensions of data and predictions
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
         % Fold data
         cv = cvpartition(numTimePoints,'kFold',kFolds);
         foldStart = 1+ (cumsum(cv.TestSize)-cv.TestSize(1));
         foldIndices = foldStart'+[0:(cv.TestSize-1)];
         order = Shuffle([1:length(foldStart)]);
         
         % Preallocate space
         R2_alpha = NaN(kFolds,numVoxels,length(alpha));
         splithalfModelPrediction = NaN(kFolds,numVoxels,length(alpha),size(foldIndices,2));

         for nc = 1:kFolds
             % Select test and train blocks
             testBlock     = order(nc);
             trainBlocks   = setdiff(order,testBlock);
             trainSet      = foldIndices(trainBlocks,:);
             testSet       = foldIndices(testBlock,:);
             Xtrain        = X(trainSet(:),:,:);
             Xtest         = X(testSet(:),:,:);
             Ytrain        = Y(trainSet(:),:);
             Ytest         = Y(testSet(:),:);
             
             for n = 1:size(Xtrain,2)
                 % Regress predictions using fractional ridge regression
                 lm = tch_glm_fracridge(Ytrain(:,n),squeeze(Xtrain(:,n,:)), alpha);
                 lm.alphas = alpha;
                 
                 for aa = 1:length(lm.alphas)
                     % Get predicted response from model
                     splithalfModelPrediction(nc,n,aa,:) = squeeze(Xtest(:,n,:))*lm.betas(:,aa);
                     % Compute R2 (coefficient of determination)
                     R2_alpha(nc,n,aa)  = computeCoD(Ytest(:,n),squeeze(splithalfModelPrediction(nc,n,aa,:)));
                 end
             end
        end
        
    % Pick alpha that gives the highest R averaged across folds  
    [~, idx] = max(max(mean(R2_alpha)));
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






