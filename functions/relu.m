function output = relu(input, varargin)

% Check inputs
if isempty(varargin)
    slope = 1;
    thresh = 0;
elseif length(varargin)==1
    slope = varargin{1};
elseif length(varargin)==2
    slope = varargin{1};
    thresh = varargin{2};
end

if isempty(thresh) || ~exist('thresh','var')
    thresh = 0;
end 

% Preallocate space for output
output = zeros(size(input));

% Keep points above threshold
mask = input>thresh;
output(mask) = input(mask);
output = slope.*output;


return