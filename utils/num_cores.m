%NUM_CORES Return the number of cores on this machine

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function n = num_cores(logical)
if nargin > 0 && logical
    n = regexp(evalc('feature(''numcores'')'), 'MATLAB detected: (\d+) logical cores.', 'tokens');
    n = str2double(n{1}{1});
else
    n = feature('numcores');
end
end