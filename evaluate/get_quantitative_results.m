%GET_QUANTITATIVE_RESULTS

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function results = get_quantitative_results(data, fname)
if nargin < 2
    % Go through all results in the current directory
    d = dir('*.mat');
    sz_min = Inf;
    sz_max = -Inf;
    M = false(numel(d), 1);
    for a = 1:numel(d)
        ind = sscanf(d(a).name, '%d_');
        if isempty(ind)
            continue;
        end
        M(a) = true;
        sz_min = min(sz_min, ind);
        sz_max = max(sz_max, ind);
    end
    d = d(M);
    sz_min = sz_min - 1;
    sz = col(sz_max-sz_min, 2);
    results = cell(sz(3:end));
    for a = 1:numel(d)
        ind = sscanf(d(a).name, '%d_');
        try
            result = get_quantitative_results(data, d(a).name);
        catch me
            warning('Error generating result%s:\n%s', sprintf(' %d', ind), getReport(me));
            continue;
        end
        ind = num2cell(ind - sz_min);
        if isempty(results{ind{3:end}})
            results{ind{3:end}} = NaN(8, 11, 100, sz(1), sz(2));
        end
        results{ind{3:end}}(:,:,:,ind{1:2}) = result;
    end
    return;
end
% Load the data
ind = sscanf(fname, '%d_');
gtH = data.gtH_refined(:,:,ind(1),ind(2));
region = data.regions{ind(1)};
output = load(fname);
if isfield(output, 'err')
    error(output.err);
end
% Compute the results
results = cat(3, output.times, cellfun(@numel, output.costs), cellfun(@(c) c(1), output.costs), cellfun(@min, output.costs));
corners = homg(reshape(region([1 2 1 4 3 4 3 2],:), 2, 4, 1, []));
corners = shiftdim(normd(bsxfun(@minus, proj(tmult(gtH, corners)), proj(tmult(output.H, corners))), 1), 1);
results = cat(1, corners, permute(results, [3 1 2]));
end