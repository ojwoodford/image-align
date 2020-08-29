%NCC_NORMALIZE

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function [X, m, n] = ncc_normalize(X, J)
isad = isautodiff(X);
if isad
    dX = grad(X);
    v = var_indices(X);
    X = double(X);
end
denom = 1 / size(X, 1);
m = sum(X, 1) .* denom;
Xm = X - m;
n = sum(Xm .* Xm);
mask = n == 0;
Xm(:,mask) = 1;
n(mask) = size(X, 1);
n = 1 ./ sqrt(n);
X = Xm .* n;
if isad
    [dX, dXm] = normalize_jacobian(dX, X, denom, n, mask);
    X = autodiff(X, v, dX);
end
if nargin > 1 && nargout > 1
    if isad
        Xm = Xm .* -(n .^ 3);
        Xm = autodiff(n, v, sum(shiftdim(Xm, -1) .* dXm, 2));
    else
        Xm = n;
    end
    m = normalize_jacobian(J, X, denom, Xm, mask);
end
end

function [dX, dXm] = normalize_jacobian(dX, X, denom, n, mask)
dX(:,:,mask) = 0;
dXm = dX - sum(dX, 2) .* denom;
dX = (dXm - shiftdim(X, -1) .* sum(shiftdim(X, -1) .* dXm, 2)) .* shiftdim(n, -1);
end