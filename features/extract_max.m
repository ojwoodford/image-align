%EXTRACT_MAX

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function X = extract_max(im, region, N, block_len, offsets)
X = extract_dense(im, block_len, region);
if numel(X) > N * 2 
    X = extract_sparse(im, offsets, region, floor(N / size(offsets, 2)));
end
end