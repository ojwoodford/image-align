%RENDER_SEQUENCE

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function render_sequence(ims, result)
figure(1);
h = gcf();
sz = normd(diff(result.corners(:,[1:4 1]), 1, 2), 1);
sz = (sz([2 1]) + sz([4 3])) / 2;
extract_normalized_region(convert2gray(ims(1)), result.corners(:,[1 2 4 3]), sz);
corners = homg(result.corners(:,[1 2 4 3 1 4 3 2]));
N = ims.num_frames();
max_time = max(result.time);
max_time = min(median(max_time) * 3, max(max_time));
colors = {'r', 'c', 'm', 'g'};
labels = {'Sparse NCC', 'Dense NCC', 'Descriptor Fields', 'Census Bitplanes'};
widths = [2 3 3 3];
styles = {'-', '-.', '--', ':'};
pb = ojw_progressbar('Rendering video results...', 0, N);
for b = 1:N
    frame = ims(b);
    warp = result.warp(:,:,min([2 1 3 4], end),b);
    time = result.time(min([2 1 3 4], end),b);
    frame = convert2gray(frame);
    for a = 4:-1:1
        Y{a} = proj(warp(:,:,a) * corners)';
        im{a} = extract_normalized_region(frame, warp(:,:,a));
    end
    try
        % Update graphics handles
        set(handles.main_im, 'CData', frame);
        for a = 1:4
            set(handles.sub_im(a), 'CData', im{a});
            set(handles.bar(a), 'YData', time(a));
            set(handles.lines(a), 'XData', Y{a}(:,1), 'YData', Y{a}(:,2));
        end
    catch
        % Reset the figure
        clf(h, 'reset');
        set(h, 'Position', [95 662 1554 583]);
        h.Color = 'w';
        ax = subplot('Position', [0 0 0.5 1]);
        handles.main_im = imdisp(frame, [0 255]);
        hold on;
        for a = 4:-1:1
            handles.lines(a) = plot(ax, Y{a}(:,1), Y{a}(:,2), styles{a}, 'Color', colors{a}, 'LineWidth', widths(a));
        end
        patch([0.5 0.5 repmat(size(frame, 2)+0.5, 1, 2)], [0.5 repmat(size(frame, 1)*0.17, 1, 2) 0.5], 'w', 'FaceAlpha', 0.3, 'EdgeColor', 'none', 'FaceColor', 'w');
        ax = axes('Position', [0.06 0.84 0.43 0.1]);
        hold on
        for a = 4:-1:1
            handles.bar(a) = barh(a, time(a), colors{a});
        end
        xlabel 'Time per frame (s)'
        set(ax, 'YTick', 1:4, 'YTickLabel', labels, 'XLim', [0 max_time], 'YLim', [0.5 4.5], 'XAxisLocation', 'top', 'TickLength', [0 0], 'XGrid', 'on', 'Color', 'none');
        for a = 4:-1:1
            ax = subplot('Position', [0.502+0.25*floor((a-1)/2) 0.002+0.50*mod(a, 2) 0.2485 0.4985]);
            handles.sub_im(a) = imdisp(im{a}, [0 255]);
            set(ax, 'Visible', 'on', 'XTick', [], 'YTick', [], 'Box', 'on', 'XColor', colors{a}, 'YColor', colors{a}, 'LineWidth', 3);
            text(5, 5, labels{a}, 'Interpreter', 'none', 'BackgroundColor', 'w', 'VerticalAlignment', 'bottom', 'Units', 'points');
        end
    end
    drawnow();
    export_fig(h, sprintf('output.%4.4d.png', b), '-a1');
    update(pb, b);
end
end

function im = extract_normalized_region(im, warp, sz)
persistent V sz_
if nargin > 2
    [Y, X] = ndgrid((1:sz(1))/(sz(1)-1), (1:sz(2))/(sz(2)-1));
    sz_ = size(Y);
    V = homg(warp * [(1-X(:)').*(1-Y(:)'); X(:)'.*(1-Y(:)'); (1-X(:)').*Y(:)'; X(:)'.*Y(:)']);
    warp = eye(3);
end
X = proj(warp * V);
im = reshape(ojw_interp2(im, X(1,:), X(2,:), 'l', 128), sz_);
end
