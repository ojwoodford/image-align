%STACK_RESULTS

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function results = stack_results(varargin)
results = varargin{1};
I = find(~cellfun(@isempty, results));
for a = 2:nargin
    results(I) = cellfun(@(c, d) cat(6, c, d), results(I), varargin{a}(I), 'UniformOutput', false);
end
end
