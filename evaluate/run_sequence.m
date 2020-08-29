%RUN_SEQUENCE

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function out = run_sequence(sequence, corners, composition, robustifier, gtWarp)

% Ask for corners, if not given
frame = sequence(1);
if isempty(corners)
    % Get the user to select a bounding box by selecting for corners
    corners = select_N_points(frame, 4);
end

% Set the tracker options
options = {{'normalize', 'ncc', 'prefilter', 'none', 'oobv', 128, 'robustifier', robustifier}, ...
           {'normalize', 'ncc', 'prefilter', 'none', 'oobv', 128, 'extract_features', 300*16, 'robustifier', robustifier}, ...
           {'normalize', 'ssd', 'prefilter', 'descriptor_fields', 'oobv', 0}, ...
           {'normalize', 'ssd', 'prefilter', 'census', 'oobv', 0.5}};%, ...
           %{'normalize', 'ssd', 'prefilter', 'locally_normalized', 'robustifier', robustifier, 'oobv', 0}};
warp_types = {8, 8, 6, 4, 2};

% Set up the trackers on the first frame
frame = impyramid(convert2gray(frame), numel(warp_types)-1);
N = sequence.num_frames();
warp = zeros(3, 3, numel(options), N);
time = zeros(numel(options), N);
for a = numel(options):-1:1
    for l = numel(warp_types):-1:1
        options_{l} = direct_options('warp_type', warp_types{l}, options{a}{:}, 'composition', composition, 'max_num_threads', 6);
    end
    t = tic();
    h{a} = directAlignHierarchical(frame, corners, [], options_);
    time(a) = toc(t);
    warp(:,:,a) = eye(3);
end

% For each consecutive frame
pb = ojw_progressbar('Tracking frames...', 1, N);
for b = 2:N
    % Load the frame
    try
        frame = sequence(b);
        assert(~isempty(frame));
    catch
        break;
    end
    frame = impyramid(convert2gray(frame), numel(warp_types)-1);
    if nargin > 5
        % Initialize the warp to the ground truth of the previous frame
        warp = repmat(gtWarp(:,:,b-1), [1 1 numel(h)]);
    end
    % Run each tracker
    for a = numel(h):-1:1
        t = tic();
        warp(:,:,a,b) = optimize(h{a}, frame, warp(:,:,a,b-1));
        time(a,b) = toc(t);
    end
    update(pb, b);
end
out = struct('corners', corners, 'warp', warp, 'time', time); 
end
