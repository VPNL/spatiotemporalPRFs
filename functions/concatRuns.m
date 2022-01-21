function output = concatRuns(input)

ordered_input = permute(input, [1 4 2 3]);
output = reshape(ordered_input,[], size(input,2),size(input,3));  

%     output = reshape(input, ...
%         [size(input,1)*size(input,4), size(input,2), size(input,3)]);
end