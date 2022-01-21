function [x,y,z]=sigma2searchgrid(sigma,params)
x = []; y = []; z = []; 
alpha = params.analysis.relativeGridStep;
sigma = sigma(:);
maxXY = params.analysis.maxXY;

% minimum step based on alpha and sigma:
step = min(sigma).*alpha;

% minimum step based on the stimulus sampling and stimulus size.
step = max(step, params.analysis.maxXY./2./params.analysis.maximumGridSampling);

% report result
fprintf(1,'[%s]:Minimimal pRF position spacing in triangular grid: %.2f deg.\n',...
    mfilename, step);


for n=1:numel(sigma),
    if params.analysis.scaleWithSigmas,
        % make sure we go through 0
        step = sigma(n).*alpha;

        % certain maximum of steps (minimum sampling)
        maxstepindeg = maxXY./2./params.analysis.minimumGridSampling;
        step=min(step,maxstepindeg);

        % certain max of steps too (minimumSampling)
        minstepindeg = maxXY./2./params.analysis.maximumGridSampling;
        step=max(step,minstepindeg);
    end
    
    % make grid
    switch lower(params.analysis.grid.type)
        case 'triangular'           % find triangular grid positions
            [tx,ty]=triangleGrid([-maxXY maxXY],step);
        case 'polar'                % find polar grid positions
            [tx,ty]=polarGrid([-maxXY maxXY],...
                params.analysis.grid.params(1),...
                params.analysis.grid.params(2));
        otherwise
            error('[%s]:Unknown grid type: %s',mfilename,...
                params.analysis.grid.type);
    end

    % grow grid
    x=[x;tx(:)]; %#ok<AGROW>
    y=[y;ty(:)]; %#ok<AGROW>
    z=[z;ones(size(ty(:))).*sigma(n)]; %#ok<AGROW>
end