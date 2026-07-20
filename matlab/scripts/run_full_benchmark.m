%RUN_FULL_BENCHMARK Execute the complete denoising benchmark.
%   This script configures and runs the full experimental pipeline across
%   all datasets, noise levels, realizations, and methods, then produces
%   summary statistics and plots.
%
%   Datasets:    custom, Set12, BSD68, Kodak24
%   Noise:       sigma = [10, 20, 25, 50]
%   Realizations: 5 per image per sigma
%   Methods:     original, adaptive, lgss, bilateral, guided, tv, l0
%
%   Estimated runtime: 12-24 hours depending on hardware.
%
%   Outputs:
%     results/results_table.csv        - per-experiment metrics
%     results/summary_statistics.csv   - aggregated statistics
%     results/per_image_statistics.csv - per-image aggregates
%     results/figures/                 - PSNR/SSIM/runtime plots
%
%   See also experiment_config, run_batch_experiments, analyze_results,
%            generate_result_plots.

fprintf('========================================\n');
fprintf('Full Benchmark Configuration\n');
fprintf('========================================\n');

% ------------------------------------------------------------------------
% Configuration
% ------------------------------------------------------------------------
cfg = experiment_config();

cfg.datasets         = {'custom', 'Set12', 'BSD68', 'Kodak24'};
cfg.noise_levels     = [10, 20, 25, 50];
cfg.num_realizations = 5;
cfg.methods          = {'original', 'adaptive', 'lgss', ...
                        'bilateral', 'guided', 'tv', 'l0'};
cfg.compute_ssim     = true;
cfg.compute_runtime  = true;
cfg.save_images      = false;
cfg.base_seed        = 2026;
cfg.output_dir       = 'results';

% ------------------------------------------------------------------------
fprintf('Datasets:       %s\n', strjoin(cfg.datasets, ', '));
fprintf('Noise levels:   ');
fprintf('%d ', cfg.noise_levels);
fprintf('\n');
fprintf('Realizations:   %d\n', cfg.num_realizations);
fprintf('Methods:        %s\n', strjoin(cfg.methods, ', '));

total_images = 0;
for d = 1:length(cfg.datasets)
    try
        imgs = load_dataset(cfg.datasets{d});
        n = sum(~cellfun(@isempty, {imgs.image}));
        total_images = total_images + n;
        fprintf('  %-10s %d images\n', cfg.datasets{d}, n);
    catch ME
        fprintf('  %-10s ERROR: %s\n', cfg.datasets{d}, ME.message);
    end
end

total_runs = total_images * length(cfg.noise_levels) * ...
             cfg.num_realizations * length(cfg.methods);
fprintf('\nTotal images:   %d\n', total_images);
fprintf('Total runs:     %d\n', total_runs);
fprintf('========================================\n');

% ------------------------------------------------------------------------
% Step 1: Run batch experiments
% ------------------------------------------------------------------------
fprintf('\n>>> Step 1/3: Running batch experiments ...\n');
fprintf('>>> This will take a long time (12-24 hours).\n\n');

results_table = run_batch_experiments(cfg);

fprintf('\n>>> Step 1 complete: %d results saved.\n', height(results_table));

% ------------------------------------------------------------------------
% Step 2: Analyze results
% ------------------------------------------------------------------------
fprintf('\n>>> Step 2/3: Analyzing results ...\n');

summary = analyze_results();

fprintf('>>> Step 2 complete.\n');

% ------------------------------------------------------------------------
% Step 3: Generate plots
% ------------------------------------------------------------------------
fprintf('\n>>> Step 3/3: Generating plots ...\n');

generate_result_plots();

fprintf('>>> Step 3 complete.\n');

% ------------------------------------------------------------------------
% Done
% ------------------------------------------------------------------------
fprintf('\n========================================\n');
fprintf('Full benchmark complete.\n');
fprintf('========================================\n');
fprintf('\nOutput files:\n');
fprintf('  %s\n', fullfile(cfg.output_dir, 'results_table.csv'));
fprintf('  %s\n', fullfile(cfg.output_dir, 'summary_statistics.csv'));
fprintf('  %s\n', fullfile(cfg.output_dir, 'per_image_statistics.csv'));
fprintf('  %s\n', fullfile(cfg.output_dir, 'figures', '*.png'));
fprintf('\nRun FULL_EXPERIMENT_REPORT.md generation after completion.\n');

end
