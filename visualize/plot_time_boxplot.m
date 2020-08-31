%PLOT_TIME_BOXPLOT

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function plot_time_boxplot(times, show_legend)
% Plot the frame time bar chart
set(gcf(), 'Position', [182 583 245 235]);
clf();
set(gcf(), 'Color', 'w');
set(gca(), 'FontName', 'Times', 'FontSize', 10, 'LineWidth', 1);
l = bplot(times([2 1 3 4],:)'*1e6, 'outliers', 'whisker', 5, 'linewidth', 1);
ylim([min(times(:)) max(times(:))]*1e6);
xlim([0.5 4.5])
set(gca(), 'XTick', 1:4, 'XTickLabel', {'Sparse\newline NCC', 'Dense\newline NCC', '   Census\newlineTransform', 'Descriptor\newline   Fields'}, 'YScale', 'log', 'YGrid', 'on');
ylabel('Tracking time (us/pixel/frame)');
box on
if nargin > 1 && show_legend
    legend(l{:}, 'Location', 'NorthWest');
end
end
