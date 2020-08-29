%EXTRACT_SPARSE

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function X = extract_sparse(im, offsets, corners, N)
% Extract the features
[X, rot, scores] = extract_edgelets(im);
% Assume points are clockwise - select features within region
edges = normalize(corners - corners(:,[2:end 1]));
edges = [edges(2,:); -edges(1,:)];
edges(3,:) = -dot(edges, corners);
M = all(reshape(dot(reshape(homg(X), 3, 1, []), edges) > 0, 4, []));
X = X(:,M);
rot = rot(:,M);
scores = scores(M);
% Remove the features which have samples out of bounds
rot = reshape(rot ./ max(abs(rot)), 2, 1, []);
rot = [[-rot(2,1,:); rot(1,1,:)] rot];
Y = reshape(X, 2, 1, []) + tmult(rot, offsets);
M = all(reshape((Y > 1) & (Y < [size(im, 2); size(im, 1)]), [], size(Y, 3)));
X = X(:,M);
Y = Y(:,:,M);
scores = scores(M);
% Select the best N features
M = compute_order(X, log1p(scores), N);
X = Y(:,:,M~=0);
end