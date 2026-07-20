function results_table = run_batch_experiments(cfg)
%RUN_BATCH_EXPERIMENTS Run batch denoising experiments.
%   RESULTS_TABLE = RUN_BATCH_EXPERIMENTS() runs with default config.
%   RESULTS_TABLE = RUN_BATCH_EXPERIMENTS(CFG) uses custom config.
%
%   Returns a table with columns:
%     dataset, image, sigma, realization, method, psnr, ssim, runtime
%
%   Experiments:
%   - Iterates over all datasets, images, noise levels, realizations
%   - Runs original, adaptive, and LGSS methods
%   - Computes PSNR and SSIM with 12-pixel border cropping
%   - Measures runtime via benchmark_runtime
%   - Saves results to results/results_table.csv

if nargin < 1
    cfg = experiment_config();
end

% Prepare results storage
results = {};
col_names = {'dataset', 'image', 'sigma', 'realization', 'method', 'psnr', 'ssim', 'runtime'};
num_cols = length(col_names);

% Ensure output directories exist
if ~exist(cfg.output_dir, 'dir')
    mkdir(cfg.output_dir);
end

% Resolve edge maps directory
edge_dir = fullfile(pwd, 'edges');

% Main experiment loop
for d = 1:length(cfg.datasets)

    dataset_name = cfg.datasets{d};
    fprintf('\n========================================\n');
    fprintf('Dataset: %s\n', dataset_name);
    fprintf('========================================\n');

    % Load dataset
    images = load_dataset(dataset_name);

    for i = 1:length(images)

        img_struct = images(i);
        if isempty(img_struct.image)
            fprintf('  Skipping %s (not found)\n', img_struct.name);
            continue;
        end

        clean = img_struct.image;
        [img_base, ~, ~] = fileparts(img_struct.name);

        fprintf('  Image: %s (%d x %d)\n', img_struct.name, ...
            img_struct.height, img_struct.width);

        for s = 1:length(cfg.noise_levels)

            sigma = cfg.noise_levels(s);
            fprintf('    Sigma = %d\n', sigma);

            % Create per-sigma output directory
            sigma_dir = fullfile(cfg.output_dir, dataset_name, ...
                sprintf('sigma_%d', sigma));

            for r = 1:cfg.num_realizations

                seed = cfg.base_seed + (r - 1);
                fprintf('      Realization %d/%d (seed=%d)\n', ...
                    r, cfg.num_realizations, seed);

                % Create realization output directory
                real_dir = fullfile(sigma_dir, sprintf('real_%d', r));
                if cfg.save_images && ~exist(real_dir, 'dir')
                    mkdir(real_dir);
                end

                % Generate noisy image
                noisy = add_gaussian_noise(clean, sigma, seed);

                % Load edge map for LGSS (try once per image)
                if any(strcmp(cfg.methods, 'lgss'))
                    edge_map = load_edge_map(edge_dir, img_struct.name, ...
                        size(clean, 1), size(clean, 2));
                else
                    edge_map = [];
                end

                for m = 1:length(cfg.methods)

                    method = cfg.methods{m};
                    fprintf('        Method: %s ... ', method);

                    % Run method
                    switch method
                        case 'original'
                            func = @denoise_original;
                        case 'adaptive'
                            func = @denoise_adaptive;
                        case 'lgss'
                            func = @(x) denoise_lgss(x, edge_map);
                        case 'bilateral'
                            func = @(x) denoise_bilateral(x);
                        case 'guided'
                            func = @(x) denoise_guided(x);
                        case 'tv'
                            func = @(x) denoise_tv(x);
                        case 'l0'
                            func = @(x) denoise_l0(x);
                        otherwise
                            error('Unknown method: %s', method);
                    end

                    [denoised, runtime] = benchmark_runtime(func, noisy);

                    % Compute metrics
                    psnr_val = compute_psnr(clean, denoised);
                    if cfg.compute_ssim
                        ssim_val = compute_ssim(clean, denoised);
                    else
                        ssim_val = NaN;
                    end
                    fprintf('PSNR = %.2f dB, SSIM = %.4f, runtime = %.2f s\n', ...
                        psnr_val, ssim_val, runtime);

                    % Store result
                    row = {dataset_name, img_struct.name, sigma, r, ...
                           method, psnr_val, ssim_val, runtime};
                    results = [results; row]; %#ok<AGROW>

                    % Save output image
                    if cfg.save_images
                        out_fname = fullfile(real_dir, ...
                            sprintf('%s_%s.%s', method, img_base, cfg.image_ext));
                        imwrite(denoised, out_fname);
                    end

                end % methods

            end % realizations

        end % noise levels

    end % images

