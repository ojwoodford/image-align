%PLOT_STATS

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function plot_stats(stats, labels, colors, name, sz, bar_x_label, bar_labels, show_legend, position)
if nargin < 9
    position = [100 118 304 265];
    if nargin < 8
        show_legend = [1 0 0 1 0];
        if nargin < 7
            bar_labels = labels;
        end
    end
end
plots = {'converged', 'iterations', 'time_to_converge'; ...
         'Proportion (%) converged', 'Num. iterations to converge', 'Mean time (s) to converge'; ...
         [1 1], [1 1], [1 0]; ...
         [0 100], [], []; ...
         100, 1, 1};
export = @(varargin) export_fig(varargin{:});
set(gcf(), 'Position', position);
x_label = 'Mean initial corner error';
a = 1;
for p = plots
    plot_two_categories((0:10)', reshape(stats.(p{1}), sz)*p{5}, [0 10], p{4}, x_label, p{2}, p{3}, colors, labels, show_legend(a));
    export(sprintf('%s_%s.pdf', name, p{1}));
    a = a + 1;
end

% Iteration time bar chart
clf();
set(gcf(), 'Color', 'w');
set(gca(), 'FontName', 'Times', 'FontSize', 10, 'LineWidth', 1);
hold on;
data = shiftdim(mean(reshape(stats.time_per_iteration, sz), 1), 1)' * 1000;
if size(data, 1) > 1
    h = bar(data);
    for a = 1:sz(2)
        h(a).FaceColor = colors(a,:);
    end
    set(gca(), 'XTick', 1:sz(3), 'XTickLabel', bar_labels(sz(2)+1:end));
    xlim([0.5 sz(3)+0.5]);
else
    for a = 1:sz(2)
        h = bar(a, data(a));
        h.FaceColor = colors(a,:);
    end
    set(gca(), 'XTick', 1:min(numel(bar_labels), sz(2)), 'XTickLabel', bar_labels(1:min(sz(2), end)));
    xlim([0.5 sz(2)+0.5]);
end
if show_legend(4)
    legend(labels{1:sz(2)}, 'Location', 'NorthWest');
end
if ~isempty(bar_x_label)
    xlabel(bar_x_label);
end
ylabel('Mean time per iteration (ms)');
box on
set(gca(), 'TickLength', [0 0], 'YGrid', 'on', 'YMinorGrid', 'on');
export(sprintf('%s_iteration_time.pdf', name));

% Error recall curve
x = sort(reshape(stats.err(5,:), [size(stats.err, 2) sz(2:end)]));
x = [zeros(1, size(x, 2), size(x, 3)); x];
y = cumsum(sign(x), 1);
y = y .* (100 ./ max(y));
plot_two_categories(x, y, [0.1 10], [0 100], 'Max. corner error (pixels)', 'Recall (%)', [0 1], colors, labels, show_legend(5));
set(gca(), 'XTick', [0.1 1 10], 'XTickLabel', {'0.1', '1', '10'});
export(sprintf('%s_error_recall.pdf', name));
end

function plot_two_categories(x, y, x_lim, y_lim, x_label, y_label, scales, colors, labels, show_legend)
clf();
set(gcf(), 'Color', 'w');
set(gca(), 'FontName', 'Times', 'FontSize', 10, 'LineWidth', 1);
hold on;
% Lines for legend
sz = [max([size(y) ones(1, 3-ndims(y))], [size(x) ones(1, 3-ndims(x))]) 1];
for b = 1:sz(2)
    plot(NaN(2, 1), NaN(2, 1), '-', 'Color', colors(b,:), 'LineWidth', 1);
end
if sz(3) > 1
    styles = {'-.', '-', ':', '--'};
    for c = 1:sz(3)
        plot(NaN(2, 1), NaN(2, 1), 'k-', 'LineStyle', styles{c}, 'LineWidth', 1);
    end
else
    styles = {'-'};
end
if sz(1) <= 20
    marker = '.';
else
    marker = '-';
end
% Actual lines to plot
for b = sz(2):-1:1
    for c = 1:sz(3)
        plot(x(:,min(b, end),min(c, end)), y(:,min(b, end),min(c, end)), marker, 'Color', colors(b,:), 'LineStyle', styles{c}, 'LineWidth', 1);
    end
end
if ~isempty(x_label)
    xlabel(x_label);
end
if ~isempty(y_label)
    ylabel(y_label);
end
if isempty(x_lim)
    x_lim = [min(x(:)) max(x(:))];
end
if isempty(y_lim)
    y_lim = [min(y(:)) max(y(:))];
end
xlim(x_lim);
ylim(y_lim);
grid on
box on
scales_ = {'log', 'linear'};
set(gca(), 'XScale', scales_{scales(1)+1}, 'YScale', scales_{scales(2)+1});
if show_legend
    h = legend(labels{:});
    if size(y, 3) > 1
        h.NumColumns = 2;
    end
    set(h.BoxFace, 'ColorData', uint8([255 255 255 200])', 'ColorType', 'truecoloralpha')
    h.Location = 'NorthEast';
end
end
