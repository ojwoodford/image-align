%EXPERIMENT_WRAPPER

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function out = experiment_wrapper(params, data)
out = 0;
% Check if the experiment has already been run
fname = sprintf('_%2.2d', params);
fname = [fname(2:end) '.mat'];
if exist(fname, 'file')
    return;
end
try
    % Run the experiment
    experiment_func = str2func(data.experiment_func);
    out = experiment_func(params, data);
    % Save the results
    save(fname, '-struct', 'out');
    out = 1;
catch me
    % Catch errors
    err = getReport(me);
    save(fname, 'err');
    fprintf('\nFailed experiment: %s\n', sprintf('%g ', params));
    warning(err);
end
end
