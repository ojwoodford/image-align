%PRECOMPUTED_GRADIENT

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

classdef precomputed_gradient < handle
    properties (SetAccess = private, Hidden = true)
        im;
        im_grad;
    end
    
    methods 
        function this = precomputed_gradient(im)
            this.im = im;
        end
        
        function im = gradim(this)
            if isempty(this.im_grad)
                this.im_grad = single(this.im);
                this.im_grad = cat(3, this.im_grad, imgrad(this.im_grad, 'sobel', 'none'));
            end
            im = this.im_grad;
        end
        
        function varargout = size(this, varargin)
            [varargout{1:nargout}] = size(this.im, varargin{:});
        end
        
        function varargout = numel(this, varargin)
            [varargout{1:nargout}] = size(this.im, varargin{:});
        end
        
        function varargout = disp(this, varargin)
            [varargout{1:nargout}] = disp(this.im, varargin{:});
        end
         
        function c = subsref(this, s)
            assert(strcmp(s.type, '()'));
            c = this.im(s.subs{:});
        end
        
        function varargout = imdisp(this, varargin)
            [varargout{1:nargout}] = imdisp(this.im, varargin{:});
        end
        
        function [c, d] = ojw_interp2(this, x, y, varargin)
            if isautodiff(x) || isautodiff(y)
                c = ojw_interp2(gradim(this), double(x), double(y), varargin{:});
                c = reshape(c, size(c, 1), size(c, 2), size(c, 3)/3, 3);
                v = unique([var_indices(x) var_indices(y)]);
                c = autodiff(c(:,:,:,1), v, bsxfun(@times, grad(x, v), shiftdim(c(:,:,:,2), -1)) + bsxfun(@times, grad(y, v), shiftdim(c(:,:,:,3), -1)));
            elseif nargout > 1
                c = ojw_interp2(gradim(this), x, y, varargin{:});
                c = reshape(c, size(c, 1), size(c, 2), size(c, 3)/3, 3);
                d = permute(c(:,:,:,2:3), [4 1 2 3]);
                c = c(:,:,:,1);
            else
                c = ojw_interp2(this.im, x, y, varargin{:});
            end
        end
    end
end