function RF = stGaussian2dDoG(X,Y,sigmaMajor,sigmaSurround,theta, x0,y0)
% pmGaussian2d - Create a two dimensional Gaussian receptive field,
% this function is inherited from vistasoft/PRFmodel
%
%  RF = stGaussian2dDoG(X,Y,sigmaMajor,sigmaMinor,theta,x0,y0, sigmaSurround);
%
%    X,Y        : Sample positions in deg
%    sigmaMajor : standard deviation longest direction
%    sigmaSurround : standard deviation of surround (assuming same x,y center) 
%    theta      : angle of sigmaMajor (radians, 0=vertical)
%                 [default = 0];
%    x0         : x-coordinate of center of RF [default = 0];
%    y0         : y-coordinate of center of RF [default = 0];
%
% Example:
% To make one rf:
%    fieldRange = 20;  % Deg
%    sampleRate = 0.2; % Deg
%    x = [-fieldRange:sampleRate:fieldRange];
%    y = x;
%    [X,Y] = meshgrid(x,y);
%    sigma = 5;  % Deg
%    rf = pmGaussian2d(X,Y,sigma);
%
% fprintf('[%s]: Create pRFs.\n', mfilename)

if nargin ~= 7
    if ~exist('X', 'var') || isempty(X),
        error('Must define X grid');
    end
    
    if ~exist('Y', 'var') || isempty(Y),
        error('Must define Y grid');
    end
    
    if ~exist ('sigmaMajor', 'var') || isempty(sigmaMajor),
        error('Must scale on major axis');
    end
    
    if ~exist ('sigmaSurround', 'var') || isempty(sigmaSurround),
        error('Must scale on major surround axis');
    end

    if ~exist ('theta', 'var') || isempty(theta), theta = false; end
    if ~exist ('x0', 'var') || isempty(x0),       x0 = 0;    end
    if ~exist ('y0', 'var') || isempty(y0),       y0 = 0;    end
end


% Allow sigma, x,y to be a matrix so that the final output will be
% size(X,1) by size(x0,2). This way we can make many RFs at the same time.
% Here I assume that all parameters are given.
if numel(sigmaMajor)~=1
    sz1 = numel(X);
    sz2 = numel(sigmaMajor);
    
    X   = repmat(X(:),1,sz2);
    Y   = repmat(Y(:),1,sz2);
    
    sigmaMajor = repmat(sigmaMajor(:)',sz1,1);
    sigmaSurround = repmat(sigmaSurround(:)',sz1,1);
    
    if any(theta(:))
        theta = repmat(theta(:)',sz1,1);
    end
    
    x0 = repmat(x0(:)',sz1,1);
    y0 = repmat(y0(:)',sz1,1);
end

% Save the original sample positions
Xorig = X;
Yorig = Y;

% Translate grid so that center is at RF center
X = X - x0;   % positive x0 moves center right
Y = Y - y0;   % positive y0 moves center up

% Rotate grid around the RF center, positive theta rotates the
% grid to the right. No need for this if theta is 0.
if any(theta(:))
    Xold = X;
    Yold = Y;
    X = Xold .* cos(theta) - Yold .* sin(theta);
    Y = Xold .* sin(theta) + Yold .* cos(theta);
end

% Make gaussian on current grid
RFpos  = exp( -.5 * ((Y ./ sigmaMajor).^2 + (X ./ sigmaMajor).^2));
RFneg =  exp( -.5 * ((Y ./ sigmaSurround).^2 + (X ./ sigmaSurround).^2));   

% Normalize the Gaussian.
% GLU 2020-01-31
% The idea is that if you stimulate the entire RF you will
% always get the same activation, independent of the RF parameters.

%     % This will give a volume of 1, rergardless of sampling, for all cases
%     RF_unitVolume = RF(:,ii) ./ (sigmaMajor(ii) .* 2 .* pi .* sigmaMinor(ii));
RFpos_unitVolume = RFpos ./ (sigmaMajor .* 2 .* pi .* sigmaMajor);
RFneg_unitVolume = RFneg ./ (sigmaSurround .* 2 .* pi .* sigmaSurround);

% From now on, new (GLU 2020-01-31)
% We want the area to be 1.
% The idea is that if we multiply it with a full fov stimuli, the result will be
% one (and then using a normalized HRF, we can have meaningful BOLD values).

% Implementation:
% - Gaussians are infinite (they can go until machine precision)
% - Decide here to truncate until 5 SD values, so that 99.994% of values are inside
sigmaMajorLimit = 5;
% - Calculate, in the same sampled grid,
%   the values corresponding to 5 SD.
% ---- Calculate grid values
minVal = Yorig(1,1);
maxVal = Yorig(end,1);
sampleRate = Yorig(2,1) - Yorig(1,1);
fieldRange = maxVal - minVal + sampleRate;

clear RF X Y x0 y0

% RF_trimmed = zeros(size(RFpos_unitVolume),'single');
sigmaMajor = sigmaMajor(1,:);
sigmaSurround = sigmaSurround(1,:);

Yfull = reshape(Yorig(:,1),[sqrt(size(Yorig,1)),sqrt(size(Yorig,1))]);
clear Yorig Xorig
% fprintf('[%s]: Trim pRFs.', mfilename)
for ii = 1:size(RFpos_unitVolume,2)    
    RFpos(:,ii) = trimPRF(RFpos_unitVolume(:,ii), Yfull, fieldRange, sampleRate, ...
        sigmaMajorLimit, sigmaMajor(ii), sigmaMajor(ii));
    RFneg(:,ii) = trimPRF(RFneg_unitVolume(:,ii), Yfull, fieldRange, sampleRate, ...
        sigmaMajorLimit, sigmaSurround(ii), sigmaSurround(ii));
    if mod(ii,100)==0, fprintf('.'); end
end

RF = RFpos + (-1.*RFneg);
% fprintf('Done!\n', mfilename)

end



function RF = trimPRF(RF_orig, Yfull, fieldRange, sampleRate, sigmaMajorLimit, sigmaMajor, sigmaMinor)
    
    % --- Calculate how big the mesh needs to be for a full RF
    xlimit = single(sigmaMajorLimit * sigmaMajor);
    tmpx   = Yfull(:,1); clear Yfull;
    
    while xlimit > max(tmpx)
        % Grow it in 10% increments to avoid making the mesh too big
        fieldRange = 1.1*fieldRange;
        tmpx       = [-fieldRange:sampleRate:fieldRange];
    end
    
    % - Now that we know that the grid can hold the full RF
    %   Calculate the full RF and calculate the area underneath it
    tmpy = tmpx;
    [Xfull,Yfull] = meshgrid(tmpx, tmpy); clear tmpx tmpy;
    
    RFfull = exp( -.5 * ((Yfull ./ sigmaMajor).^2 + (Xfull ./ sigmaMinor).^2));
    
    RFfull = RFfull ./ (sigmaMajor .* 2 .* pi .* sigmaMinor);
    
    % - Calculate the full RF area
    sRFfull = sum(RFfull, 'all' ); clear RFfull;
    
    % - Normalize our RF with the full RF value we just obtained
    RF  = RF_orig./ sRFfull;
end