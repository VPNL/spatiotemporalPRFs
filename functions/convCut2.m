function output = convCut2(stimulus, impulse, nTerms)
%   convCut2(stimulus, impulse, nTerms)
% 
% Function similar to convCut.m, but now for matrices
% INPUTS -----------------------------------------------------
% stimulus : a 2D flattened stimulus time course
% impulse  : an impulse response function
% nTerms   : number of terms after cutting
%
% OUTPUT(S) --------------------------------------------------
% output   : output cutted between 1 and nTerms

% % DEPENDENCIES ----------------------------------------------

%%

output = conv2(squeeze(stimulus), squeeze(impulse), 'full');

output = output(1:nTerms);


end