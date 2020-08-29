%NCC_EXPERIMENT

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function out = ncc_experiment(params, data)
% Params:
% 1 - source image index
% 2 - target image index
% 3 - method
% 4 - experiment type (1: full region, 2: grid, 3: grid, robust, 
%                      4: sparse,  5: sparse, robust, 6: sparse, weighted, 7: sparse, weighted, robust, 
%                      8: DSO sparse layout, robust
% 5 - composition type
% 6 - occlude
% 7 - value (grid block length, or number of features (x0.1))

maxNumCompThreads(data.num_threads);
mean_distances = 0:10;

% Set the options
options.warp_type = 'homog';
options.prefilter = 'none';
options.normalize = 'ncc';
options.intensity_model = 'none';
options.optimizer_params = [100 1e-4 1e-6 3];
options.composition = params(5) - 2;
spacing = 1;
weights = @(varargin) [];
generative_params = [];
robustifier = @(r, varargin) robust_gm(r, 0.5);
if params(5) == 4
    % Use Scandaroli's ESM optimization
    options.composition = -0.5;
else
    options.composition = sign(params(5) - 2);
end
if isfield(data, 'edgelet_offsets')
    options.edgelet_offsets = data.edgelet_offsets;
end
options.max_num_threads = data.num_threads; % Use one thread for sampling
switch params(3)
    case 2
        % ZNSSD optimization
        options.normalize = 'znssd';
    case 3
        % ECC
        options.normalize = 'zeromean';
        options.cost_adjustment = @ecc_adjustment;
    case 4
        % Normalized image
        options.normalize = 'ssd';
        options.prefilter = 'locally_normalized';
    case 5
        % Descriptor field
        options.normalize = 'ssd';
        options.prefilter = 'descriptor_fields';
        robustifier = [];
    case 6
        % Census bit planes
        options.normalize = 'ssd';
        options.prefilter = 'census';
        robustifier = [];
    case 7
        % Standard SSD
        options.normalize = 'ssd';
        robustifier = [];
    case 8
        % Generative model
        options.normalize = 'ssd';
        options.intensity_model = 'gain_bias';
        generative_params = [0; 0];
        options.condition_linear_system = params(4) > 1; % Condition local normalization
    case 9
        % Use Irani's region weighting scheme
        robustifier = @irani_weighting;
    case 10
        % Use Scandaroli's region and pixel weighting scheme
        robustifier = @scandaroli_weighting;
    case 11
        % 1 sigma Gaussian blur
        f = gauss_mask(1, 0, -2:2);
        options.prefilter = @(im) imfiltsep(im, f, f);
    case 12
        % Use precomputed image gradients
        options.precompute_gradients = true;
    case 13
        % Weight the features by the normalization
        weights = @compute_normalization;
    otherwise
        % Standard NCC
end
if ismember(params(4), [3 5 6])
    % Add robustification
    options.robustifier = robustifier;
end
options = direct_options(options);

% Get the image data
src = data.ims{params(1)};
occlude = data.occlude{params(1)};
region = data.regions{params(1)};
feats_per_region = sort(data.feats_per_region{params(1)}(1:params(7)*10,:)); % Sort for better data coherency
features = data.features{params(1)};
rot = reshape(data.rot{params(1)}, 2, 1, []);
rot = [[-rot(2,1,:); rot(1,1,:)] rot];
tgt = data.ims{params(2)};
gtH = data.gtH(:,:,params(1),params(2));

% Prefilter the images
src = options.prefilter(src);
tgt = options.prefilter(tgt);
src_ = src;
options.prefilter = @(im) im;

N = size(region, 2);
D = numel(mean_distances);
H = zeros(3, 3, D, N);
times = zeros(D, N);
costs = cell(D, N);
for a = 1:N
    % Compute the feature locations
    if params(4) < 4
        % Dense
        x = region(1,a)+0.5:spacing:region(3,a);
        y = region(2,a)+0.5:spacing:region(4,a);
        X = flipud(ndgrid_cols(y, x));
        % Rearrange into NxN blocks
        gl = params(7);
        X = reshape(permute(reshape(X, 2, gl, numel(y)/gl, gl, numel(x)/gl), [1 2 4 3 5]), 2, gl*gl, []);
        if params(4) == 1
            X = X(:,:);
        end
    else
        % Sparse
        I = feats_per_region(:,a);
        X = reshape(features(:,I), 2, 1, []);
        if params(4) == 6
            % DSO pixel offsets (integer position, no rotation)
            X = floor(X) + [0.5 0.5 -0.5 -1.5 -0.5 0.5 1.5 2.5; 0.5 -1.5 -0.5 0.5 1.5 2.5 1.5 0.5];
        else
            X = X + tmult(rot(:,:,I), options.edgelet_offsets);
        end
    end
    
    if params(6)
        % Occlude an area of the src image
        src = src_;
        src(occlude(2,a):occlude(4,a),occlude(1,a):occlude(3,a),:) = rand([flipud(occlude(3:4,a)-occlude(1:2,a)+1)' size(src, 3)]) < 0.5;
    end
    
    % Set up the solver
    corners = reshape(region([1 2 1 4 3 4 3 2],a), 2, 4);
    %options.debug_points = corners(:,[1:4 1]);
    h = directAlign(src, X, weights(src, X), options);
    
    % For each distance
    for b = 1:D
        % Compute the initial homography
        initialH = gtH * compute_homography(corners, corners + data.offsets(:,:,a) * mean_distances(b));
        initialH = initialH ./ initialH(3,3);
        initialH = [initialH(:); col(repmat(generative_params, 1, size(X, 3)))];
        
        % Optimize
        t = tic();
        [initialH, costs{b,a}] = optimize(h, tgt, initialH);
        times(b,a) = toc(t);
        H(:,:,b,a) = reshape(initialH(1:9), 3, 3);
        costs{b,a} = costs{b,a} / size(X, 3);
    end
end
out.H = H;
out.times = times;
out.costs = costs;
end