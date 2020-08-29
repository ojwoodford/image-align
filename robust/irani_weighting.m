%IRANI_WEIGHTING

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function [cost, W] = irani_weighting(cost, ~, J, H)
if nargin < 3 || isempty(J)
    return;
end
if isempty(H)
    H = tmult(J, J, [0 1]);
end
W = cost;
for a = 1:numel(W)
    W(a) = max(det(H(:,:,a)), 0);
end
end