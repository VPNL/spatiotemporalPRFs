function output = relu(input, slope, thresh)

% Check inputs
if isempty(slope) || ~exist('slope','var')
    slope = 1;
end

if isempty(thresh) || ~exist('thresh','var')
    thresh = 0;
end 

% Preallocate space for output
output = zeros(size(input));

% Keep points above threshold
for n = 1:size(input,2)
    currInput = input(:,n);
    output(currInput>thresh,n) = slope.*currInput(currInput>thresh);
end

return