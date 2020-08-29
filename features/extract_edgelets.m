%EXTRACT_EDGELETS

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function [X, dir, scores, middle] = extract_edgelets(im, thresh, radius, grad_method, M)
% Set defaults
if nargin < 5
    M = true(3, 3);
    if nargin < 4
        grad_method = 1;
        if nargin < 3
            radius = 1.5;
            if nargin < 2
                thresh = 1;
            end
        end
    end
end

% Get the gradients
[Ix, Iy] = imgrad(double(convert2gray(im)), grad_method);

% Compute 3 scores along the gradient
middle = sqrt(Ix .* Ix + Iy .* Iy) + 1e-100;
norm = 1 ./ middle(2:end-1,2:end-1);

Ix = Ix(2:end-1,2:end-1) .* norm;
Iy = Iy(2:end-1,2:end-1) .* norm;

[y, x] = ndgrid(2:size(middle, 1)-1, 2:size(middle, 2)-1);

first = ojw_interp2(middle, x+Ix, y+Iy);
last = ojw_interp2(middle, x-Ix, y-Iy);
middle = middle(2:end-1,2:end-1);
M = M(2:end-1,2:end-1);

% Find score maxima
if radius > 0
    M = M & (middle > first) & (middle > last) & (middle > thresh);
    M = imnonmaxsup(middle .* M, radius, 0);
end

% Extract and refine the maxima
[y, x] = find(M);
dir = [col(Ix(M), 2); col(Iy(M), 2)];
first = first(M);
scores = middle(M);
last = last(M);
X = (-0.5 * (last - first)) ./ (2 * scores - (first + last));
X = X .* ((scores > first) & (scores > last));
if strcmpi(grad_method, 'bilinear')
    offset = 0.5;
else
    offset = 1;
end
X = [x(:)'; y(:)'] + dir .* X(:)' + offset;
end