%NCC_EXPERIMENT

% Copyright Oliver Woodford 2025

function out = robustifier_experiment(params, data)
% Params:
% 1 - source image index
% 2 - target image index
% 3 - second order robustification (1: no, 2: yes)
% 4 - robustifier type (1: Huber, 2: Geman McClure)
% 5 - composition type (1: Inverse, 2: ESM, 3: Forward)
% 6 - features (1: dense, 2: sparse)
% 7 - value (grid block length, or number of features (x0.1))
% 8 - condition linear system (1: no, 2: yes)

maxNumCompThreads(data.num_threads);
mean_distances = 0:10;

% Set the options
options.warp_type = 'homog';
options.normalize = 'ncc';
options.intensity_model = 'none';
options.optimizer_params = [100 1e-4 1e-6 3];
options.composition = params(5) - 2;
options.robust_2nd_deriv = params(3) == 2;
options.condition_linear_system = params(8) == 2;
switch params(4)
    case 1
        options.robustifier = @(r, varargin) robust_huber(r, 0.5);
    case 2
        options.robustifier = @(r, varargin) robust_gm(r, 0.5);
    otherwise
        error('Robustifier not recognized');
end
options.max_num_threads = data.num_threads; % Use one thread for sampling
options = direct_options(options);

% Get the image data
src = data.ims{params(1)};
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
options.prefilter = @(im) im;

N = size(region, 2);
D = numel(mean_distances);
H = zeros(3, 3, D, N);
times = zeros(D, N);
costs = cell(D, N);
for a = 1:N
    % Compute the feature locations
    if params(6) < 2
        % Dense
        x = region(1,a)+0.5:1:region(3,a);
        y = region(2,a)+0.5:1:region(4,a);
        X = flipud(ndgrid_cols(y, x));
        % Rearrange into NxN blocks
        gl = params(7);
        X = reshape(permute(reshape(X, 2, gl, numel(y)/gl, gl, numel(x)/gl), [1 2 4 3 5]), 2, gl*gl, []);
    else
        % Sparse
        I = feats_per_region(:,a);
        X = reshape(features(:,I), 2, 1, []);
        X = X + tmult(rot(:,:,I), options.edgelet_offsets);
    end
    
    % Set up the solver
    corners = reshape(region([1 2 1 4 3 4 3 2],a), 2, 4);
    %options.debug_points = corners(:,[1:4 1]);
    h = directAlign(src, X, [], options);
    
    % For each distance
    for b = 1:D
        % Compute the initial homography
        initialH = gtH * compute_homography(corners, corners + data.offsets(:,:,a) * mean_distances(b));
        initialH = col(initialH ./ initialH(3,3));
        
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