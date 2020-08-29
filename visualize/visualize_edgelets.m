%VISUALIZE_EDGELETS

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function visualize_edgelets(data, im, patch)
if nargin < 3
    if nargin < 2
        for a = 1:numel(data.ims)
            visualize_edgelets(data, a);
        end
        return;
    end
    for a = 1:size(data.feats_per_region{im})
        visualize_edgelets(data, im, a);
        pause();
    end
    return;
end
corners = reshape(data.regions{im}([1 2 3 2 3 4 1 4 1 2],patch), 2, 5)';
I = data.feats_per_region{im}(:,patch);
features = reshape(flipud(normalize(data.rot{im}(:,I))), 2, 1, []) .* [1 -1; -1 1];
features = reshape(data.features{im}(:,I), 2, 1, []) + features;
clf reset;
sc(data.ims{im});
hold on
plot(corners(:,1), corners(:,2), 'r-', 'LineWidth', 3);
render_lines_points(features, parula(size(features, 3))', 'LineWidth', 2);
end