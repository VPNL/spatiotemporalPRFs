function output = convCut2(tc, impulse, nTerms)
%   convCut2(input, impulse, nTerms)
% 
% Function similar to convCut.m, but now for matrices
% INPUTS -----------------------------------------------------
% tc        : (double) a 2D flattened time course
% impulse   : an impulse response function
% nTerms    : number of terms after cutting
%
% OUTPUT(S) --------------------------------------------------
% output   : output cutted between 1 and nTerms

% % DEPENDENCIES ----------------------------------------------

%%
% output = conv2(squeeze(tc), squeeze(impulse), 'full');

output = convn(squeeze(tc), squeeze(impulse), 'full');

output = output(1:nTerms,:,:);


end