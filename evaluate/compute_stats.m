%COMPUTE_STATS

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function stats = compute_stats(result, M, method, sigma, ind)
if nargin > 4
    % Given indices to results to concatenate
    ind = ind(:,:);
    stats = compute_stats(result{ind(1),ind(2),ind(3),ind(4),ind(5)}, M, method, sigma);
    for a = 2:size(ind, 2)
        stats = merge_stats(stats, compute_stats(result{ind(1,a),ind(2,a),ind(3,a),ind(4,a),ind(5,a)}, M, method, sigma));
    end
    return;
end
if numel(sigma) > 1
    % Given sigma results to concatenate
    stats = compute_stats(result, M, method, sigma(1));
    for a = 2:numel(sigma)
        stats = merge_stats(stats, compute_stats(result, M, method, sigma(a)));
    end
    return;
end
if nargin < 4
    sigma = 1;
    if nargin < 3
        method = 'hard';
    end
end
result = permute(result, [1 2 3 6 4 5]);
result = reshape(result(:,:,:,:,M), size(result, 1), size(result, 2), []);
W = result(1:4,:,:);
stats.err = shiftdim(max(W), 1);
switch method
    case 'hard'
        W = W < sigma;
    case 'pdf'
        W = exp(-0.5 * (result(1:4,:,:) / sigma) .^ 2);
    case 'cdf'
        W = 1 - erf(result(1:4,:,:) / (sigma * sqrt(2)));
end
W = prod(W, 1);
N = sum(W, 3);
stats.converged = N' / size(W, 3);
N = 1 ./ N';
stats.time_to_converge = sum(result(5,:,:) .* W, 3)' .* N;
stats.iterations = sum(result(6,:,:) .* W, 3)' .* N;
stats.time_per_iteration = mean(result(5,:,:) ./ result(6,:,:), 3)';
end