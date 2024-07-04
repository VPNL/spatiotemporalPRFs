function stim = masktestStim(baseImg,seq,resampleSize)
% Function to make test stimulus for stRet
% 
%   stim = masktestStim(baseImg,seq,resampleSize)
%
% Example:
% userLoadFile = '/Users/insubkim/oak_home/spatiotemporal/experiments/stRet/data/subj01/session1/Stimuli/images_and_params_run01.mat';
% fs = 1000;
% resampleSize = 61;
% resampleSize = 101;
% userStim = baseImg;
% load(baseImgpath);
% load(userLoadFile)
%
% Written by IK 2021 @ VPNL Stanford U

% Set boolean for keeping all stimulus time points (instead of sparsify)
keepAllPoints = 1;

% resize image
nImages = size(baseImg, 3);
resampled = zeros(resampleSize,resampleSize, size(baseImg,3));
for ii = 1:nImages
    tmp = imresize(baseImg(:,:,ii), [resampleSize,resampleSize], 'nearest');
    resampled(:,:,ii) = tmp;
end

% populate temporal timecourse to the given images
% seq = userStim.sequence(:,10001:end);
% seq = userStim.sequence;

offMask = zeros([size(resampled,1) size(resampled,2)]);
images = zeros(size(resampled,1),size(resampled,2),length(seq),'logical');


for eachimage = 1:length(seq)
    if seq(eachimage) == 0
        images(:,:,eachimage) = offMask;
    elseif seq(eachimage) ~= 0
        images(:,:,eachimage) = resampled(:,:,seq(eachimage));
    end
end
% sz = size( images );
% images = reshape( images, [], sz(end) );        % # Collapse first two dimensions

% stimwindow = nansum(images,2);
% % needs to be changed later on
% if keepAllPoints
%     % mark all pixels as pixels to keep
%     stimwindow(:) = 1;
%     instimwindow = find(stimwindow==1);
% else
%     stimwindow = stimwindow > 0;
%     stimwindow = stimwindow(:);
%     instimwindow = find(stimwindow==1);
% end
% 
% keep = instimwindow;
% msStim   = sparse(msStim(keep,:));
% msStim   = (msStim(keep,:));
msStim = reshape(images, size(images,1)*size(images,2),[]);
stim = sparse(msStim);

end