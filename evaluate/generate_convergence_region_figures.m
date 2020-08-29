%GENERATE_COVERGENCE_REGION_FIGURES

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function generate_convergence_region_figures()
% Images
im{3} = double(convert2gray(imread('A.png')));
im{2} = double(convert2gray(imread('B.png')));
im{1} = double(convert2gray(imread('C.png')));
load patch_indices.mat
    
% Scoring functions
prefilter_funcs = {@(im) im, @(im) im, @(im) im, @(im) im, @(im) im, @(im) imnorm(im, 3, 100), @(im) edge_distance_image(im, 0.1), @(im) imnorm(normd(imgrad(im, 'sobel'), 3), 1, 100), @(im) int8(census_transform(im))};
normalize_funcs = {@ssd, @sad, @zerom, @ncc, @gain_bias, @ssd, @ssd, @ssd, @ssd};

if exist('areas.mat', 'file')
    load areas.mat;
else
    N = numel(prefilter_funcs) * numel(im);
    n = 0;
    widths = [2 3 4 5];
    for a = numel(prefilter_funcs):-1:1
        for b = numel(im):-1:1
            [areas(:,:,:,b,a), counts(:,:,:,b,a), regions(:,:,:,b,a)] = cost_function_static_analysis(im{1}, im{b}, patch_ind, normalize_funcs{a}, prefilter_funcs{a}, widths);
            n = n + 1;
            ojw_progressbar('Computing regions...', n/N);
        end
    end
    save areas.mat areas counts regions
end

% Generate the figures
limits = [repmat([0 255], 5, 1); -1 1; 0 35; -0.5 0.5; -1 2]';
radii = sqrt(squeeze(mean(areas, 2)) / (2 * pi));
circle = linspace(0, 2*pi, 101);
circle = [sin(circle); cos(circle)];
styles = {'', '', ':', '-.', '-'};
colors = eye(3);
for a = numel(prefilter_funcs):-1:1
    for b = numel(im):-1:1
        % Display the image
        tgtImOrig = prefilter_funcs{a}(im{b});
        sz = size(tgtImOrig);
        corners = [0.5 0.5; sz(2)+0.5 0.5; sz(2)+0.5 sz(1)+0.5; 0.5 sz(1)+0.5]';
        qfig(gcf());
        clf reset;
        imdisp(double(tgtImOrig(:,:,1:min(end, 3))), limits(:,a));
        hold on
        
        for level = 1:5
            % Display the modes
            for i = 1:3
                if level == 1
                    [y, x] = ind2sub(sz(1:2), patch_ind(i));
                    plot(x, y, '+', 'Color', colors(:,i));
                    [y, x] = find(regions{end,i,end,b,a});
                    plot(x, y, '.', 'Color', colors(:,i));
                end
            end
            if isempty(styles{level})
                continue;
            end
            % Display the regions
            for i = 1:3
                if ~isempty(styles{level}) && ~isscalar(regions{level,i,end,b,a})
                    contour(double(regions{level,i,end,b,a}) - 0.5, [0 0], 'LineColor', colors(:,i), 'LineWidth', 2, 'LineStyle', styles{level});
                end
            end
        
            % Display the circles
            for width = 1:4
                X = circle * radii(level,width,b,a) + corners(:,width);
                plot(X(1,:)', X(2,:)', ['y' styles{level}], 'LineWidth', 2);
            end
        end
        export_fig(gcf(), sprintf('result_im%d_method%d.png', b, a));
    end
end
end

function d = ssd(p, q)
d = p - q;
d = sum(sum(d .* d, 1), 3);
end

function d = sad(p, q)
d = sum(abs(p - q), 1);
end

function d = zerom(p, q)
d = ssd(zero_mean(p), zero_mean(q));
end

function d = ncc(p, q)
d = ssd(normalize(zero_mean(p)), normalize(zero_mean(q)));
end

function d = gain_bias(p, q)
gb = [q ones(size(q, 1), 1)] \ p;
d = ssd(q, (p - gb(2,:)) ./ (gb(1,:) + 1e-20));
end