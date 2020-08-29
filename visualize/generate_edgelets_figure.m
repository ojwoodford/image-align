%GENERATE_EDGELETS_FIGURE

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function generate_edgelets_figure(im, num_feats, region)
if nargin < 3 || numel(region) < 4
    if nargin > 2 && numel(region) == 2
        X = select_N_points(im, 1);
        region = round(X + (region(:) - 1) .* [-0.5 0.5]);
    else
        region = round(select_N_points(im, 2));
    end
    disp(region(:)');
end
% Image
imwrite(im(region(2):region(4),region(1):region(3),:), 'edge_crop.png');

% Edgelets
im = convert2gray(double(im));
M = false(size(im));
M(region(2):region(4),region(1):region(3)) = true;
[X, rot, scores, score_im] = extract_edgelets(im, 1, 1.5, 1, M);
M = compute_order(X, log1p(max(scores, 0)), num_feats) ~= 0;
X = reshape(X(:,M) - col(region(1:2)) + 1, 2, 1, []);
rot = rot(:,M);
rot = reshape(rot ./ max(abs(rot)), 2, 1, []);
rot = [[-rot(2,1,:); rot(1,1,:)] rot];
X = X + tmult(rot, [0 0  0  0.5 -0.5 -1   0   1    1    0   -1  -0.5  0.5   0   0  0; ...
                    6 4 2.5 1.5  1.5 0.5 0.5 0.5 -0.5 -0.5 -0.5 -1.5 -1.5 -2.5 -4 -6]);
X = permute([X NaN(2, 1, size(X, 3))], [2 3 1]);
clf reset;
imdisp(im(region(2):region(4),region(1):region(3)), [0 255]);
hold on
plot(col(X(:,:,1)), col(X(:,:,2)), 'g.');
X = X([1 3 4 8 9 13 14 16 14 12 11 6 6 3 17],:,:);
plot(col(X(:,:,1)), col(X(:,:,2)), 'g-');
export_fig edgelets.pdf

% Score image
score_im = sc(cat(3, log1p(max(score_im, 0)), im(2:end-1,2:end-1)), 'prob');
imwrite(score_im(region(2)+1:region(4)+1,region(1)+1:region(3)+1,:), 'edge_strength.png');
end
