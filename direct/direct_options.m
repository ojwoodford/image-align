%DIRECT_OPTIONS

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function options = direct_options(varargin)
% Set the options
options.optimizer_params = [100 1e-4 1e-6 3];
options.condition_linear_system = false;
options.warp_type = 8; % 8-parameter Homography
options.prefilter = 'gray';
options.normalize = 'ncc';
options.src_interp = 'linear'; % Interpolation scheme for the source image
options.tgt_interp = 'linear'; % Interpolation scheme for the target image
options.pretransform = []; % Should the patch coordinates be transformed
options.extract_features = 'dense'; % Features used by hierarchical alignment
options.edgelet_offsets = [0 0  0  0.5 -0.5 -1   0   1    1    0   -1  -0.5  0.5   0   0  0; ...
                           6 4 2.5 1.5  1.5 0.5 0.5 0.5 -0.5 -0.5 -0.5 -1.5 -1.5 -2.5 -4 -6]; % Default edgelet layout
options.left_update = false; % Should updates be applied to the left or right of the warp
options.intensity_model = 'none';
options.composition = 0; % Negative means inverse, positive means forwards, zero means ESM (hybrid)
options.robustifier = []; % No robustification
options.ideal2image = @(X) X; % Allows for post warp conversion from ideal to image coordinates
options.precompute_gradients = false; % Precompute image gradients
options.precondition = []; % Precondition the parameter space
options.cost_adjustment = []; % Use the standard least squares cost
options.oobv = -100; % The out of bounds value
options.debug_points = zeros(2, 0); % Points for debug visualization
options.grid_refine_iters = 0; % If doing grid search, refine this many iterations per element
options.grid_params = []; % MxN grid search parameters, where M is the warp dim, and N is the number of search locations
options.enlarge_region = 1; % Scale regions at different levels of hierarchical alignment
options.max_num_threads = num_cores(); % The maximum number of threads that image sampling can use
options.iteration_func = @(varargin) false; % Default output function for the optimizer
options.block_len = 6; % Length of square blocks used for extracting dense features
options.no_fast_ad = false; % Flag indicating if autodiff should be accelerated if possible

% Get the changed arguments
options = vgg_argparse(options, varargin);

% Set values given options
options.warp_size = [3 3];
options.lift_points = @(X) X; % Used to increase dimensionality of 2D points
options.tangent = @(warp) assert('Tangent not defined for this warp');
G = [0 0 0 1 1 0 0 0 1; 0 0 1 0 0 1 0 0 0; 0 0 0 0 0 0 1 0 0; ...
     0 0 -1 0 0 1 0 0 0; 0 0 0 1 -1 0 0 0 1; 0 0 0 0 0 0 0 1 0; ...
     1 0 0 0 0 0 0 0 0; 0 1 0 0 0 0 0 0 0; 0 0 0 -2 0 0 0 0 1]';
switch options.warp_type
    case {'trans', 2}
        options.ndims = 2;
        G = sparse(G([1:options.ndims end],:));
        options.update = @(v) reshape(homg(v)' * G, 3, 3);
    case {'trans-rot', 3}
        options.ndims = 3;
        G = sparse(G([1:options.ndims end],:));
        options.update = @(v) reshape(homg(v)' * G, 3, 3);
    case {'trans-rot-scale', 4}
        options.ndims = 4;
        G = sparse(G([1:options.ndims end],:));
        options.update = @(v) reshape(homg(v)' * G, 3, 3);
    case {'affine', 6}
        options.ndims = 6;
        G = sparse(G([1:options.ndims end],:));
        options.update = @(v) reshape(homg(v)' * G, 3, 3);
    case {'homog', 8}
        options.ndims = 8;
        G = sparse(G);
        options.update = @(v) reshape(homg(v)' * G, 3, 3);
    case {'quadric', 17}
        options.warp_size = [3 6];
        options.ndims = 17;
        options.update = @(v) [eye(3, 6); reshape(v(9:17), 3, 3) [1+v(4)+v(5) v(6)-v(3) v(1); v(6)+v(3) 1+v(4)-v(5) v(2); v(7) v(8) 1-2*v(4)]];
        options.lift_points = @(X) [X.*X; prod(X, 1); X];
    otherwise
        % Assume a lie group
        liegroup = lie(options.warp_type);
        options.ndims = ndims(liegroup);
        options.update = @(v) exp(liegroup, v);
        options.tangent = @(warp) log(liegroup, warp);
        options.warp_size = size(liegroup);
end
if ~isa(options.extract_features, 'function_handle')
    switch options.extract_features
        case 'dense'
            options.extract_features = @(im, edges) extract_dense(im, options.block_len, edges);
        case 'edgelets'
            options.extract_features = @(im, edges) extract_sparse(im, options.edgelet_offsets, edges, 300);
        otherwise
            assert(isnumeric(options.extract_features));
            options.extract_features = @(im, edges) extract_max(im, edges, options.extract_features, options.block_len, options.edgelet_offsets);
    end
end
if ~isa(options.normalize, 'function_handle')
    switch options.normalize
        case 'ssd'
            options.normalize = @(patches) patches;
        case 'zeromean'
            options.normalize = @zero_mean;
        case 'ncc'
            options.normalize = @ncc_normalize;
        case 'znssd'
            options.normalize = @ncc_normalize_nograd;
        otherwise
            error('Normalization method %s not recognized', options.normalize);
    end
end
if ~isa(options.prefilter, 'function_handle')
    switch options.prefilter
        case {'gray', 'grey'}
            options.prefilter = @convert2gray;
        case 'locally_normalized'
            options.prefilter = @(im) imnorm(convert2gray(im), 3, 100);
        case 'edge_distance'
            options.prefilter = @(im) edge_distance_image(im, 0.1);
        case 'normalized_edges'
            options.prefilter = @(im) imnorm(normd(imgrad(im, 'sobel'), 3), 1, 100);
        case 'census'
            options.prefilter = @(im) uint8(census_transform(convert2gray(im)));
        case 'descriptor_fields'
            options.prefilter = @(im) uint16(descriptor_field(convert2gray(im), 1) * 256);
        case 'normalized_stack'
            options.prefilter = @(im) single(normalized_channels(im, 1, 5));
        otherwise
            options.prefilter = @(im) im;
    end
end
if options.precompute_gradients
    options.prefilter = @(im) precomputed_gradient(options.prefilter(im));
end
switch options.intensity_model
    case 'none'
        options.extra_dims = 0;
        options.apply_intensity = @(patches, params) patches;
    case 'gain_bias'
        options.extra_dims = 2;
        options.apply_intensity = @gain_bias;
    otherwise
        error('Intensity model %s not recognized', options.intensity_model);
end
end

function patches = gain_bias(patches, params)
params = reshape(params, 2, []);
patches = (patches .* exp(params(1,:))) + params(2,:);
end
