%SELECT_REGIONS

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function regions = select_regions(features, imsz, region_len, num_tests, min_num_features, mask)
% Compute an integral image of features per pixel
count = reshape(accumarray(col([imsz(1) 1] * ceil(features) - imsz(1)), 1, [imsz(1)*imsz(2) 1]), imsz);
count = cumsum(cumsum(uint64(count), 1), 2);
% Compute the regions to track
regions = [];
while size(regions, 2) < num_tests
    corners = floor(rand(2, 1e4) .* (fliplr(imsz)' - region_len));
    corners = reshape(repmat(corners, 4, 1) + [1 1 1 region_len([1 1 1 1]) 1]', 2, 4, 1e4);
    % Regions must have at least N features
    I = reshape([imsz(1) 1] * corners(:,:), 4, 1e4) - imsz(1);
    M = (count(I(1,:)) + count(I(3,:)) - count(I(2,:)) - count(I(4,:))) > min_num_features;
    % Regions must be within the shared area
    if nargin > 5
        M = M & all(ojw_interp2(mask, shiftdim(corners(1,:,:), 1), shiftdim(corners(2,:,:), 1)) > 0.5);
    end
    % Select the regions
    regions = [regions reshape(corners(:,[1 3],M), 4, [])];
end
regions = regions(:,1:num_tests);
end