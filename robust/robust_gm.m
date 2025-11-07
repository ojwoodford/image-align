%ROBUST_GM

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function [s, W, W2] = robust_gm(s, width)
tau_sq = width * width;
r = 1.0 ./ (s + tau_sq);
a = tau_sq .* r;
s = s .* a;
W = a .* a;
if nargout < 3
    return;
end
W2 = -2 * (W .* r);
end