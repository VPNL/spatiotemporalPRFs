function [hrf,params] = getHRF(params)

% Description: Grabs HRF according to the optionNumber
% 1. SPM HRF
% 2. vistasoft HRF
% 
% INPUT:
% params  : (struct) Params struct should have the following fields:
%           * params.analysis.temporal.fs - temporal sampling rate
 %          * params.analysis.hrf = specify HRF type
% OUTPUT:
% hrf    : (double) 
%               
% Written by ISK 2021 @ VPNL Stanford U

if ~isfield(params.analysis,'hrf')
    params.analysis.hrf.type = 'spm';
end

switch params.analysis.hrf.type
    case {1,'spm'}
        hrf = canonical_hrf(1 / params.analysis.temporal.fs, [5 14 28]);
    case {2,'vista'}
        vistaParams     = [5.4 5.2 10.8 7.35 0.35];
        tSteps = 0:1/params.analysis.temporal.fs:20;
        values = rmHrfTwogammas(tSteps, vistaParams);
        hrf = values' / sum(values);
    case {3,'library1'}
        % kay's library
        file0 = strrep(which('getcanonicalhrflibrary'),'getcanonicalhrflibrary.m','getcanonicalhrflibrary.tsv');
        hrfs = load(file0)';  % 20 HRFs x 501 time points        
        trold = 0.1;
        tr = 1/params.analysis.temporal.fs;

        % resample to desired sampleing rate
        hrfs = interp1((0:size(hrfs,2)-1)*trold,hrfs',0:tr:(size(hrfs,2)-1)*trold,'pchip')';  % 20 HRFs x time
        hrfs = hrfs ./ sum(hrfs')';
%         hrfs = hrfs ./ repmat(max(hrfs,[],2),[1 size(hrfs,2)]);

        params.analysis.hrf.lib = hrfs;
        hrf  = hrfs(1,1:2001);
        
    case {4,'library2'}
        % vistasoft version
        file0 = './myHRFlib.mat';
        hrfs = load(file0)';  % 20 HRFs x 501 time points
        hrfs = hrfs.myHRFlib;
        
        trold = 0.1;
        tr = 1/params.analysis.temporal.fs;

        % resample to desired sampleing rate
        hrfs = interp1((0:size(hrfs,2)-1)*trold,hrfs',0:tr:(size(hrfs,2)-1)*trold,'pchip')';  % 20 HRFs x time
        hrfs = hrfs ./ sum(hrfs')';

        params.analysis.hrf.lib = hrfs;
        hrf  = hrfs(1,1:2001);
        
    case {5,'opt'}
        tmp = load('./fit_HRF.mat','estimatedParams');
        tmp = tmp.estimatedParams;
        
        tSteps = 0:1/params.analysis.temporal.fs:20;

        for i = 1:size(tmp,1)
            values = rmHrfTwogammas(tSteps, tmp(i,:));
            hrf(:,i) = values' / sum(values);
        end
        
        
end

params.analysis.hrf.func = hrf;

end