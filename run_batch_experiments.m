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

% Map common filenames to edge map filenames
[~, base, ext] = fileparts(img_name);

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
    edge_map = im2double(imread(edge_path));
    if ndims(edge_map) == 3
        edge_map = mean(edge_map, 3);
    end
    if size(edge_map, 1) ~= target_h || size(edge_map, 2) ~= target_w
        edge_map = imresize(edge_map, [target_h, target_w]);
    end
else
    edge_map = zeros(target_h, target_w);
end

end
