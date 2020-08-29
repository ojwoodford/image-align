%VISUALIZE_INTERPOLATION

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function visualize_interpolation(type)

im = repmat(uint8(100), 7, 20);
im(:,11:end) = 200;

x = linspace(7, 15, 1000)';
y = repmat(3.5, 1000, 1);
%z = [x'; y'];

[v, g] = ojw_interp2(im, x, y, type);
v = v - v(1);
g = g(1,:)';
g_ = [0; (v(3:end)-v(1:end-2)) ./ (x(3:end)-x(1:end-2)); 0];
clf reset
subplot(211);
h = plot(x, [v g g_]);
h(3).LineStyle = '--';
legend('Value', 'Analytic gradient', 'Numeric gradient', 'Location', 'best');
title 'Along X direction'

[v, g] = ojw_interp2(im', y, x, type);
v = v - v(1);
g = g(2,:)';
g_ = [0; (v(3:end)-v(1:end-2)) ./ (x(3:end)-x(1:end-2)); 0];
subplot(212);
h = plot(x, [v g g_]);
h(3).LineStyle = '--';
legend('Value', 'Analytic gradient', 'Numeric gradient', 'Location', 'best');
title 'Along Y direction'
end
