%PLOT_CDF

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function h = plot_cdf(x, varargin)
x = [zeros(1, size(x, 2)); sort(x)];
y = linspace(0, 1, size(x, 1))';
if nargin > 1 && isscalar(varargin{1}) && isnumeric(varargin{1})
    x = dpsimplify([x y], varargin{1});
    y = x(:,2);
    x = x(:,1);
    varargin = varargin(2:end);
end
h = plot(x, y, varargin{:});
end