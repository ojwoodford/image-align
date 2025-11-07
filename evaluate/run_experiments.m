%RUN_EXPERIMENTS

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function run_experiments(experimentParams, data)
num_workers = min(num_cores(), size(experimentParams, 2));
data.num_threads = ceil(num_cores() / num_workers);
batch_job_distrib(@experiment_wrapper, experimentParams,  {'', num_workers}, data, '-progress', '-chunk_lims', [1 1]);
end
