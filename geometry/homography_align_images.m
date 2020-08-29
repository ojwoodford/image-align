%HOMOGRAPHY_ALIGN_IMAGES

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function [H, Hrefined] = homography_align_images(ims)
sz = size(ims{1});
% Extract the SIFT features
N = numel(ims);
for a = N:-1:1
    ims{a} = convert2gray(ims{a});
    [feats{a}, desc{a}] = vl_sift(single(ims{a}));
    ims{a} = uint8(census_transform(convert2gray(ims{a})));
end

% Set the options for the photometric refinement
options = direct_options('normalize', 'ssd', 'prefilter', 'none', 'robustifier', [], 'composition', 0);
[Y, X] = ndgrid(20.5:size(ims{a}, 1)-20, 20.5:size(ims{a}, 2)-20);
% Cull to a multiple of the block size
block_size = 8;
after = mod(size(X), block_size) * 0.5;
before = floor(after);
after = ceil(after);
X = X(before(1)+1:end-after(1),before(2)+1:end-after(2));
X = reshape(permute(reshape(X, block_size, size(X, 1)/block_size, block_size, size(X, 2)/block_size), [1 3 2 4]), block_size*block_size, []);
Y = Y(before(1)+1:end-after(1),before(2)+1:end-after(2));
Y = reshape(permute(reshape(Y, block_size, size(Y, 1)/block_size, block_size, size(Y, 2)/block_size), [1 3 2 4]), block_size*block_size, []);
block_size = block_size * block_size;
X = [reshape(X, 1, block_size, []); reshape(Y, 1, block_size, [])];
X = reshape(X, 2, 1, []);
%options.debug_points = squeeze(mean(X, 2));

% For each pair:
H = repmat(eye(3), 1, 1, N, N);
Hrefined = repmat(eye(3), 1, 1, N, N);
rng default
for from = 1:N
    if nargout > 1
        % Construct the aligner for this image
        h = directAlign(ims{from}, X, [], options);
    end
    for to = 1:N
        if from == to
            continue;
        end
        % Match the descriptors
        matches = vl_ubcmatch(desc{from}, desc{to});
        % Do RANSAC to fit the homography
        [~, D] = msac_homography(feats{from}(1:2,matches(1,:)), feats{to}(1:2,matches(2,:)), 1);
        % Compute the the inliers
        [~, I] = likelihood_ratio_test('homography', D, sz(1)*sz(2));
        % Use DLT on the inliers to refine the estimate
        H(:,:,from,to) = compute_homography(feats{from}(1:2,matches(1,I)), feats{to}(1:2,matches(2,I)));
        if nargout > 1
            % Refine the homography photometrically
            Hrefined(:,:,from,to) = optimize(h, ims{to}, H(:,:,from,to));
        end
    end
end
end