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
    results = recurse_subdirs(@robustifier_experiments, '../Data/graffiti2');
    fprintf('    Done in %gs\n', toc(t));
    
    % Combine and store the results
    results = stack_results(results{~cellfun(@isempty, results)});
    save quantitative.mat results
end

% Generate the plots
M = eye(4) == 0;
% Huber kernel
stats = compute_stats(results, M, 'hard', 1, ndgrid_cols(1:2, 1, 1:3, 1, 1, 1));
plot_stats(stats, {'IRLS', '2nd order', 'INV', 'ESM', 'FWD'}, parula(3), 'huber', [11 2 3], 'Help');
stats = compute_stats(results, M, 'hard', 1, ndgrid_cols(1:2, 2, 1:3, 1, 1, 1));
plot_stats(stats, {'IRLS', '2nd order', 'INV', 'ESM', 'FWD'}, parula(3), 'gm', [11 2 3], 'Help');
end

function results = robustifier_experiments(base)
if isempty(dirim(base))
    % No images here. Just exit.
    results = {};
    return;
end
[~, name] = fileparts(base);
base = cd(cd(base)); % Get the full path to base
qmkdir(name);
temp_cd(name);

if ~exist('results.mat', 'file')
    fprintf(' Computing results for sequence %s...', name); t = tic();
    % Run the experiments
    data = load_sequence_data(base);
    N = numel(data.ims);
    data.experiment_func = 'robustifier_experiment';
    run_experiments(ndgrid_cols(1:N, 1:N, 1:2, [2 1], [2 3 1], 1:2, 6, 1), data);
    
    % Collate the results
    results = get_quantitative_results(data);
    save results.mat results
    fprintf(' Done in %gs.\n', toc(t));
else
    results = load_field('results.mat', 'results');
end
end
