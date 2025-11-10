%RUN_QUANTITATIVE_EXPERIMENTS

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function run_quantitative_experiments()
if exist('quantitative.mat', 'file')
    return;
end
fprintf('Running quantitative experiments...\n'); t = tic();
experimentParams = [ndgrid_cols(1,   2,     4,   0, 6) ... % Scandaroli ESM update
                ndgrid_cols(5:6, 1,     2:3, 0, 6) ... % Other descriptor experiments (all compositions)
                ndgrid_cols(8,   1:2,   1:3, 0, 6) ... % Generative (all compositions)
                ndgrid_cols(1:3, 1,     2:3, 0, 6) ... % Single cost experiments
                ndgrid_cols(1:2, 2:3,   2:3, 0, 6) ... % Multi cost experiments
                ndgrid_cols(1:2, 5,     2:3, 0, 10) ... % Multi cost experiments
                ndgrid_cols(1,   3,     2,   0, [2 3 4 6 8]) ... % Grid block size experiment
                ndgrid_cols(1,   1:3,   2,   0, 6) ... % Patch layout experiments
                ndgrid_cols(1,   [4 6], 2,   0, 10) ... % Patch layout experiments
                ndgrid_cols(1,   1:3,   2:3, 1, 6) ... % Occlusion experiments
                ndgrid_cols(1,   4:5,   2:3, 1, 10) ... % Occlusion experiments
                ndgrid_cols(9:10,  3,   1:3, 0, 6) ... % Weighting experiments
                ndgrid_cols(7,   1,     2,   0, 6) ... % SSD (ESM only)
                ndgrid_cols(1,   2,     2:3, 0, 6) ... % NCC no weighting
                ndgrid_cols(1,   5,     2,   0, 10:-1:1) ... % Number of features experiment
                ndgrid_cols(6:-1:1, 1,  1,   0, 6) ... % Other descriptor experiments (all compositions)
                ndgrid_cols(1,   1:3,   1,   1, 6) ... % Occlusion experiments
                ndgrid_cols(1,   4:5,   1,   1, 10) ... % Occlusion experiments
                ndgrid_cols(5:6, 1,     1,   1, 6) ... % Occlusion experiments
                ndgrid_cols(1:3, 1,     1,   0, 6) ... % Single cost experiments (InvComp)
                ndgrid_cols(1:2, 2:3,   1,   0, 6) ... % Multi cost experiments (InvComp)
                ndgrid_cols(1:2, 5,     1,   0, 10) ...  % Multi cost experiments (InvComp)
                ndgrid_cols(1,   2,     1,   0, 6)  ... % NCC no weighting (InvComp)
                ndgrid_cols(7,   1,     1,   0, 6)]; ... % SSD (InvComp)
experimentParams = unique(experimentParams', 'stable', 'rows')'; % Remove duplicates
results = recurse_subdirs(@(base) run_experiments(base, 'ncc_experiment', experimentParams), '../Data/graffiti2');
fprintf('    Done in %gs\n', toc(t));

% Combine and store the results
results = stack_results(results{~cellfun(@isempty, results)});
save quantitative.mat results
end
