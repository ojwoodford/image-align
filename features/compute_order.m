%COMPUTE_ORDER

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function order = compute_order(X, W, n, radius)
if nargin < 4
    radius = 0;
else
    radius = radius * radius;
end
D = Inf(size(X, 2), 1);
W = W .* W;
[~, i] = max(W);
n = min(n, size(X, 2));
order = zeros(size(X, 2), 1);
D2 = 0.5 * sum(X .* X, 1);
for j = 1:n
    order(i) = j;
    D = min(D, (D2 - X(:,i)' * X)' + D2(i));
    [m, i] = max(D .* W);
    if m == 0 || D(i) < radius
        break;
    end
end
end
