%RENDER_HOMOGRAPHY

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function varargout = render_homography(im1, im2, H)
im1 = imnorm(imwarp(convert2gray(double(im1)), H), 10, 100);
im2 = imnorm(convert2gray(double(im2)), 5, 100);
[varargout{1:nargout}] = sc(cat(3, im1, (im1 + im2) * 0.5, im2 * 0.7 + im1 * 0.3), [-1 1]);
end
