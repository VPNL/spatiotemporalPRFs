%% s_SimpleTutorial.m
% Simple tutorial to get predicted fMRI BOLD voxel responses for 
% compressive spatiotemporal pRFs using a sweeping bar stimulus.
% 
% The compressive spatiotemporal model is described by 
%   Kim, Kupers, Lerma-Usabiaga, & Grill-Spector (2024) J Neurosci. 
% 
% This tutorial creates two example pRFs:
% PRF 1: centered at [0,0] degrees of visual angle, size (1 std) = 1 deg
% PRF 2: centered at [1,2] degrees of visual angle, size (1 std) = 2 deg.
%
% Example stimulus is a 220-second run with a bar traversing across the
% screen in 4 directions (horizontally left to right, diagonally upper right 
% to lower left, vertically bottom to top, and diagonally lower right to 
% upper left). Bar position changes every 5 seconds. For each position, 
% bar content is updated with different temporal frequencies: 

%% Get example pRF parameters
cd(fullfile(stPRFsRootPath));

params = getExampleParams;
[f, params] = get3DSpatiotemporalpRFs(params);

% Define general parameters
params.analysis.predFile = fullfile(stPRFsRootPath,'example','modelpredictions.mat'); % file name with stored predictions
params.analysis.pRFmodel = {'st'}; % type of model, needed to make stimulus sequence.

%% Visualize first pRF in the visual field
nrPix = sqrt(size(f.spatial.prfs,1));

figure(1); clf;
subplot(221);
imagesc(reshape(f.spatial.prfs(:,1),nrPix,nrPix));
xlabel('X-pos (deg)'); ylabel('Y-pos (deg)');
set(gca,'XTick',[1 floor(nrPix/2) nrPix],'XTickLabel',[-12 0 12],...
    'YTick',[1 floor(nrPix/2) nrPix],'YTickLabel',[12 0 -12],...
    'FontSize',14,'TickDir','out')
title('PRF 1 - spatial component')
set(gca,'FontSize',12,'TickDir','out'); box off;

subplot(222);
imagesc(reshape(f.spatial.prfs(:,2),nrPix,nrPix));
xlabel('X-pos (deg)'); ylabel('Y-pos (deg)');
set(gca,'XTick',[1 floor(nrPix/2) nrPix],'XTickLabel',[-12 0 12],...
    'YTick',[1 floor(nrPix/2) nrPix],'YTickLabel',[12 0 -12],...
    'FontSize',14,'TickDir','out')
title('PRF 2 - spatial component')
set(gca,'FontSize',12,'TickDir','out'); box off;

h = subplot(2,2,[3 4]); cla; hold all;
plot(1:size(f.temporal,1),zeros(1,size(f.temporal,1)),'k-'); 
for cc = 1:size(f.temporal,2)
    plot(1:size(f.temporal(:,cc),1),f.temporal(:,cc),'lineWidth',2); 
end
legend(h.Children(length(h.Children)-1:-1:1), strrep(f.names,'_',' '))
xlabel('Time (ms)'); ylabel('Response amplitude (a.u.)')
title('pRF temporal impulse response functions')
set(gca,'FontSize',12,'TickDir','out'); box off;

%% Load example stimulus
runNr = 1;
params.stim(runNr).imFile          = fullfile(stPRFsRootPath,'example','example_stimulus.mat');
params.stim(runNr).paramsFile      = params.stim.imFile;
params.stim(runNr).prescanDuration = 0; % we don't consider additional blank time before the stimulus starts (seconds)
load(params.stim(runNr).imFile,'sequence','sec_sequence');

% Create 3D stim sequence
params = makeStiminMS(params,runNr);

% Stimulus is stored in sparse matrix to speed up computations, 
% let's convert to a full matrix to visualize stimulus
params.stim.images = full(params.stim.images);

% Derive stimulus parameters
nrPix = sqrt(size(params.stim.images,1)); % Note: Stimulus must have the same dimensions as pRF [X,Y]-support
t_s   = 1:(size(params.stim.images,2)/params.analysis.temporal.fs); 
t_ms  = (1:size(params.stim.images,2))/params.analysis.temporal.fs;

%% Visualize stimulus

% Stim is collapsed along x,y dimensions, so we reshape into x by y by time
stim3D = reshape(params.stim.images,[nrPix,nrPix,size(params.stim.images,2)]);

% Visualize a downsampled version of the unique stimulus frames used in this run
figure(2); stem(sec_sequence); 
xlabel('Time (s)')
ylabel('Image nr')
set(gca,'FontSize',14,'TickDir','out'); box off;
title('Stimulus temporal sequence (downsampled to 1 Hz)')

% Visualize binary images (again we only plot every 5th second, because the
% bar moves every 5 seconds).
figure(3); clf;
framesToPlot = 1:(5*params.analysis.temporal.fs):size(stim3D,3);
nrSubPlots = ceil(sqrt(length(framesToPlot)));
for t = 1:length(framesToPlot)
    subplot(nrSubPlots,nrSubPlots,t); hold all;
    imshow(stim3D(:,:,framesToPlot(t))); colormap gray;
    title(num2str(t))
end
sgtitle('Stimulus spatial locations (downsampled to 0.2 Hz)')

%% Get predictions
predictions = stPredictBOLDFromStim(params, params.stim.images);

%% Visualize predicted time series
predBOLD_weightedSum = (0.5*predictions.predBOLD(:,1,1,1) + 0.5*predictions.predBOLD(:,1,2,1));

figure(4); clf; hold all;
subplot(2,2,1); 
plot(t_ms, predictions.predNeural(:,1,1,1),'LineWidth',2); hold on;
plot(t_ms, predictions.predNeural(:,1,2,1),'LineWidth',2);
legend('Sustained','Transient')
xlabel('Time (s)');
ylabel('Neural response amplitude (a.u.)')
set(gca,'FontSize',14,'TickDir','out')
title('Predicted neural channel response - pRF 1')

subplot(2,2,2); 
plot(t_ms, predictions.predNeural(:,2,1,1),'LineWidth',2); hold on;
plot(t_ms, predictions.predNeural(:,2,2,1),'LineWidth',2);
legend('Sustained','Transient')
xlabel('Time (s)');
ylabel('Neural response amplitude (a.u.)')
set(gca,'FontSize',14,'TickDir','out')
title('Predicted neural channel response - pRF 2')

subplot(2,2,3); set(gca,'FontSize',14,'TickDir','out')
plot(t_s,predictions.predBOLD(:,1,1,1),'LineWidth',2); hold on;
plot(t_s,predictions.predBOLD(:,1,2,1),'LineWidth',2)
plot(t_s,predBOLD_weightedSum,'LineWidth',2)
legend('Sustained','Transient','Equally weighted sum')
xlabel('Time (s)')
ylabel('BOLD response (% signal change)')
set(gca,'FontSize',14,'TickDir','out')
title('Predicted BOLD response - pRF 1')

subplot(2,2,4); set(gca,'FontSize',14,'TickDir','out')
plot(t_s,predictions.predBOLD(:,2,1,1),'LineWidth',2); hold on;
plot(t_s,predictions.predBOLD(:,2,2,1),'LineWidth',2)
plot(t_s,predBOLD_weightedSum,'LineWidth',2)
legend('Sustained','Transient','Equally weighted sum')
xlabel('Time (s)')
ylabel('BOLD response (% signal change)')
set(gca,'FontSize',14,'TickDir','out')
title('Predicted BOLD response - pRF 2')

