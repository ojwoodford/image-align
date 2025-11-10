%RUN_EXPERIMENTS

% Copyright Oliver Woodford 2025

function results = run_experiments(base, funcname, experimentParams)
t = tic();
N = numel(dirim(base));
if N == 0
    % No images here. Just exit.
    results = {};
    return;
end
[~, name] = fileparts(base);
base = cd(cd(base)); % Get the full path to base
qmkdir(name);
temp_cd(name);

experimentParams = vertcat(repmat(ndgrid_cols(1:N, 1:N), 1, size(experimentParams, 2)), ...
                   reshape(repmat(experimentParams, N*N, 1), size(experimentParams, 1), []));
experimentParams = experimentParams(:,cellfun(@(v) ~done(v), num2cell(experimentParams, 1)));

if ~isempty(experimentParams)
    fprintf(' Computing results for sequence %s...', name);
    % Clear stored results
    qdelete('results.mat');
    % Run the experiments
    data = load_sequence_data(base);
    data.experiment_func = funcname;
    num_workers = min(num_cores(), size(experimentParams, 2));
    batch_job_distrib(@experiment_wrapper, experimentParams,  {'', num_workers}, data, '-progress', '-chunk_lims', [1 1]);
end

if ~exist('results.mat', 'file')
    % Collate the results
    results = get_quantitative_results(data);
    save results.mat results
    fprintf(' Done in %gs.\n', toc(t));
else
    results = load_field('results.mat', 'results');
end
end

function is = done(params)
fname = sprintf('_%2.2d', params);
is = exist([fname(2:end) '.mat'], 'file');
end