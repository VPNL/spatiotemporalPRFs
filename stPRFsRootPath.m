function rootPath = stPRFsRootPath()
%
% Return the path to root VPNL/spatiotemporalPRFs project folder
%
% This function must reside in the directory base of this code repository.
% It is used to determine the location of various subdirectories
%
% Example:
%   fullfile(stPRFsRootPath, 'functions')
%
% By Eline Kupers 2021 @ Stanford U


rootPath = which('stPRFsRootPath');
rootPath = fileparts(rootPath);

return

