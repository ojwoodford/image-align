%TEST_DENSE_ALIGNMENT

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function [H, costs, gain_bias] = test_dense_alignment(src, tgt, H, type)
if nargin < 2
    if nargin < 1
        rng_seeder();
    else
        rng_seeder(src);
    end
    src = imread('peppers.png');
    H = exp(lie('sim2'), randn(4, 1) .* [5 5 0.1 0.1]');
    tgt = imwarp(single(src) * (0.5 + rand(1)), H);
    close all;
    for a = 1:1
        test_dense_alignment(src, tgt, eye(3), 1);
        %test_dense_alignment(src, tgt, eye(3), 5);
        %test_dense_alignment(src, tgt, eye(3), 11);
        %test_dense_alignment(src, tgt, eye(3), 15);
        %test_dense_alignment(src, tgt, eye(3), 13);
        %test_dense_alignment(src, tgt, eye(3), 14);
    end
    set(gca(), 'YScale', 'log');
    h = findobj(gca(), 'Type', 'Line');
    styles = {'-', '--', '-.', ':'};
    for a = 1:numel(h)
        h(a).LineStyle = styles{numel(h)+1-a};
    end
    return;
end
if nargin < 4
    type = 1;
end

% Compute pyramids
level = size(src);
level = max(floor(log2(min(level(1), level(2)))) - 4, 0);
src = impyramid(src, level);
tgt = impyramid(tgt, level);

% Set the optimizer options
block_size = 0;
switch type
    case 1
        options = {'warp_type', 'sim2', 'composition', 1, 'robustifier', []};
    case 2
        options = {'warp_type', 'sim2', 'composition', -1, 'robustifier', [], 'normalize', @ncc_normalize_nograd};
    case 3
        options = {'warp_type', 'sim2', 'composition', 0, 'robustifier', [], 'normalize', 'zeromean', 'cost_adjustment', @ecc_adjustment};
    case 5
        options = {'warp_type', 'sl3', 'normalize', 'ssd', 'intensity_model', 'gain_bias', 'composition', -1, 'condition_linear_system', true};
        block_size = 6;
    case 6
        options = {'composition', 0, 'robustifier', [], 'prefilter', 'descriptor_fields', 'normalize', 'ssd'};
    case 7
        options = {'composition', -1, 'robustifier', [], 'prefilter', 'census', 'normalize', 'ssd'};
    case 8
        options = {'warp_type', 'sim2', 'composition', -1, 'robustifier', [], 'left_update', true};
    case 9
        options = {'warp_type', 'sl3', 'normalize', 'ssd', 'robustifier', @(r, varargin) robust_gm(r, 100), 'prefilter', 'none'};
    case 10
        options = {'warp_type', 'sim2', 'composition', 0, 'robustifier', @(r, varargin) robust_gm(r, 0.5)};
        block_size = 8;
    case 11
        options = {'warp_type', 'sim2', 'composition', 0, 'robustifier', @irani_weighting};
        block_size = 8;
    case 12
        options = {'warp_type', 'sim2', 'composition', 0, 'robustifier', @scandaroli_weighting};
        block_size = 8;
    case 13
        options = {'composition', -1, 'robustifier', [], 'prefilter', 'census', 'normalize', 'ssd'};
    case 14
        options = {'composition', 0, 'robustifier', [], 'prefilter', 'census', 'normalize', 'ssd'};
end
options = direct_options(options{:});
options.optimizer_params(1) = 200;
%options.iteration_func = @store;
gain_bias = zeros(options.extra_dims, 1);
%robust = options.robustifier(1e100) ~= 1e200;
%options.prefilter = @(im) precomputed_gradient(options.prefilter(im));

% Do coarse to fine
%figure(1);
for level = numel(src):-1:1
    % Account for the scale
    scale = [0.5 0 0.25; 0 0.5 0.25; 0 0 1] ^ (level - 1);
    H = scale * H / scale;
    
    % Compute the sample region
    sz = size(src{level});
    border = ceil(sz / 5);
    sz = sz - border + 1;
    region = [border([2 1]) sz([2 1])];
    [Y, X] = ndgrid(region(2)+0.5:region(4), region(1)+0.5:region(3));
    options.debug_points = [X(1,1) X(1,end) X(end,end) X(end,1) X(1,1); ...
                            Y(1,1) Y(1,end) Y(end,end) Y(end,1) Y(1,1)];
    if block_size ~= 0
        % Cull to a multiple of the block size
        after = mod(size(X), block_size) * 0.5;
        before = floor(after);
        after = ceil(after);
        X = X(before(1)+1:end-after(1),before(2)+1:end-after(2));
        X = reshape(permute(reshape(X, block_size, size(X, 1)/block_size, block_size, size(X, 2)/block_size), [1 3 2 4]), block_size*block_size, []);
        Y = Y(before(1)+1:end-after(1),before(2)+1:end-after(2));
        Y = reshape(permute(reshape(Y, block_size, size(Y, 1)/block_size, block_size, size(Y, 2)/block_size), [1 3 2 4]), block_size*block_size, []);
        X = [shiftdim(X, -1); shiftdim(Y, -1)];
    else
        X = [col(X, 2); col(Y, 2)];
    end
    
    if ~isempty(gain_bias)
        if block_size == 0
            X = X(:,:);
        end
        gain_bias = repmat(mean(gain_bias, 2), 1, size(X, 3));
    end
    
    % Construct the problem
    h = directAlign(src{level}, X, [], options);
    
    % Optimize
    figure(1);
    %store();
    [H, costs{level}] = optimize(h, tgt{level}, [col(H); col(gain_bias)]);
    gain_bias = reshape(H(10:end), 2, []);
    H = scale \ reshape(H(1:9), 3, 3) * scale;
    costs{level} = costs{level} / numel(Y);
    %costs{level} = col(store()) / numel(Y);
end

% Plot the costs
costs = flipud(costs(:));
figure(2);
hold all
plot(cat(1, costs{:}));
end

function y = store(~, s, varargin)
persistent z
if nargin == 0
    y = z;
    z = [];
else
    z(s.iteration) = s.score;
    y = false;
end
end
