function [prfs, params] = getPRFs(params)
% Description: Function that takes spatial model as input to get either
% standard 2D Gaussian or CSS 2D Gaussian.
% INPUT:
% params  : (struct) Params struct should have the following fields:
%           * params.analysis.spatial.fieldSize  - (int) radius of FoV in deg, assuming square FoV
%           * params.analysis.spatial.sampleRate - (int) nr of grid points for entire FoV
%           * params.analysis.spatial.x0 - (int or vector) x-center position of pRFs (deg)
%           * params.analysis.spatial.y0 - (int or vector) y-center position of pRFs (deg)
%           * params.analysis.spatial.sigmaMajor - (int or vector) If linear or css pRF, 1
%                  std of circular 2D Gaussian. If elliptical pRF, 1 std for major axes (deg)
%           * params.analysis.spatial.sigmaMinor - (int or vector) If linear or css pRF, same
%                  as sigmaMajor. If elliptical pRF, sigma for minor axes (deg)
%           * params.analysis.spatial.theta - (int or vector) If linear or css pRF, theta
%                  can be empty or 0. If elliptical pRF, theta is angle (radians, 0=vertical)
%           * [params.analysis.spatial.X] - (matrix) X-axis of 2D support
%                  grid (deg), if not defined, we'll make it
%           * [params.analysis.spatial.Y] - (matrix) Y-axis of 2D support
%                  grid (deg), if not defined, we'll make it
%           * [params.analysis.spatial.pRFModelType] - (str) define if you want to use
%                  vistasoft's default 'unitHeight', or PRFModel
%                  'unitVolume' (default).
%           * [params.analysis.spatial.trimRFFlag] - (bool) if we want to
%                   truncate the RF at 5 SD or not, only for 'unitHeight' pRFs.
%           * [keepPixels] - (logical) matrix or vector with dimensions stim x by stim y.
%                   if a pixel is true, then it falls within our stimulus
%                   window and we keep it to generate pRF responses. If a
%                   pixel is false, it falls outside the stimulus window
%                   and we remove it to save computational resources.
%
% OUTPUT:
% prfs    : (double) matrix with [x-pixels by y-pixels (in deg)] by nr of
%               pRFs
% Written by ERK 2021 @ VPNL Stanford U

%% Check inputs

% Check if we request a particular pRF model
if ~isfield(params.analysis.spatial,'pRFModelType') || isempty(params.analysis.spatial.pRFModelType)
    params.analysis.spatial.pRFModelType = 'unitVolume';
end

% Get the support grid for the pRF:
if ~isfield(params.analysis.spatial,'X') || isempty(params.analysis.spatial.X)
    XYGrid = -params.analysis.spatial.fieldSize:params.analysis.spatial.sampleRate:params.analysis.spatial.fieldSize;
    [X,Y]  = meshgrid(XYGrid,XYGrid);
    
    % Store in params
    params.analysis.spatial.X = X;
    params.analysis.spatial.Y = Y;
    
    % Clear some memory
    clear XYGrid X Y
end

% Assume circular pRFs if no sigma minor is defined
if ~isfield(params.analysis.spatial,'sigmaMinor')
    params.analysis.spatial.sigmaMinor = params.analysis.spatial.sigmaMajor;
end

% Assume circular pRFs if no sigma minor is defined
if ~isfield(params.analysis.spatial,'theta')
    params.analysis.spatial.theta = zeros(size(params.analysis.spatial.sigmaMajor));
end

% Assume we want to trim edges of pRF
if ~isfield(params.analysis.spatial,'trimRFFlag')
    params.analysis.spatial.trimRFFlag = true;
end

%% Get num of voxels and loop over them to create pRFs
numVoxels = length(params.analysis.spatial.sigmaMajor);

switch params.analysis.spatial.pRFModelType
    case 'unitVolume'
        % This function normalizes the volume under the 2D gaussian and
        % truncates pRF at 5 SD. All pRFs will have a volume of 1 (or close
        % to 1)
        prfs = pmGaussian2d(...
            params.analysis.spatial.X, ...
            params.analysis.spatial.Y, ...
            params.analysis.spatial.sigmaMajor, ...
            params.analysis.spatial.sigmaMinor, ...
            params.analysis.spatial.theta, ...
            params.analysis.spatial.x0, ...
            params.analysis.spatial.y0);
        
    case 'unitHeight'
        % This function does NOT normalize the volume under the 2D gaussian
        % and does NOT truncate pRF at 5 SD. All pRFs will have a height
        % of 1.
        prfs = rfGaussian2d(...
            params.analysis.spatial.X, ...
            params.analysis.spatial.Y, ...
            params.analysis.spatial.sigmaMajor, ...
            params.analysis.spatial.sigmaMinor, ...
            params.analysis.spatial.theta, ...
            params.analysis.spatial.x0, ...
            params.analysis.spatial.y0);
        
        for n = 1:numVoxels
            if params.analysis.spatial.trimRFFlag
                % Mask RF at 5 sd to remove trailing edge
                SDcutoff = 5;
                % Define radius
                r = (params.analysis.spatial.sigmaMajor(n)*SDcutoff)./params.analysis.spatial.sampleRate;
                ctr = 1+(max(params.analysis.spatial.X(:))/params.analysis.spatial.sampleRate);
                center = ctr + [params.analysis.spatial.y0(n);params.analysis.spatial.x0(n)]./params.analysis.spatial.sampleRate;
                
                thisRF = reshape(prfs(:,n),[sqrt(size(prfs,1)),sqrt(size(prfs,1))]);
                mask = logical(makecircleimage(size(thisRF,1),r, [],[],[],[],center));
                prfs(:,n) = thisRF.*mask;
            end
        end
end

% If requested, remove no stim pixels
if ~isempty(params.analysis.spatial.keepPixels)
    prfs = prfs(keepPixels,:);
end

end
