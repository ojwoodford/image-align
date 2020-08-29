%IMPYRAMID  Creates an image pyramid from a given filter
%
%   B = impyramid(A, max_depths, filter)
%
% Generates the pyramid of an image of any class.
%
% IN:
%   A - MxNxC input image, or Sx1 cell array of input images.
%   max_depths - scalar indicating maximum number of additional pyramid
%                levels to calculate.
%   filter - Tx1 filter to apply to image in x and y directions before
%            downsampling. Default: [0 0.125 0.375 0.375 0.125].
%
% OUT:
%   B - 1xL (or SxL) cell array, where B{1} == A, and B{2},..,B{L} are the
%       subsampled pyramid levels.

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function B = impyramid(A, varargin)
% Multi-cell input
if iscell(A)
    B = reshape(A, numel(A), 1);
    B{1,max_depths+1} = [];
    for a = 1:numel(A)
        C = impyramid(A{a}, varargin{:});
        B(a,1:numel(C)) = C;
    end
    return
end

% Set the filter
if nargin > 2
    F = varargin{2};
else
    % Magic four tap integer filter
    F = [0 0.125 0.375 0.375 0.125];
end

% Calculate number of depths required
d = ceil(log2(min(size(A, 1), size(A, 2))));
if nargin > 1
    if varargin{1} < 0
        d = max(d + varargin{1}, 0);
    else
        d = min(d, varargin{1});
    end
else
    d = max(d - 5, 0);
end
d = d + 1;

% Initialize the first level
B = cell(1, d);
B{1} = A;

% Convert to double for higher accuracy (especially with logical arrays)
C = double(A);
F = double(F);

% Calculate other levels
for a = 2:d
    % Filter
    C = imfiltsep(C, F);
    
    % Subsample
    C = C(2:2:end,2:2:end,:);
    
    % Cast image
    if islogical(A)
        B{a} = C > 0.5;
    else
        B{a} = cast(C, 'like', A);
    end
end
end
