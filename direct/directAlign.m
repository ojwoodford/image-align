%DIRECTALIGN

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

classdef directAlign
    properties (SetAccess = private, Hidden = true)
        patches;
        X;
        options;
        debug_info;
        T;
        invT;
        Jinverse;
        Hinverse;
        Pinverse;
        conditioning;
        warp_sz;
        warp_len;
        weights;
    end
    methods
        function this = directAlign(srcIm, patchPixelCoordinates, weights, options)
            % Set the options
            this.options = options;
            this.warp_sz = options.warp_size;
            this.warp_len = prod(this.warp_sz);
            this.weights = weights;
            
            % Filter the reference image
            filteredIm = options.prefilter(srcIm);
            
            % Initialize the patch coordinates
            this.X = patchPixelCoordinates;
            if ~isempty(options.pretransform)
                if isequal(options.pretransform, 'whiten')
                    [this.X, this.T] = whiten_srt(this.X(:,:));
                else
                    this.T = options.pretransform;
                    this.X = reshape(proj(this.T * homg(this.X(:,:))), size(patchPixelCoordinates));
                end
                this.X = reshape(this.X, size(patchPixelCoordinates));
            else
                this.T = eye(this.warp_sz([2 2]));
            end
            this.X = homg(this.X);
            sz = [size(patchPixelCoordinates, 2) size(patchPixelCoordinates, 3) 2];
            this.invT = inv(this.T);
            intensity_params = zeros(options.extra_dims, 1);
            if options.composition <= 0
                % Compute the derivatives
                warp = direct_update([col(eye(this.warp_sz)); intensity_params], autodiff(zeros(options.ndims+options.extra_dims, 1)), options);
                intensity_params = warp(this.warp_len+1:end);
                warp = this.invT * reshape(warp(1:this.warp_len), this.warp_sz);
                warp = warp(end-options.warp_size(1)+1:end,:);
                patchPixelCoordinates = top3(warp * reshape(this.X, size(this.X, 1), []));
                patchPixelCoordinates = proj(patchPixelCoordinates);
            elseif size(this.X, 1) > 3
                warp = options.update(zeros(options.ndims, 1));
                warp = warp(end-options.warp_size(1)+1:end,:);
                patchPixelCoordinates = proj(top3(warp * homg(patchPixelCoordinates(:,:))));
            else
                patchPixelCoordinates = patchPixelCoordinates(:,:);
            end
            % Convert from ideal to image coordinates
            patchPixelCoordinates = reshape(options.ideal2image(patchPixelCoordinates)', sz);
            
            % Sample the patches in the source image
            this.patches = ojw_interp2_alt(filteredIm, patchPixelCoordinates, options.src_interp, NaN, options.max_num_threads);
            assert(~any(isnan(double(this.patches(:)))));
            
            % Apply the inverse generative transform
            this.patches = options.apply_intensity(this.patches, intensity_params);
            
            % Normalize the patches
            this.patches = options.normalize(this.patches);
            assert(~any(isnan(double(this.patches(:)))));
            
            % Concatenate color channels
            this.patches = reshape(permute(this.patches, [1 3 2]), [], size(this.patches, 2));
            
            if options.composition <= 0
                % Extract the derivatives
                this.Jinverse = grad(this.patches);
                this.patches = double(this.patches);
                if options.composition < 0
                    % Construct the inverse Hessian
                    this.Hinverse = tmult(this.Jinverse, this.Jinverse, [0 1]);
                    if isempty(options.robustifier) && (options.composition == -1)
                        % Compute the pseudo inverse
                        J = prepJ(this.Jinverse, options.extra_dims);
                        if options.condition_linear_system
                            % Condition
                            this.conditioning = col(1 ./ sqrt(1 + sum(J .* J, 1)));
                            if issparse(J)
                                J = J * sparse((1:numel(this.conditioning))', (1:numel(this.conditioning))', this.conditioning);
                            else
                                J = J .* this.conditioning';
                            end
                        end
                        if issparse(J)
                            this.Pinverse = ((J' * J) + sparse(1:size(J, 2), 1:size(J, 2), 1e-15)) \ J';
                        else
                            this.Pinverse = pinv(J);
                        end
                    end
                end
            end
            
            % Set the debug info
            this.debug_info = struct('srcIm', srcIm, 'filteredIm', filteredIm, 'ideal2image', options.ideal2image);
            debug(this);
        end
        
        function [c, gn_step] = cost(this, variables, filteredIm, options)
            if nargin < 4
                options = this.options;
            end
            % Autodiff if needed
            compute_hess = (nargout > 1) || isequal(options.robustifier, @irani_weighting) || ~isempty(options.cost_adjustment);
            isad = compute_hess && (options.composition > -1);
            if isad
                variables = direct_update(variables, autodiff(zeros(options.ndims+options.extra_dims, 1)), options);
            end
            isad = isad && (options.extra_dims == 0) && ~options.no_fast_ad;
            
            % Compute the target image locations
            sz = options.warp_size;
            len = prod(sz);
            warp = this.invT * reshape(variables(1:len), sz);
            sz = [2 size(this.X, 2) size(this.X, 3)];
            r = proj(top3(warp * reshape(this.X, size(this.X, 1), [])));
            r = reshape(options.ideal2image(r), sz);
            
            if isad
                % Store the warp Jacobian and compute image Jacobian only
                v = var_indices(r);
                dW = grad(r);
                r = double(r);
                
                % Sample the image
                [r, dI] = ojw_interp2(filteredIm, shiftdim(r(1,:,:), 1), shiftdim(r(2,:,:), 1), options.tgt_interp, options.oobv, options.max_num_threads);
                r = autodiff(r, 1:2, dI);
            else
                % Sample the image
                r = permute(r, [2 3 1]);
                r = ojw_interp2_alt(filteredIm, r, options.tgt_interp, options.oobv, options.max_num_threads);
            end
            
            % Apply any intensity adjustments
            r = options.apply_intensity(r, variables(len+1:end));
            
            % Apply any normalizations
            r = options.normalize(r);
            
            if isad
                % Apply stored warp Jacobian
                dI = grad(r);
                r = autodiff(double(r), v, reshape(sum(dW .* shiftdim(dI, -1), 2), size(dW, 1), size(dW, 3), size(dW, 4), size(dI, 4)));
            end
            
            % Concatenate multiple channels
            r = reshape(permute(r, [1 3 2]), [], size(r, 2));
            
            H = [];
            if compute_hess
                % Compute the gradient
                switch options.composition
                    case 1
                        % Forwards composition
                        J = grad(r);
                    case 0
                        % ESM composition
                        J = grad(r);
                        J = 0.5 * (J + this.Jinverse);
                    case -0.5
                        % Scandaroli Hybrid composition
                        J = grad(r);
                        H = tmult(J, J, [0 1]);
                        H = 0.5 * (H + this.Hinverse);
                        J = 0.5 * (J + this.Jinverse);
                    case -1
                        % Inverse composition
                        J = this.Jinverse;
                        H = this.Hinverse;
                    otherwise
                        error('Composition %g not recognized', options.composition);
                end
                r = double(r);
            end 
                
            if isempty(options.cost_adjustment)
                % Subtract the source patch
                r = r - this.patches;
                err = r;
            else
                % Any special adjustments, like that of ECC
                [err, r] = options.cost_adjustment(r, this.patches, J);
            end
            c = sum(err .* err, 1);
            
            W = 1;
            quit_early = nargout < 2;
            if ~isempty(options.robustifier)
                % Robustify
                if nargout > 1
                    [c, W] = options.robustifier(c, err, J, H);
                else
                    c = options.robustifier(c, err);
                end
            elseif (nargout > 1) && (options.composition == -1)
                % Use pseudo inverse
                gn_step = -(this.Pinverse * r(:));
                if ~isempty(this.conditioning)
                    gn_step = this.conditioning .* gn_step;
                end
                quit_early = true;
            end
            
            % Per block weighting
            if ~isempty(this.weights)
                c = c .* this.weights;
                W = W .* this.weights;
            end
            
            if quit_early
                return;
            end
            
            if options.composition >= 0 || options.condition_linear_system || (size(W, 1) > 1)
                assert(options.composition ~= -0.5, 'Scandaroli hybrid approach not supported with this configuration')
                % Weight
                if ~isequal(W, 1)
                    W = sqrt(W);
                    r = r .* W;
                    J = J .* shiftdim(W, -1);
                end
                
                J = prepJ(J, options.extra_dims);
                if options.condition_linear_system                    
                     % Condition
                    conditioning_ = col(1 ./ sqrt(1 + sum(J .* J, 1)));
                    if issparse(J)
                        J = J * sparse((1:numel(conditioning_))', (1:numel(conditioning_))', conditioning_);
                    else
                        J = J .* conditioning_';
                    end
                end
                if issparse(J)
                    % Solve
                    gn_step = -(((J' * J) + sparse(1:size(J, 2), 1:size(J, 2), 1e-15)) \ (J' * col(r)));
                else
                    % Solve Jacobian system
                    gn_step = -lsqminnorm(J, col(r), 1e-8);
                end
                if options.condition_linear_system
                    gn_step = conditioning_ .* gn_step;
                end
            else
                % Solve Hessian system (normal equations)
                % Compute the gradient
                r = tmult(J, reshape(r, size(r, 1), 1, size(r, 2)));
                
                % Weight
                if ~isequal(W, 1)
                    W = col(W, 3);
                    r = r .* W;
                    H = H .* W;
                end
                
                % Aggregate residuals & compute the step
                r = sum(r, 3);
                H = sum(H, 3);
                gn_step = -lsqminnorm(H, r, 1e-8);
            end
        end
        
        function [warp, varargout] = optimize(this, tgtIm, warp, options)
            if nargin < 4
                options = this.options;
            end
            
            % Filter the target image
            filteredIm = options.prefilter(tgtIm);
            
            % Set the debugging function
            if isempty(options.debug_points)
                outputFunction = options.iteration_func;
            else
                debug(this);
                outputFunction = @(varargin) debug(this, tgtIm, filteredIm, options, varargin{1}, varargin{2});
            end
            
            % Transform the warp
            sz = size(warp);
            warp(1:this.warp_len) = col(this.T * reshape(warp(1:this.warp_len), this.warp_sz) * this.invT);
            
            % Set the optimizer arguments
            args = {@(w) cost(this, w, filteredIm, options), ...
                    @(w, dw) direct_update(w, dw, options), ...
                    outputFunction, options.optimizer_params};
            
            % Do a grid search
            if ~isempty(options.grid_params)
                args{4}(1) = options.grid_refine_iters + 1;
                best_score = Inf;
                start_warp = warp;
                for p = options.grid_params
                    [warp_, costs] = optimizer(direct_update(start_warp, p, options), args{:});
                    costs = min(costs);
                    if costs < best_score
                        best_score = costs;
                        warp = warp_;
                    end
                end
                args{4}(1) = options.optimizer_params(1);
            end      
            
            % Optimize
            [warp, varargout{1:nargout-1}] = optimizer(warp(:), args{:});
            
            % Untransform the warp
            warp(1:this.warp_len) = col(this.invT * reshape(warp(1:this.warp_len), this.warp_sz) * this.T);
            warp = reshape(warp, sz);
        end
        
        function stop = debug(this, tgtIm, filteredIm, options, warp, optimizer_state)
            stop = false;
            persistent handles jet_map;
            if nargin < 4
                handles = [];
                jet_map = jet(256);
                return;
            end
            
            % Call any existing output function
            if ~isempty(options.iteration_func)
                options.iteration_func(warp, optimizer_state);
            end
            
            % Warp and project into the image
            Y = options.ideal2image(proj(top3((this.invT * reshape(warp(1:this.warp_len), this.warp_sz) * this.T) * homg(options.debug_points))))';
            
            % Compute the color from photometric score
            if isfield(optimizer_state, 'resnorm')
                C = optimizer_state.resnorm(:);
            else
                C = [];
            end
            if numel(C) > 1 && size(Y, 1) >= numel(C) && mod(size(Y, 1), numel(C)) == 0
                C = C - min(C);
                C = floor(C * (255.9999 / max(C))) + 1;
                C = repmat(C', size(Y, 1) / numel(C), 1);
            else
                C = repmat(128, size(Y, 1), 1);
            end
            C = jet_map(C(:),:);
            
            if ~isempty(handles)
                % Do a fast update
                try
                    set(handles.plot1, 'XData', Y(:,1), 'YData', Y(:,2));
                    set(handles.plot2, 'XData', Y(:,1), 'YData', Y(:,2), 'FaceVertexCData', C);
                catch me
                    warning(getReport(me, 'basic'));
                    handles = [];
                end
            end
            
            if isempty(handles)
                % Do a full update
                if size(options.debug_points, 2) == 5
                    style = 'g-';
                    edgeColor = 'flat';
                    markerEdgeColor = 'none';
                else
                    style = 'g.';
                    edgeColor = 'none';
                    markerEdgeColor = 'flat';
                end
                figure(gcf());
                clf reset
                axes('Position', [0 0.5 0.5 0.5]);
                imdisp(this.debug_info.srcIm(:,:,1:min(end, 3)), []);
                hold on
                X_ = options.debug_points(:,:);
                if size(X_, 1) > 2
                    X_ = proj(top3(X_));
                end
                X_ = this.debug_info.ideal2image(X_)';
                plot(X_(:,1), X_(:,2), style);
                axes('Position', [0 0 0.5 0.5]);
                imdisp(this.debug_info.filteredIm(:,:,1:min(end, 3)), []);
                hold on
                plot(X_(:,1), X_(:,2), style);
                axes('Position', [0.5 0.5 0.5 0.5]);
                imdisp(tgtIm(:,:,1:min(end, 3)), []);
                hold on
                handles.plot1 = plot(Y(:,1), Y(:,2), style);
                axes('Position', [0.5 0 0.5 0.5]);
                imdisp(filteredIm(:,:,1:min(end, 3)), []);
                hold on
                handles.plot2 = patch('XData', Y(:,1), 'YData', Y(:,2), 'FaceVertexCData', C, 'FaceColor', 'none', 'EdgeColor', edgeColor, 'MarkerEdgeColor', markerEdgeColor, 'Marker', '.');
            end
            drawnow();
        end
    end
end

function [best_x, scores, trajectory] = optimizer(x, cost_func, update_func, output_func, params)
% Params: 1. max_iters,
%         2. func_change_tol,
%         3. grad_tol,
%         4. consecutive_fail_tol
best_x = x;
trajectory = zeros(numel(x), (nargout>2)*params(1));
best_score = realmax('double');
scores = zeros(params(1), 1);
fails = 100;
params(1) = floor(params(1));
res = [];
resnorm = [];
for iter = 1:params(1)
    if nargout > 2
        trajectory(:,iter) = x;
    end
    score = Inf;
    finite = all_finite(x);
    if finite
        if iter < params(1)
            [resnorm, dx] = cost_func(x);
            finite = all_finite(dx);
        else
            resnorm = cost_func(x);
            finite = all_finite(resnorm);
        end
        if finite
            score = sum(resnorm);
        end
    end
    scores(iter) = score; 
    stop = output_func(x, struct('iteration', iter, 'score', score, 'resnorm', resnorm, 'res', res));
    if score < best_score
        best_x = x;
        if (best_score - score) < (best_score * params(2))
            break;
        end
        best_score = score;
        fails = 0;
    else
        fails = fails + 1;
        if fails > params(4)
            break;
        end
    end
    if stop || ~finite || iter >= params(1)
        break;
    end
    if max(abs(dx)) < params(3)
        break;
    end
    x = update_func(x, dx);
end
scores = scores(1:iter);
trajectory = trajectory(:,1:min(iter,end));
end

function variables = direct_update(variables, delta, options)
if ~isempty(options.precondition)
    delta = options.precondition * delta;
end
if options.extra_dims
    len = prod(options.warp_size);
    if options.left_update
        variables = [col(options.update(delta(1:options.ndims)) * reshape(variables(1:len), options.warp_size)); ...
                     col(reshape(variables(len+1:end), options.extra_dims, []) + reshape(delta(options.ndims+1:end), options.extra_dims, []))];
    else
        variables = [col(reshape(variables(1:len), options.warp_size) * options.update(delta(1:options.ndims))); ...
                     col(reshape(variables(len+1:end), options.extra_dims, []) + reshape(delta(options.ndims+1:end), options.extra_dims, []))];
    end
else
    if options.left_update
        variables = reshape(options.update(delta) * reshape(variables, options.warp_size), size(variables));
    else
        variables = reshape(reshape(variables, options.warp_size) * options.update(delta), size(variables));
    end
end
end

function J = prepJ(J, extra_dims)
if extra_dims > 0 && (size(J, 3) > 1)
    % Construct sparse Jacobian
    sz = size(J);
    J = [sparse(J(1:end-extra_dims,:)') ...
        sparse(col(repmat(1:sz(2)*sz(3), extra_dims, 1)), ...
        col(bsxfun(@plus, repmat((0:extra_dims-1)', sz(2), 1), 1:extra_dims:sz(3)*extra_dims)), ...
        col(J(end-extra_dims+1:end,:)))];
else
    J = J(:,:)';
end
end

function X = top3(X)
if size(X, 1) > 3
    X = X(1:3,:);
end
end

function x = all_finite(x)
if issparse(x)
    [~, ~, x] = find(x);
end
x = all(isfinite(x(:)));
end
