%MERGE_STATS

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function stats = merge_stats(stats, s)
ind = size(stats.converged, 2) + (1:size(s.converged, 2));
stats.converged(:,ind) = s.converged;
stats.iterations(:,ind) = s.iterations;
stats.time_per_iteration(:,ind) = s.time_per_iteration;
stats.time_to_converge(:,ind) = s.time_to_converge;
switch sign(size(stats.err, 2) - size(s.err, 2))
    case -1
        stats.err(:,end+1:size(s.err, 2),:) = NaN;
    case 1
        s.err(:,end+1:size(stats.err, 2),:) = NaN;
    otherwise
end
stats.err(:,:,ind) = s.err;
end