end % datasets

% Convert to table
results_table = cell2table(results, 'VariableNames', col_names);

% Save CSV
csv_path = fullfile(cfg.output_dir, 'results_table.csv');
writetable(results_table, csv_path);
fprintf('\nResults saved to: %s\n', csv_path);

% Print summary
fprintf('\n========================================\n');
fprintf('Experiment Summary\n');
fprintf('========================================\n');
fprintf('Datasets:       %s\n', strjoin(cfg.datasets, ', '));
fprintf('Noise levels:   %s\n', num2str(cfg.noise_levels));
fprintf('Realizations:   %d\n', cfg.num_realizations);
fprintf('Methods:        %s\n', strjoin(cfg.methods, ', '));
fprintf('Total runs:     %d\n', size(results_table, 1));
fprintf('========================================\n');

end

% -------------------------------------------------------------------------
function edge_map = load_edge_map(edge_dir, img_name, target_h, target_w)
%LOAD_EDGE_MAP Load or create edge map for a given image.
%   If a precomputed edge map exists, load it.
%   Otherwise, generate one using Canny edge detection and cache it.

[~, base, ext] = fileparts(img_name);

% Map known precomputed edge map filenames
switch lower(base)
    case 'lena'
        edge_fname = 'edge_map_Lena.png';
    case 'barbara'
        edge_fname = 'edge_map_Barbara.png';
    case 'cameraman'
        edge_fname = 'edge_map_Cameraman.png';
    case 'strip_gt'
        edge_fname = 'edge_map_strip_noise.png';
    otherwise
        edge_fname = sprintf('edge_map_%s.png', base);
end

edge_path = fullfile(edge_dir, edge_fname);

if exist(edge_path, 'file')
    % Load precomputed edge map
    edge_map = im2double(imread(edge_path));
    if ndims(edge_map) == 3
        edge_map = mean(edge_map, 3);
    end
    if size(edge_map, 1) ~= target_h || size(edge_map, 2) ~= target_w
        edge_map = imresize(edge_map, [target_h, target_w]);
    end
else
    % Auto-generate edge map using Canny and cache it
    edge_map = generate_canny_edge_map(img_name, target_h, target_w);

    % Cache to disk for future runs
    if ~exist(edge_dir, 'dir')
        mkdir(edge_dir);
    end
    imwrite(edge_map, edge_path);
end

end

% -------------------------------------------------------------------------
function edge_map = generate_canny_edge_map(img_name, target_h, target_w)
%GENERATE_CANNY_EDGE_MAP Create a Canny edge map for a benchmark image.
%   Returns a soft edge confidence map in [0, 1].

% Locate the image in datasets/
[~, base, ext] = fileparts(img_name);

% Search common dataset directories
dataset_dirs = {'Set12', 'BSD68', 'Kodak24', 'custom'};
img_path = '';
for d = 1:length(dataset_dirs)
    candidate = fullfile(pwd, 'datasets', dataset_dirs{d}, img_name);
    if exist(candidate, 'file')
        img_path = candidate;
        break;
    end
end

% Fallback: try repo root
if isempty(img_path)
    candidate = fullfile(pwd, img_name);
    if exist(candidate, 'file')
        img_path = candidate;
    end
end

if isempty(img_path)
    warning('load_edge_map:ImageNotFound', ...
        'Cannot locate %s for edge map generation. Using zeros.', img_name);
    edge_map = zeros(target_h, target_w);
    return;
end

% Read and convert to grayscale
img = im2double(imread(img_path));
if size(img, 3) == 3
    img = rgb2gray(img);
end

% Apply Gaussian smoothing before Canny to reduce noise-induced edges
img_smooth = imgaussfilt(img, 1.0);

% Run Canny edge detector with automatic thresholding
edge_binary = edge(img_smooth, 'Canny');

% Convert binary edges to soft confidence map via distance transform
% Pixels closer to an edge get higher confidence
D = bwdist(edge_binary);

% Normalize distance to [0, 1] with exponential decay
% sigma_scale controls how wide the edge influence is (in pixels)
sigma_scale = 3.0;
edge_map = exp(-D / sigma_scale);

% Clamp to [0, 1]
edge_map = min(max(edge_map, 0), 1);

% Resize if needed
if size(edge_map, 1) ~= target_h || size(edge_map, 2) ~= target_w
    edge_map = imresize(edge_map, [target_h, target_w]);
end

end
