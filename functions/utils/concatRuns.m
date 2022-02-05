function output = concatRuns(input)

% input case 1) measurement * Voxel * channel * runs
% input case 2) measurement * Voxel * runs
% in either input cases, removes the last dimension (runs) and concats it
% to the measurement dimension
%% removes the last dimension and puts it back to 
if ndims(input) == 4
    ordered_input = permute(input, [1 4 2 3]);
    output = reshape(ordered_input,[], size(input,2),size(input,3));
elseif ndims(input) == 3
    ordered_input = permute(input, [1 3 2]);
    output = reshape(ordered_input,[], size(input,2));
end


%     output = reshape(input, ...
%         [size(input,1)*size(input,4), size(input,2), size(input,3)]);
end