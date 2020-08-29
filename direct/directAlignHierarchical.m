%DIRECTALIGNHIERARCHICAL

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

classdef directAlignHierarchical
    properties (SetAccess = private, Hidden = true)
        levels;
        options;
    end
    methods
        function this = directAlignHierarchical(srcImPyramid, baseLevelPatchPixelCoordinates, weights, options, patchCenter)
            if ~iscell(options)
                options = {options};
            end
            this.options = options;
            
            computeRegions = isequal(size(baseLevelPatchPixelCoordinates), [2 4]);
            if ~computeRegions && nargin < 5
                % Subtract the center from the patch coordinates
                baseLevelPatchPixelCoordinates = baseLevelPatchPixelCoordinates(end-1:end,:,:);
                patchCenter = mean(baseLevelPatchPixelCoordinates, 2);
                baseLevelPatchPixelCoordinates = bsxfun(@minus, baseLevelPatchPixelCoordinates, patchCenter);
            end
            
            % For each pyramid level
            ideal2im = cellfun(@(c) c.ideal2image, options, 'UniformOutput', false);
            this.levels = {};
            s = [2, -0.5];
            for level = 1:max(numel(srcImPyramid), numel(options))
                im = srcImPyramid{min(level, end)};
                % Account for scale
                if level <= numel(srcImPyramid)
                    s = s * 0.5;
                    s(2) = s(2) + 0.25;
                end
                ideal2im_ = @(X) ideal2im{min(level, end)}(X) * s(1) + s(2);
                if computeRegions
                    enlarge = options{min(level, end)}.enlarge_region(min(level, end));
                    X = options{min(level, end)}.extract_features(im, ideal2im_(baseLevelPatchPixelCoordinates * enlarge - (enlarge - 1) * mean(baseLevelPatchPixelCoordinates(:,:), 2)));
                    if ~isempty(weights)
                        % Weights
                        % Photometric weights
                        weights = ojw_interp2(im, squeeze(X(1,:,:)), squeeze(X(2,:,:)));
                        weights = zero_mean(weights);
                        weights = sum(sum(weights .* weights, 1), 3);
                        % Distance weights
                        W = squeeze(mean(X, 2));
                        W = W - mean(W, 2);
                        W = sum(W .* W);
                        W = exp(W ./ -mean(W));
                        weights = weights .* W;
                        weights = weights / sum(weights(:));
                    end
                    X = (X - s(2)) * (1 / s(1));
                    options{min(level, end)}.ideal2image = @(X) X * s(1) + s(2);
                else
                    options{min(level, end)}.ideal2image = ideal2im_;
                    X = bsxfun(@plus, baseLevelPatchPixelCoordinates, patchCenter);
                    % Expand the patch for the next scale
                    baseLevelPatchPixelCoordinates = baseLevelPatchPixelCoordinates * 2;
                end
                % Remove out of bounds regions
                Y = options{min(level, end)}.ideal2image(X);
                M = all(Y(1,:,:)>=1 & Y(2,:,:)>=1 & Y(1,:,:)<=size(im, 2) & Y(2,:,:)<=size(im, 1), 2);
                if ~any(M)
                    break;
                end
                X = X(:,:,M);
                if ~isempty(weights)
                    weights = weights(M);
                end
                % Construct the direct alignment optimizer
                this.levels{level} = directAlign(im, options{min(level, end)}.lift_points(X), weights, options{min(level, end)});
            end
        end
        
        function [warp, costs, min_cost] = optimize(this, tgtImPyramid, warp, options)
            if nargin < 4
                options = this.options;
            elseif ~iscell(options)
                options = {options};
            end
            
            % For each pyramid level
            ideal2im = cellfun(@(c) c.ideal2image, options, 'UniformOutput', false);
            s = 0.5 .^ (min(numel(this.levels), numel(tgtImPyramid)) - 1);
            s(2) = 0.5 * (1 - s);
            costs = cell(numel(this.levels), 1);
            for level = numel(this.levels):-1:1
                % Account for scale
                options{min(level, end)}.ideal2image = @(X) ideal2im{min(level, end)}(X) * s(1) + s(2);
                if level <= numel(tgtImPyramid)
                    s(2) = s(2) - 0.25;
                    s = s * 2;
                end
                % Optimize
                [warp, costs{level}] = optimize(this.levels{level}, tgtImPyramid{min(level, end)}, warp, options{min(level, end)});
            end
            if nargout > 2
                min_cost = min(costs{1});
            end
        end
        
        function [warp, costs, min_cost] = optimize_level(this, tgtImPyramid, warp, level, options)
            if nargin < 5
                options = this.options{min(level, end)};
            end
            % Account for scale
            ideal2im = options.ideal2image;
            s = 0.5 .^ (min(level, numel(tgtImPyramid)) - 1);
            s(2) = 0.5 * (1 - s);
            options.ideal2image = @(X) ideal2im(X) * s(1) + s(2);
            % Optimize
            [warp, costs] = optimize(this.levels{level}, tgtImPyramid{min(level, end)}, warp, options);
            if nargout > 2
                min_cost = min(costs);
            end
        end
    end
end

