%COST_FUNCTION_STATIC_ANALYSIS

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function [convergenceAreas, minimaCounts, regions] = cost_function_static_analysis(srcIm, tgtIm, patch_ind, distance_func, prefilter_func, patch_half_widths)
sz = size(tgtIm);

% Construct the filtered windows
[srcY, srcX] = ndgrid(1:size(srcIm, 1), 1:size(srcIm, 2));
srcX = srcX(:)';
srcY = srcY(:)';
[tgtY, tgtX] = ndgrid(1:size(tgtIm, 1), 1:size(tgtIm, 2));
tgtX = tgtX(:)';
tgtY = tgtY(:)';
patch_half_widths = sort(patch_half_widths); % Smaller to larger
windows = cell(2, 5, numel(patch_half_widths));
for width = numel(patch_half_widths):-1:1
    offsets{width} = patch_patterns('square', [floor(patch_half_widths(width))*2+1 1])';
end
for level = 1:size(windows, 2)
    step = 2 .^ (level - 1);
    [srcIm, srcFiltered] = filter(srcIm, step, prefilter_func);
    [tgtIm, tgtFiltered] = filter(tgtIm, step, prefilter_func);
    oobv = cast(0, 'like', srcFiltered);
    for width = 1:size(windows, 3)
        windows{1,level,width} = ojw_interp2(srcFiltered, bsxfun(@plus, srcX, offsets{width}(:,1)), bsxfun(@plus, srcY, offsets{width}(:,2)), 'n', oobv);
        windows{2,level,width} = ojw_interp2(tgtFiltered, bsxfun(@plus, tgtX, offsets{width}(:,1)), bsxfun(@plus, tgtY, offsets{width}(:,2)), 'n', oobv);
        offsets{width} = offsets{width} * 2;
    end
end

% For each width
for width = size(windows, 3):-1:1
    % For each patch
    for i = numel(patch_ind):-1:1
        for level = 1:size(windows, 2)
            % Compute the distance image
            output = reshape(distance_func(windows{2,level,width}, windows{1,level,width}(:,patch_ind(i),:)), sz);
            
            % Find the local minima
            M = imnonmaxsup(-output, 1.5);
            
            % Find the modes in the watershed of the pyramid level below
            if level == 1
                modes = patch_ind(i);
            else
                % Find the modes in the watershed
                modes = find(M & L);
            end
            
            % Count all the minima
            M = M & output <= output(patch_ind(i));
            minimaCounts(level,i,width) = sum(M(:));
            
            if isempty(modes)
                L = false;
            else
                % Compute the watershed
                L = watershed(output, 8);
                l = unique(L(modes));
                l = l(l ~= 0);
                L = imerode(imdilate(ismember(L, l), ones(3)), ones(3));
            end
            convergenceAreas(level,i,width) = sum(L(:));
            
            if i <= 3
                % Store the watershed
                regions{level,i,width} = L;
                if level == 1
                    % Store the modes
                    regions{size(windows, 2)+1,i,width} = M;
                end
            end
        end
    end
end
end

function [im, filtered] = filter(im, step, prefilter_func)
filtered = prefilter_func(zeros(11));
filtered = zeros(size(im, 1), size(im, 2), size(filtered, 3), class(filtered));
% Split the image up into shifted tiles at the correct subsampling
for a = 1:step
    for b = 1:step
        % Extract the tile
        im_ = im(b:step:end,a:step:end,:);
        % Apply the prefilter to each tile
        filtered(b:step:end,a:step:end,:) = prefilter_func(im_);
        % Filter the tile as if downsampling
        im(b:step:end,a:step:end,:) = imfiltsep(im_, [0 0.125 0.375 0.375 0.125]);
    end
end
end