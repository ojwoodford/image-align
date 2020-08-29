%ROBUST_TRUNCATED

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function [s, W] = robust_truncated(s, width)
tau_sq = width * width;
W = ones(size(s));
W(s > tau_sq) = 0;
s = min(s, tau_sq);
end

