%RUN_ROBUSTIFIER_EXPERIMENTS

% Copyright Oliver Woodford 2025

function run_robustifier_experiments(base)
resdir = fullfile(base, 'RobustResults');
qmkdir(resdir);
temp_cd(resdir);

% Generate the results
if exist('quantitative.mat', 'file')
    results = load_field('quantitative.mat', 'results');
else
    fprintf('Running robustifier experiments...\n'); t = tic();
    experimentParams = [ndgrid_cols(1:2, 1:2, [2 3 1], 1:2, 6, 1, 1) ... % NCC dense & sparse
                        ndgrid_cols(1:2, 1:2, [2 3 1], 1:2, 6, 1, 2)]; % SSD dense
    results = recurse_subdirs(@(base) run_experiments(base, 'robustifier_experiment', experimentParams), '../Data/graffiti2');
    fprintf('    Done in %gs\n', toc(t));
    
    % Combine and store the results
    results = stack_results(results{~cellfun(@isempty, results)});
    save quantitative.mat results
end

% Generate the plots
% NCC
M = eye(4) == 0;
stats = compute_stats(results, M, 'hard', 1, ndgrid_cols(1:2, 1, 1:3, 1, 1, 1, 1));
plot_stats(stats, {'IRLS', '2nd order', 'INV', 'ESM', 'FWD'}, parula(3), 'ncc_dense_huber', [11 2 3], 'Help');
stats = compute_stats(results, M, 'hard', 1, ndgrid_cols(1:2, 2, 1:3, 1, 1, 1, 1));
plot_stats(stats, {'IRLS', '2nd order', 'INV', 'ESM', 'FWD'}, parula(3), 'ncc_dense_gm', [11 2 3], 'Help');
stats = compute_stats(results, M, 'hard', 1, ndgrid_cols(1:2, 1, 1:3, 2, 1, 1, 1));
plot_stats(stats, {'IRLS', '2nd order', 'INV', 'ESM', 'FWD'}, parula(3), 'ncc_sparse_huber', [11 2 3], 'Help');
stats = compute_stats(results, M, 'hard', 1, ndgrid_cols(1:2, 2, 1:3, 2, 1, 1, 1));
plot_stats(stats, {'IRLS', '2nd order', 'INV', 'ESM', 'FWD'}, parula(3), 'ncc_sparse_gm', [11 2 3], 'Help');
% SSD
M = ~M;
stats = compute_stats(results, M, 'hard', 1, ndgrid_cols(1:2, 1, 1:3, 1, 1, 1, 2));
plot_stats(stats, {'IRLS', '2nd order', 'INV', 'ESM', 'FWD'}, parula(3), 'ssd_dense_huber', [11 2 3], 'Help');
stats = compute_stats(results, M, 'hard', 1, ndgrid_cols(1:2, 2, 1:3, 1, 1, 1, 2));
plot_stats(stats, {'IRLS', '2nd order', 'INV', 'ESM', 'FWD'}, parula(3), 'ssd_dense_gm', [11 2 3], 'Help');
stats = compute_stats(results, M, 'hard', 1, ndgrid_cols(1:2, 1, 1:3, 2, 1, 1, 2));
plot_stats(stats, {'IRLS', '2nd order', 'INV', 'ESM', 'FWD'}, parula(3), 'ssd_sparse_huber', [11 2 3], 'Help');
stats = compute_stats(results, M, 'hard', 1, ndgrid_cols(1:2, 2, 1:3, 2, 1, 1, 2));
plot_stats(stats, {'IRLS', '2nd order', 'INV', 'ESM', 'FWD'}, parula(3), 'ssd_sparse_gm', [11 2 3], 'Help');
end
