%SELECT_N_POINTS

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function X = select_N_points(im, N)
if nargin < 2
    N = 0;
end
figure(gcf());
clf reset;
imdisp(im);
hold on;
h1 = plot(NaN, NaN, 'r+');
h2 = plot(NaN, NaN, 'go');
last_point = [];
X = zeros(2, 0);
while 1
    [x, y, button] = ginput(1);
    if button == 1
        if N <= 0 && isequal(last_point, [x; y])
            break;
        end
        last_point = [x; y];
        % Add the point
        X(:,end+1) = last_point;
    else
        % Undo the last point
        X = X(:,1:end-1);
    end
    set(h1, 'XData', X(1,:)', 'YData', X(2,:)');
    set(h2, 'XData', X(1,:)', 'YData', X(2,:)');
    if N > 0 && size(X, 2) == N
        break
    end
end
end