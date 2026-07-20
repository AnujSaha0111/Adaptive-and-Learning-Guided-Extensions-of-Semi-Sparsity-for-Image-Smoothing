function summary = analyze_results(results_file)
%ANALYZE_RESULTS Compute summary statistics from experiment results.
%   SUMMARY = ANALYZE_RESULTS() reads results/results_table.csv.
%   SUMMARY = ANALYZE_RESULTS(RESULTS_FILE) reads custom file.
%
%   Generates:
%     results/summary_statistics.csv
%       Columns: dataset, sigma, method, mean_psnr, std_psnr,
%                mean_ssim, std_ssim, mean_runtime, std_runtime,
%                num_samples
%
%     results/per_image_statistics.csv
%       Columns: dataset, image, sigma, method, mean_psnr, std_psnr,
%                mean_ssim, std_ssim, num_samples
%
%   Returns SUMMARY as a table.

if nargin < 1
    results_file = fullfile('results', 'results_table.csv');
end

if ~exist(results_file, 'file')
    error('analyze_results:FileNotFound', ...
        'Results file not found: %s', results_file);
end

T = readtable(results_file);

fprintf('Analyzing results from: %s\n', results_file);
fprintf('Total runs: %d\n', size(T, 1));

% Check required columns
required_cols = {'dataset', 'sigma', 'method', 'psnr', 'ssim', 'runtime'};
for i = 1:length(required_cols)
    if ~ismember(required_cols{i}, T.Properties.VariableNames)
        error('analyze_results:MissingColumn', ...
            'Required column "%s" not found in results.', required_cols{i});
    end
end

% --- Summary by (dataset, sigma, method) ---
[groups, group_ids] = findgroups(T(:, {'dataset', 'sigma', 'method'}));

mean_psnr   = splitapply(@(x) mean(x, 'omitnan'), T.psnr, groups);
std_psnr    = splitapply(@(x) std(x, 'omitnan'), T.psnr, groups);
mean_ssim   = splitapply(@(x) mean(x, 'omitnan'), T.ssim, groups);
std_ssim    = splitapply(@(x) std(x, 'omitnan'), T.ssim, groups);
mean_runtime = splitapply(@(x) mean(x, 'omitnan'), T.runtime, groups);
std_runtime  = splitapply(@(x) std(x, 'omitnan'), T.runtime, groups);
num_samples  = splitapply(@(x) length(x), T.psnr, groups);

summary = table();
summary.dataset      = group_ids.dataset;
summary.sigma        = group_ids.sigma;
summary.method       = group_ids.method;
summary.mean_psnr    = mean_psnr;
summary.std_psnr     = std_psnr;
summary.mean_ssim    = mean_ssim;
summary.std_ssim     = std_ssim;
summary.mean_runtime = mean_runtime;
summary.std_runtime  = std_runtime;
summary.num_samples  = num_samples;

summary = sortrows(summary, {'dataset', 'sigma', 'method'});

% Save summary
summary_path = fullfile('results', 'summary_statistics.csv');
writetable(summary, summary_path);
fprintf('Summary saved to: %s\n', summary_path);

% --- Per-image statistics ---
if ismember('image', T.Properties.VariableNames)
    [img_groups, img_ids] = findgroups(T(:, {'dataset', 'image', 'sigma', 'method'}));

    img_mean_psnr = splitapply(@(x) mean(x, 'omitnan'), T.psnr, img_groups);
    img_std_psnr  = splitapply(@(x) std(x, 'omitnan'), T.psnr, img_groups);
    img_mean_ssim = splitapply(@(x) mean(x, 'omitnan'), T.ssim, img_groups);
    img_std_ssim  = splitapply(@(x) std(x, 'omitnan'), T.ssim, img_groups);
    img_n         = splitapply(@(x) length(x), T.psnr, img_groups);

    per_image = table();
    per_image.dataset  = img_ids.dataset;
    per_image.image    = img_ids.image;
    per_image.sigma    = img_ids.sigma;
    per_image.method   = img_ids.method;
    per_image.mean_psnr = img_mean_psnr;
    per_image.std_psnr  = img_std_psnr;
    per_image.mean_ssim = img_mean_ssim;
    per_image.std_ssim  = img_std_ssim;
    per_image.num_samples = img_n;

    per_image = sortrows(per_image, {'dataset', 'image', 'sigma', 'method'});

    per_image_path = fullfile('results', 'per_image_statistics.csv');
    writetable(per_image, per_image_path);
    fprintf('Per-image statistics saved to: %s\n', per_image_path);
end

% Print summary to console
fprintf('\n=== Summary Statistics ===\n');
fprintf('%-12s %-6s %-10s %8s %8s %8s %8s %8s\n', ...
    'Dataset', 'Sigma', 'Method', 'PSNR', 'PSNR-std', 'SSIM', 'SSIM-std', 'N');
fprintf('%s\n', repmat('-', 1, 80));

for i = 1:size(summary, 1)
    fprintf('%-12s %-6d %-10s %8.2f %8.4f %8.4f %8.4f %8d\n', ...
        summary.dataset{i}, summary.sigma(i), summary.method{i}, ...
        summary.mean_psnr(i), summary.std_psnr(i), ...
        summary.mean_ssim(i), summary.std_ssim(i), ...
        summary.num_samples(i));
end

end
