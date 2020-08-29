%OPTIMIZATION_VISUALIZATION

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function optimization_visualization(im, region, dense_offsets, method, start_points)
if nargin < 5
    start_points = linspace(-1 * pi, 0.75 * pi, 8);
    start_points = [cos(start_points); sin(start_points)] .* (logspace(-0.7, 0, 8) * dense_offsets{1}(end));
end
options.warp_type = 'trans';
options.prefilter = 'gray';
options.normalize = 'ncc';
options.optimizer_params = [100 1e-6 1e-10 3];
options.composition = 0; % Negative means inverse, positive means forwards, zero means ESM (hybrid)
options.robustifier = [];
X = flipud(ndgrid_cols(region(2)+0.5:region(4), region(1)+0.5:region(3)));
block_size = 6;
X = reshape(permute(reshape(X, 2, block_size, (region(4)-region(2))/block_size, block_size, (region(3)-region(1))/block_size), [1 2 4 3 5]), 2, block_size*block_size, []);
if method == 1
    X = X(:,:);
end
if method == 3
    tau = 0.5;
    robustify = @(c) c .* (tau*tau ./ (c + tau*tau));
    cost = @(c) sum(robustify(sum(c .* c, 1)), 2);
    options.robustifier = @(r, varargin) robust_gm(r, tau);
else
    cost = @(c) sum(sum(c .* c, 1), 2);
end
options = direct_options(options);
im = options.prefilter(im);

Y = flipud(ndgrid_cols(dense_offsets{1}, dense_offsets{2}));
src = ncc_normalize(ojw_interp2(im, shiftdim(X(1,:,:), 1), shiftdim(X(2,:,:), 1)));
tgt = ncc_normalize(reshape(ojw_interp2(im, shiftdim(X(1,:,:), 1)+col(Y(1,:), 3), shiftdim(X(2,:,:), 1)+col(Y(2,:), 3)), size(X, 2), size(X, 3), size(Y, 2)));
tgt = reshape(cost(tgt - src), numel(dense_offsets{2}), numel(dense_offsets{1}));
cmap = earth(14);
cmap = cmap(floor(end*0.6):floor(end*0.95),:) * 0.5 + 0.5;

% Optimize from each start point using each method
H = eye(3);
trajectory = cell(size(start_points, 2), 4);
% NCC
h = directAlign(im, X, [], options);
for a = 1:size(start_points, 2)
    H(1:2,3) = start_points(:,a);
    [H, costs, traj] = optimize(h, im, H);
    [~, m] = min(costs);
    trajectory{a,1} = traj(7:8,1:m)';
end
% Scandaroli
options.optimizer = @optimize_scandaroli_esm;
options.composition = 1;
for a = 1:size(start_points, 2)
    H(1:2,3) = start_points(:,a);
    [H, costs, traj] = optimize(h, im, H, options);
    [~, m] = min(costs);
    trajectory{a,3} = traj(7:8,1:m)';
end
% ZNSSD
options.optimizer = @optimize_gauss_newton;
options.composition = 0;
options.normalize = @ncc_normalize_nograd;
h = directAlign(im, X, [], options);
for a = 1:size(start_points, 2)
    H(1:2,3) = start_points(:,a);
    [H, costs, traj] = optimize(h, im, H, options);
    [~, m] = min(costs);
    trajectory{a,2} = traj(7:8,1:m)';
end
if method == 1
    % ECCM
    options.normalize = @zero_mean;
    options.cost_adjustment = @ecc_adjustment;
    h = directAlign(im, X, [], options);
    for a = 1:size(start_points, 2)
        H(1:2,3) = start_points(:,a);
        [H, costs, traj] = optimize(h, im, H);
        [~, m] = min(costs);
        trajectory{a,4} = traj(7:8,1:m)';
    end
end

clf reset;
set(gcf(), 'Color', 'w', 'Position', [540 493 135 167]);
imsc(dense_offsets{1}, dense_offsets{2}, tgt, cmap);
colors = [0 0.4470 0.7410; 0.8500 0.3250 0.0980; 0.4940 0.1840 0.5560; 0.9290 0.6940 0.1250];
hold on;
for b = 1:3+(method==1)
    plot(NaN(2, 1), NaN(2, 1), '-', 'Color', colors(b,:));
end
contour(dense_offsets{1}, dense_offsets{2}, tgt, 'LineWidth', 0.5, 'Color', 'w');
for a = size(start_points, 2):-1:1
    for b = 3+(method==1):-1:1
        plot(trajectory{a,b}(:,1), trajectory{a,b}(:,2), '.-', 'Color', colors(b,:), 'MarkerSize', 2.5);
        plot(trajectory{a,b}(end,1), trajectory{a,b}(end,2), '.', 'Color', colors(b,:), 'MarkerSize', 4);
    end
end
plot(start_points(1,:)', start_points(2,:)', 'k.', 'MarkerSize', 4);

set(gca(), 'FontName', 'Times', 'FontSize', 5, 'YDir', 'normal');
axis equal;
xlim(dense_offsets{1}([1 end]));
ylim(dense_offsets{2}([1 end]));
names = {'NCC', 'ZNSSD', 'SMR', 'ECCM'};
[h, icons] = legend(names{1:3+(method==1)}, 'Location', 'SouthEast');
h.Color = 'none';
h.Box = 'off';
for a = 4+(method==1):2:numel(icons)
    icons(a).XData(1) = 0.4;
end
export_fig(sprintf('trajectory_%d.pdf', method));
end