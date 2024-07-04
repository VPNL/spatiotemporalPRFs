function output = convCutn(tc, impulse, nTerms)
% Function similar to convCut.m, but now for matrices
%   convCut2(input, impulse, nTerms)
% 
% INPUTS -----------------------------------------------------
% tc        : (double) a 2D flattened time course
% impulse   : an impulse response function
% nTerms    : number of terms after cutting
%
% OUTPUT(S)
% output    : output cutted between 1 and nTerms
%
% Written by AS?

%%
output = convn(squeeze(tc), squeeze(impulse), 'full');

output = output(1:nTerms,:,:);


end