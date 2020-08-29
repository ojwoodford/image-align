%EXTRACT_DENSE

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function X = extract_dense(im, block_len, corners)
% Extract a grid of points
border = block_len * 0.5; 
X = flipud(ndgrid_cols(border:size(im, 1)-border, border:size(im, 2)-border));
% Assume points are clockwise - select features within region
edges = normalize(corners - corners(:,[2:end 1]));
edges = [edges(2,:); -edges(1,:)];
edges(3,:) = -dot(edges, corners);
M = all(reshape(dot(reshape(homg(X), 3, 1, []), edges) > 0, 4, []));
% Compute the offset which generates the most features
ind = [1 block_len] * mod(X, block_len) + 1;
[~, m] = max(accumarray(ind(:), M(:)));
M = M & (m == ind);
% Get the blocks
offsets = 1:block_len;
offsets = offsets - mean(offsets);
[y, x] = ndgrid(offsets, offsets);
offsets = [x(:)'; y(:)'];
X = reshape(X(:,M), 2, 1, []) + offsets;
end