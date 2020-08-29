%IMWARP

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function im = imwarp(im, warp)
X = proj(warp \ homg(flipud(ndgrid_cols(1:size(im, 1), 1:size(im, 2)))));
im = reshape(ojw_interp2(im, X(1,:), X(2,:), 'l', cast(0, class(im))), size(im));
end
