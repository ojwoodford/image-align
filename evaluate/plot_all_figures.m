%PLOT_ALL_FIGURES

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function plot_all_figures()

% Generate the edgelet figures
if exist('../Data/graffiti2/2/2_1.png', 'file')
    im = imread('../Data/graffiti2/2/2_1.png');
    generate_edgelets_figure(im, 100, [532 147 659 274]);
    for a = 1:3
        optimization_visualization(im, [571 186 619 234], {linspace(-10, 10, 512), linspace(-10, 10, 512)}, a);
    end
end

% Generate the quantitative figures
if exist('quantitative.mat', 'file')
    results = load_field('quantitative.mat', 'results');
    % Global NCC/gain+bias schemes
    M = eye(4) == 0;
    stats = compute_stats(results, M, 'hard', 1, ndgrid_cols([1:2 8 3], 1, 1:3, 1, 6));
    plot_stats(stats, {'NCC', 'ZNSSD', 'GB', 'ECC', 'INV', 'ESM', 'FWD'}, parula(5), 'ncc_global', [11 4 3], 'Jacobian type');
    % Locally normalized NCC
    stats = compute_stats(results, M, 'hard', 1, ndgrid_cols([1:2 8], 2, 1:3, 1, 6));
    plot_stats(stats, {'NCC', 'ZNSSD', 'GB', 'INV', 'ESM', 'FWD'}, parula(5), 'ncc_local', [11 3 3], 'Jacobian type');
    % Weighting schemes
    stats = compute_stats(results, M, 'hard', 1, reshape(ndgrid_cols([1:2 9:10], 3, 1:3, 1, 6), 5, 4, 3));
    plot_stats(stats, {'NCC GM', 'ZNSSD GM', 'Det. H', 'SMR', 'INV', 'ESM', 'FWD'}, parula(5), 'weighting', [11 4 3], 'Jacobian type');
    % Grid block size
    stats = compute_stats(results, M, 'hard', 1, ndgrid_cols(1, 3, 2, 1, [8 6 4 3 2]));
    labels = {'8\times8', '6\times6', '4\times4', '3\times3', '2\times2'};
    plot_stats(stats, labels, parula(6), 'block_size', [11 5], 'Block size', labels, [1 0 0 0 0 0]);
    % Number of sparse features, our layout vs DSO
    stats = [ndgrid_cols(1, 6, 2, 1, 10) ndgrid_cols(1, 5, 2, 1, 10:-1:1)];
    stats = compute_stats(results, M, 'hard', 1, stats);
    plot_stats(stats, {'100 fts. DSO', '100 features', '90 features', '80 features', '70 features', '60 features', '50 features', '40 features', '30 features', '20 features', '10 features'}, ...
                       [1 0 0; parula(10)], 'sparse', [11 11], 'Features', {'DSO', '100', '90', '80', '70', '60', '50', '40', '30', '20', '10'}, [1 0 0 0 0 0]);
    % Image descriptors
    stats = [reshape(ndgrid_cols(1, 3, 1:3, 1, 6), 5, 1, 3) reshape(ndgrid_cols(1, 5, 1:3, 1, 10), 5, 1, 3) reshape(ndgrid_cols(5:6, 1, 1:3, 1, 6), 5, 2, 3)];
    stats = compute_stats(results, M, 'hard', 1, stats);
    plot_stats(stats, {'6\times6 NCC', 'Sparse NCC', 'Descriptor Fields', 'Census Bitplanes', 'INV', 'ESM', 'FWD'}, parula(5), 'descriptors', [11 4 3], 'Jacobian type');
    % Image descriptors w. occlusion
    stats = [cat(3, ndgrid_cols(1, 2, 1, 1, 6), ndgrid_cols(1, 3, 1, 2, 6)) reshape(ndgrid_cols(5:6, 1, 1, 1:2, 6), 5, 2, 2)];
    stats = compute_stats(results, M, 'hard', 1, stats);
    plot_stats(stats, {'NCC', 'Descriptor Fields', 'Census Bitplanes', 'No robust.', 'Occluded'}, parula(4), 'descriptors2', [11 3 2], '');
    % Occlusion : grid & sparse, robust & no robust
    stats = compute_stats(results, M, 'hard', 1, [reshape(ndgrid_cols(1, 2:3, 1:3, 2, 6), 5, 2, 3) reshape(ndgrid_cols(1, 4:5, 1:3, 2, 10), 5, 2, 3)]);
    plot_stats(stats, {'6\times6 NCC None', '6\times6 NCC GM', 'Sparse NCC None', 'Sparse NCC GM', 'INV', 'ESM', 'FWD'}, parula(5), 'occlusion', [11 4 3], 'Jacobian type');
    % Scandaroli ESM
    stats = compute_stats(results, M, 'hard', 1, ndgrid_cols(1, 2, [2 4], 1, 6));
    labels = {'ESM', 'SMR'};
    plot_stats(stats, labels, parula(3), 'scandaroli_esm', [11 2 1], 'Optimizer', labels, [1 0 0 0 0 0]);
    % Locally normalized NCC vs SSD
    stats = [7 1 2 1 6; 1 2 2 1 6]';
    stats = merge_stats(compute_stats(results, ~M, 'hard', 1, stats), compute_stats(results, M, 'hard', 1, stats));
    stats = merge_stats(stats, compute_stats(results, M, 'hard', 1, [7 1 1 1 6; 1 2 1 1 6]'));
    plot_stats(stats, {'SSD', 'NCC', 'Same/ESM', 'Diff./ESM', 'Diff./INV'}, parula(3), 'ssd', [11 2 3], '');
end

if exist('videos', 'dir')
    sequences = {'book', 'bear', 'cat-plane'};
    frame_times = cell(numel(sequences), 2);
    for a = 1:numel(sequences)
        results = load(sprintf('videos/%s.mat', sequences{a}));
        frame_times{a,1} = results.time(:,2:end) / polyarea(results.corners(1,:), results.corners(2,:));
        results = load(sprintf('videos/%s_esm.mat', sequences{a}));
        frame_times{a,2} = results.time(:,2:end) / polyarea(results.corners(1,:), results.corners(2,:));
    end
    plot_time_boxplot(cat(2, frame_times{:,1}), true);
    export_fig('frame_times.pdf');
    plot_time_boxplot(cat(2, frame_times{:,2}));
    export_fig('frame_times_esm.pdf');
end
end