%SCANDAROLI_WEIGHTING

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function [cost, W] = scandaroli_weighting(cost, err, varargin)
if nargin < 2
    return;
end
% Compute an *optimal* 2 cluster k-means split
sorted = sort(cost(:));
means = cumsum(sorted) ./ (1:numel(sorted))';
split = (means + flipud(cumsum(flipud(sorted)) ./ (1:numel(sorted))')) * 0.5;
[~, a] = min(abs(split - sorted));
% Compute the regional weight
[~, W] = robust_huber(col(max(cost - means(a), 0), 2), sqrt(split(a) - means(a))); % Guessing at the threshold
% Compute the pixelwise weight
[~, W2] = robust_huber(err .* err, median(col(abs(err)))); % Guessing at the threshold
W = W .* W2;
end