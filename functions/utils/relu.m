function output = relu(input, varargin)
% Function to apply linear rectifier, which removes negative numbers and
% can scale max height of response
% 
% 	output = relu(input, varargin)
% 
% INPUT:
%   input    : (vector or matrix)  pRF time series (time points by pRFs) 
%   [slope]  : slope of RELU function, if empty, default = 1;
%   [thresh] : threshold of RELU function, if empty, default = 0;
%   [useGPU] : boolean to define if we use GPU arrays or not, default = false
%
% OUTPUT:
%   output  : (vector or matrix)  rectified pRF time series (time points by pRFs)
%
% Written by ERK & ISK 2021 @ VPNL Stanford U

% Check inputs
if isempty(varargin)
    slope = 1;
    thresh = 0;
elseif length(varargin)==1
    slope = varargin{1};
elseif length(varargin)==2
    slope = varargin{1};
    thresh = varargin{2};
elseif length(varargin)==3
    slope = varargin{1};
    thresh = varargin{2};
    useGPU = varargin{3};

end

if  ~exist('thresh','var') || isempty(thresh)
    thresh = 0;
end 

if ~exist('useGPU','var') || isempty(useGPU) 
    useGPU = 0;
end 

% Preallocate space for output
if useGPU
    output = zeros(size(input),"gpuArray");
else
    output = zeros(size(input));
end

% Keep points above threshold
mask = bsxfun(@gt,input,thresh);

output(mask) = input(mask);
output = bsxfun(@times,slope,output);


return