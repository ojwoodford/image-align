%ROBUST_HUBER

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function [s, W] = robust_huber(s, width)
tau_sq = width * width;
outliers = s > tau_sq;
sqrt_s = sqrt(s(outliers));
s(outliers) = 2.0 * width * sqrt_s - tau_sq;
sqrt_s = width ./ sqrt_s;
W = s;
W(outliers) = sqrt_s;
W(~outliers) = 1;
end

