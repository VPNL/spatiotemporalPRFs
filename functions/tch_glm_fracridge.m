function model = tch_glm_fracridge(Y, X, fracAlpha)
% Apply a general linear model (GLM) with fractional ridge regression 
% (minimizing the L2-norm) to data in Y using design matrix in X. This
% function requires the toolbox fracridge: 
% https://github.com/nrdg/fracridge.git
%
% INPUTS
%   Y: TR by voxel matrix of fMRI time series data
%   X: model design matrix
%   fracAlpha: fractions (between 0 and 1) to determine optimal alpha
%   (hyperparameter that penalizes large betas)
%
% OUTPUT FIELDS
%   betas: fitted linear model weights
%   residual: error of model prediction for each time point
%   stdevs: estimated standard deviation for each beta weight
%   dof: degrees of freedom of the fitting
%
% Adapted from tch_glm (cstmodel)


% check inputs
if nargin < 2
    error('not enough input arguments');
end

if exist('fracAlpha','var') && ~isempty(fracAlpha)
    mode = 1;
else
    fracAlpha = [0.2:0.05:1];
    mode = 0;
end

if size(X,1) ~= size(Y, 1)
    error('rows in data (Y) and design matrix (X) do not match');
else
    X = double(X);
    Y = double(Y);
end

if ~isempty(fracAlpha)

    % initialize model struct
    model = struct('design_mat', [],...
        'dof', [], ...
        'betas', [], ...
        'alphas', [], ...
        'offset', [], ...
        'residual', [], ...
        'var_covar', []);
    
    % compute degrees of freedom and store design matrix
    model.design_mat = X;
    model.dof = size(Y, 1) - rank(X);
    
    % get number of TRs, voxels, and predictors
    [num_trs, num_vox] = size(Y); num_preds = size(X, 2);
    
    % estimate beta weights for each predictor in the design matrix
    % fracridge(X,fracs,y,tol,mode, standardizemode)
    [betas,alphas,offset] = fracridge(X,fracAlpha,Y,[],mode);
    
    % Store betas, alphas and offsets
    model.betas  = betas;
    model.alphas = alphas;
    model.offset = offset;

    % compute residual error at each time point
    for bb = 1:size(betas,2)
        model.residual(:,bb) = Y - X * betas(:,bb);
        
        % compute residual variance and variance-covariance matrix
        model.resid_var(:,bb) = sum(model.residual(:,bb) .^ 2) / model.dof;
        vin = inv(X' * eye(num_trs) * X); model.var_covar = X' * X;
        
        % compute standard deviations and standard errors of betas
        stdevs = sqrt(diag(vin) .* diag(model.var_covar) * model.resid_var(:,bb));
        sems = stdevs ./ sqrt(repmat(round(sum(X))', [1 num_vox]));
        model.stdevs(:,bb) = reshape(stdevs, [1 num_preds num_vox]);
        model.sems(:,bb) = reshape(sems, [1 num_preds num_vox]); 
    end

end