function lm = ridgefitModelPredictionToData(data, predictions, alpha, ...
        regressionType, offsetFlag)
% Function toFit model prediction to data at single voxel level
%
%   lm = ridgefitModelPredictionToData(data, predictions, alpha, ...
%         regressionType, offsetFlag)
%
% INPUTS
% data           : (double) matrix (time points x voxels)
% predictions    : (double) array (time points x voxels x channels)
% regressionType : (str) use 'OLS' for ordinary least squares
%                       or 'fracridge' for fractional ridge regression
% alpha          : (double) can be an integer or a vector or empty. If
%                   defined, it will use that particular alpha, if empty,
%                   it will use a range of alphas.
% offsetFlag     : (bool) add column of ones as regressor 
%
%
% OUTPUTS
% lm             : (struct) linear model 
%
% Written by ERK & ISK 2021 @ VPNL Stanford U
%
%% Check inputs
numTimePoints = size(data,1);
numVoxels     = size(data,2);
numChannels   = size(predictions,3);

% Preallocate space
R2_full     = NaN(1,numVoxels);

if crossvalBetaFlag
    R2_crossval = NaN(1,numVoxels);
end

if offsetFlag
    B_full  = NaN(numVoxels,numChannels+1);
else
    B_full  = NaN(numVoxels,numChannels);
end

% Define normalization function of peak response height
normMax = @(x) x./max(x);

% Define data and prediction
X = predictions;
Y = data;

% Fit sum of equal weighted Sustained and Transient channel if requested
if sumSTFlag
    X = normMax(bsxfun(@(x) plus(x,2), X));
end

% Add offset if requested
if offsetFlag
    X = cat(3,X,ones(size(X,1),size(X,2),1));
end

%% Start fitting!
switch regressionType
    
    case 'OLS'
        
        % Loop over voxels
        for n = 1:size(X,2)

            if ~any(isnan(X(:,n,:)))
                % Regress predictions using ordinary least-squares
                lm = tch_glm(Y(:,n),squeeze(X(:,n,:)));
            end
            sumChannelPrediction(:,n) = squeeze(X(:,n,:))*lm.betas;

            % Generate also a response without offset
            if offsetFlag
                sumChannelPredictionNoOffset(:,n) = sumChannelPrediction(:,n) - lm.betas(end)*X(:,n,end);
            end
             
            % Compute Coefficient of Determination (R2), store R2 and beta
            R2_full(n)  = computeCoD(Y(:,n),sumChannelPrediction(:,n));
            B_full(n,:,:) = lm.betas';
        end
        
      case 'fracridge'
       
        splits{1} = 1:ceil(numTimePoints/2);
        splits{2} = (ceil(numTimePoints/2)+1):numTimePoints;
        if ~exist('alpha','var') || isempty(alpha)
            alpha = logspace(-2,2,30);
        end
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
    [val, idx] = max(mean([max(R2_alpha(1,:,:),[],2), max(R2_alpha(2,:,:),[],2)]));
    bestAlpha = lm.alphas(idx);
    clear lm
    
    % Refit entire dataset with chosen alpha
    for n = 1:size(X,2)
        lm = tch_glm_fracridge(Y(:,n),squeeze(X(:,n,:)), bestAlpha);

        % Get predicted response from model
        sumChannelPrediction = squeeze(X(:,n,:))*lm.betas;

        % Generate also a response without offset
        if offsetFlag
            sumChannelPredictionNoOffset(:,n) = sumChannelPrediction(:,n) - lm.betas(end)*X(:,n,end);
        end

        % Compute Coefficient of Determination (R2), store R2 and beta
        R2_full(n)  = computeCoD(Y,sumChannelPrediction(:,n));
        B_full(n,:) = lm.betas;
    end


end

return






