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
mkdir_(base)
temp_cd(base);

% Download the data
fprintf('Downloading missing datasets...\n'); t = tic();
mkdir_('Data');
cd('Data');
download_dataset('graffiti2', 'zip', 'https://drive.google.com/uc?export=download&id=1w07UiATOPfU9GFut9p8ZgxyIg6GzgJ4B');
download_dataset('rifle',     'zip', 'https://drive.google.com/uc?export=download&id=1y_owhnanHygmQSFBIJyAWU4J-J3g5IdV');
download_dataset('book',      'tgz', 'https://drive.google.com/uc?export=download&id=0B9p0qMkQ6VAUVW8yU2hKWnZiN1k');
download_dataset('bear',      'tgz', 'https://drive.google.com/uc?export=download&id=0B9p0qMkQ6VAUdkd2aW9uN183bEk');
download_dataset('cat-plane', 'tgz', 'https://drive.google.com/uc?export=download&id=0B9p0qMkQ6VAURzJjTFFoRUVSblk');
cd('..');
fprintf('    Done in %gs\n', toc(t));

% Run the quantitative experiments on regions
mkdir_('Results')
cd('Results')
if ~exist('quantitative.mat', 'file')
    fprintf('Running quantitative experiments...\n'); t = tic();
    results = recurse_subdirs(@quantitative, '../Data/graffiti2');
    fprintf('    Done in %gs\n', toc(t));
    
    % Combine and store the results
    results = stack_results(results{~cellfun(@isempty, results)});
    save quantitative.mat results
end

% Run the qualitative experiments on videos
mkdir_('videos');
fprintf('Running video experiments...\n');
videos = {'book',      'book/000.pgm',           [114 586 680 116; 199 130 465 542]; ...
          'bear',      'bear/0000.pgm',          [221 618 624 244; 174 153 436 444]; ...
          'cat-plane', 'cat-plane/00000001.ppm', [198 457 458 207; 109 105 407 411]};
maxNumCompThreads(num_cores());
for a = 1:size(videos, 1)
    % Inverse compositional
    generate_video(videos{a,:}, -1, []);
    % ESM
    generate_video([videos{a,1} '_esm'], videos{a,2:end}, 0, @(r, varargin) robust_gm(r, 0.5));
end
fprintf('Done.\n');

% Plot the graphs
plot_all_figures();
end

function generate_video(name, first_frame, corners, varargin)
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
    dir_name = mat_name(1:end-4);
    mkdir_(dir_name);
    temp_cd(dir_name);
    render_sequence(ims, results);
    write_video(imstream('output.0001.png'), sprintf('../%s.mp4', name));
    cd('../..');
    fprintf('    Done in %gs\n', toc(t));
end
end

function mkdir_(name)
if ~exist(name, 'dir')
    mkdir(name);
end
end

function download_dataset(name, varargin)
if ~exist(name, 'dir')
    fprintf('    Downloading %s\n', name);
    download_zip(name, varargin{:});
end
end

function results = quantitative(base)
% Compute the global data
try
    data = load_sequence_data(base);
catch
    % No images here. Just exit.
    results = {};
    return;
end

% Create the result directory for this sequence
[~, name] = fileparts(base);
mkdir_(name);
temp_cd(name);

if ~exist('results.mat', 'file')
    fprintf(' Computing results for sequence %s...', name); t = tic();
    % Run the experiments
    run_quantitative_experiments(data);
    
    % Collate the results
    results = get_quantitative_results(data);
    save results.mat results
    fprintf(' Done in %gs.\n', toc(t));
else
    results = load_field('results.mat', 'results');
end
end

function results = stack_results(varargin)
results = varargin{1};
I = find(~cellfun(@isempty, results));
for a = 2:nargin
    results(I) = cellfun(@(c, d) cat(6, c, d), results(I), varargin{a}(I), 'UniformOutput', false);
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
