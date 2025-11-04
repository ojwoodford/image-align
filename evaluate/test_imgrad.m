function test_imgrad()
% Mimic code of https://juliaimages.org/ImageFiltering.jl/dev/gradients/

% Construct the test image
x = (1.6 * pi) .* linspace(-1.03125, 1.03125, 132);
[y, x] = ndgrid(x, x);
I = x .^ 2 + y .^ 2;
Ix = 2 * cos(I);
Iy = y .* Ix;
Ix = x .* Ix;
I = sin(I);
direction_true = cat(3, Ix, Iy); 
direction_true = normalize(direction_true(4:end-3,4:end-3,:));

filters = {'prewitt', 'sobel', 'bickley', 'simoncelli', 1};
for f = filters
    [Ix, Iy] = imgrad(I, f{1});
    direction_estimated = cat(3, Ix, Iy);
    direction_estimated = normalize(direction_estimated(4:end-3,4:end-3,:));
    error = direction_true - direction_estimated;
    error = sqrt(sum(error .^ 2, 3));
    fprintf("Using %s results in a mean deviation of %g.\n", f{1}, mean(col(error)));
end
end

function A = normalize(A)
A = A ./ sqrt(max(sum(A .^ 2, 3), 1e-5));
end

