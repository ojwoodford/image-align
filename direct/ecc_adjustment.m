%ECC_ADJUSTMENT

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function [err, r] = ecc_adjustment(r, patch, J)
% Compute the cost
wim = r(:);
err = normalize(wim) - normalize(patch(:));

if nargout < 2
    return;
end

J = reshape(J, size(J, 1), []);

% Compute the correction to account for normalization, as per:
% "Parametric Image Alignment Using Enhanced Correlation Coefficient
% Maximization", Evangelidis & Psarakis, PAMI 2008
% Code adapted from that downloaded from: 
% https://www.mathworks.com/matlabcentral/fileexchange/27253-ecc-image-alignment-algorithm-image-registration
Gt = J * patch(:);
Gw = J * wim;
iCxGw = pinv(J') * wim;

% Compute lambda parameter
lambda = (wim' * wim - Gw' * iCxGw) / (patch(:)' * wim - Gt' * iCxGw);

% Subtract the scaled source patch
r = r - patch * lambda;
end