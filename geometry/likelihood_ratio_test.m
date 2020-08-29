%LIKELIHOOD_RATIO_TEST Model scoring test
%
% The Likelihood Ratio Test for model scoring from Cohen & Zach's:
%  "The Likelihood-Ratio Test and Efficient Robust Estimation"
%
% [score, inliers] = likelihood_ratio_test(model_type, errors, search_area)
%
%IN:
%   model_type - 'rotation', 'homography', or 'essential'.
%   errors - 1d errors

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function [score, inliers] = likelihood_ratio_test(model_type, errors, search_area)

errors = abs(errors);
sigma = col(sort(errors));

switch model_type
    case {'rotation', 'homography'}
        inlier_area_ratio = sigma .* sigma * (2 * pi / search_area);
    case 'essential'
        inlier_area_ratio = sigma * (4 * sqrt(search_area / (2 * pi)) / search_area);
end

n = numel(errors);
inlier_ratio = col(1:n) / n;
M = inlier_ratio >= inlier_area_ratio; % Exclude cases beaten by the null hypothesis
M = M & (inlier_area_ratio > 1e-10); % Ignore points in the minimal set
inlier_ratio = inlier_ratio(M);
if isempty(inlier_ratio)
    score = 0;
    sigma = 0;
else
    inlier_area_ratio = inlier_area_ratio(M);
    score = inlier_ratio .* log(inlier_ratio ./ inlier_area_ratio) + (1 - inlier_ratio) .* log((1 - inlier_ratio) ./ (1 - inlier_area_ratio));
    [score, pos] = max(score);
    sigma = sigma(M);
    sigma = sigma(pos);
    score = score * 2 * n;
end

if nargout < 2
    return;
end
inliers = errors <= sigma;
end
