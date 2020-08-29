%NCC_NORMALIZE_NOGRAD

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function Y = ncc_normalize_nograd(X)
[Y, ~, n] = ncc_normalize(double(X));
if isautodiff(X)
    Y = autodiff(Y, var_indices(X), grad(X) .* shiftdim(n, -1));
end
end