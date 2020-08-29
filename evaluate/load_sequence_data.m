%LOAD_SEQUENCE_DATA

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function data = load_sequence_data(src_dir)
num_tests = 100; % Tests per image pair per distance
region_len = 49; % Pixel length of a region
num_feats_per_region = 100; % The number of features per region

% Load the images
temp_cd(src_dir);
names = dirim();
N = numel(names);
ims = cell(N, 1);
for a = 1:N
    % Load the gray image
    ims{a} = convert2gray(imread(names{a}));
end

% Try to load the data
version = 1;
seed = typecast(col(DataHash(ims{1}, 'array', 'uint8')), 'uint32');
seed = seed(1) + version; % Add the version number to the hash
try
    load data.mat;
    assert(data.seed == seed);
catch
    % Compute the ground truth homographies
    rng default
    [data.gtH, data.gtH_refined] = homography_align_images(ims);
    data.gtH = data.gtH ./ data.gtH(3,3,:,:);
    data.gtH_refined = data.gtH_refined ./ data.gtH_refined(3,3,:,:);
    
    % Set the initial corner offsets to have mean distance of 1 pixel
    rng(seed);
    data.offsets = randn(2, 4, num_tests);
    data.offsets = data.offsets ./ mean(normd(data.offsets, 1), 2);
    
    % Construct the set of image coordinates for each image
    coords = cell(N, 1);
    sizes = zeros(2, N);
    for a = 1:N
        sizes(:,a) = size(ims{a})';
        coords{a} = homg(flipud(ndgrid_cols(1:size(ims{a}, 1), 1:size(ims{a}, 2))));
    end
    
    % Compute initial homographies in source frame
    data.occlude = cell(N, 1);
    data.regions = cell(N, 1);
    data.features = cell(N, 1);
    data.rot = cell(N, 1);
    data.feats_per_region = cell(N, 1);
    for a = 1:N
        % Compute the image region seen in all other images
        mask = false(size(ims{a}));
        mask(6:end-5,6:end-5) = true; % Pad 5 pixels to give room for features
        for b = 1:N
            if a == b
                continue;
            end
            % From a to b
            X = proj(data.gtH_refined(:,:,a,b) * coords{a});
            mask = mask & reshape(all([X >= 1; X <= sizes(:,b)]), sizes(:,a)');
        end
        mask = ~imdilate_(~mask, ones(7));
        assert(any(mask(:)), 'Images have no common area');
        % Compute edgelets
        [data.features{a}, data.rot{a}, scores] = extract_edgelets(ims{a});
        % Retain edgelets in the region
        M = ojw_interp2(mask, data.features{a}(1,:), data.features{a}(2,:)) > 0.5;
        data.features{a} = data.features{a}(:,M);
        data.rot{a} = data.rot{a}(:,M);
        scores = scores(M);
        % Select regions to track
        data.regions{a} = select_regions(data.features{a}, size(ims{a}), region_len, num_tests, num_feats_per_region, mask);
        % For each region, select the best features in the region
        data.feats_per_region{a} = zeros(num_feats_per_region, num_tests, 'uint32');
        for b = 1:num_tests
            M = find(all([data.features{a} > data.regions{a}(1:2,b); data.features{a} < data.regions{a}(3:4,b)]));
            assert(numel(M) >= num_feats_per_region);
            order = compute_order(data.features{a}(:,M), log1p(scores(M)), num_feats_per_region);
            M_ = order ~= 0;
            data.feats_per_region{a}(order(M_),b) = uint32(M(M_));
        end
        % Compute the region to occlude - shift up/down & left/right by half a
        % window
        data.occlude{a} = data.regions{a} + repmat([mod(1:num_tests, 4) < 1.5; mod(1:num_tests, 2) == 1] * region_len - floor(region_len / 2), 2, 1);
        % Make sure occluded regions are in bounds
        data.occlude{a} = max(data.occlude{a}, 1);
        data.occlude{a}([1 3],:) = min(data.occlude{a}([1 3],:), sizes(2,a));
        data.occlude{a}([2 4],:) = min(data.occlude{a}([2 4],:), sizes(1,a));
    end
    
    % Save the sequence data
    data.region_len = region_len;
    data.seed = seed;
    save data.mat data;
end
data.rot = cellfun(@(c) c ./ max(abs(c)), data.rot, 'UniformOutput', false); % Scale so a distance of 1 pixel is at least 1 pixel distant in either x or y
data.ims = ims;
data.num_threads = num_cores();
end