%RUN_ALL Run all experiments & generate figures
%
%   run_all(base)
%
% Run everything to generate figures and video for the paper
%
%IN:
%   base - path to directory to store the data and results in.

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function run_all(base)
% Make sure all the mex functions are compiled
check_compiled('ojw_interp2');
check_compiled('vl_sift');
check_compiled('vl_ubcmatch');

% Make and go to the directory
qmkdir(base)
temp_cd(base);

% Download the data
fprintf('Downloading missing datasets...\n'); t = tic();
qmkdir('Data');
cd('Data');
download_dataset('graffiti2', '1w07UiATOPfU9GFut9p8ZgxyIg6GzgJ4B');
download_dataset('rifle',     '1y_owhnanHygmQSFBIJyAWU4J-J3g5IdV');
download_dataset('book',      '1j0BTtRRYiglVGoLM1617NMwgyEKIG-Xp');
download_dataset('bear',      '1o9d7dcQ5PEK3e_MddPbOgGqyjMstYz0m');
download_dataset('cat-plane', '13oyRZHjblz3xZK8gCDAwRx26vMTvZN7G');
cd('..');
fprintf('    Done in %gs\n', toc(t));

% Run the quantitative experiments on regions
qmkdir('Results')
cd('Results')
run_quantitative_experiments();

% Run the qualitative experiments on videos
qmkdir('videos');
fprintf('Running video experiments...\n');
videos = {'book',      'book/000.png',       [114 586 680 116; 199 130 465 542]; ...
          'bear',      'bear/0000.png',      [221 618 624 244; 174 153 436 444]; ...
          'cat-plane', 'cat-plane/0001.png', [198 457 458 207; 109 105 407 411]};
maxNumCompThreads(num_cores());
store_frames = false; % Set to true to get uncompressed video frames for publication
for a = 1:size(videos, 1)
    % Inverse compositional
    generate_video(videos{a,:}, store_frames, -1, []);
    % ESM
    generate_video([videos{a,1} '_esm'], videos{a,2:end}, store_frames, 0, @(r, varargin) robust_gm(r, 0.5));
end
fprintf('Done.\n');

% Plot the graphs
plot_all_figures();
end

function generate_video(name, first_frame, corners, store_frames, varargin)
mat_name = sprintf('videos/%s.mat', name);
if ~exist(mat_name, 'file')
    first_frame = sprintf('../Data/%s', first_frame);
    if ~exist(first_frame, 'file')
        warning('%s sequence not found. Skipping evaluation.', name);
        return;
    end
    fprintf('   %s...\n', name); t = tic();
    ims = imstream(first_frame);
    results = run_sequence(ims, corners, varargin{:});
    save(mat_name, '-struct', 'results');
    if store_frames
        dir_name = mat_name(1:end-4);
        qmkdir(dir_name);
        temp_cd(dir_name);
        render_sequence(ims, results);
        write_video(imstream('output.0001.png'), sprintf('../%s.mp4', name));
        cd('../..');
    else
        render_video(ims, results, sprintf('videos/%s.mp4', name));
    end
    fprintf('    Done in %gs\n', toc(t));
end
end

function download_dataset(name, fid)
if ~exist(name, 'dir')
    fprintf('    Downloading %s\n', name);
    try
        tname = tempname();
        base = cd();
        co = onCleanup(@() cleanup(base, tname));
        mkdir(tname);
        cd(tname);
        fname = strcat(name, '.zip');
        download_gdrive_file(fname, fid);
        unzip(fname);
        if exist(name, 'dir')
            movefile(name, base);
        else
            delete(fname);
            cd(base);
            movefile(tname, name);
        end
    catch me
        warning(getReport(me));
    end
end
end

function cleanup(base, tname)
cd(base);
if exist(tname, 'dir')
    rmdir(tname, 's');
end
end

function check_compiled(name)
str = which(name);
if isempty(str)
    error('Function %s not found. Have you run startup to set the path?', name);
end
if isequal(str(end-1:end), '.m')
    try
        compile(name);
    catch
    end
    str = which(name);
    if isequal(str(end-1:end), '.m')
        error('Failed to compile %s. Have you configured C & C++ compilers?', name);
    end
end
end
