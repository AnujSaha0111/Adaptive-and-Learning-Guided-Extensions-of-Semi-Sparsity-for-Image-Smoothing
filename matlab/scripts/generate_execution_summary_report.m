function generate_execution_summary_report()

setup_paths();

results_file = fullfile('results', 'results_table.csv');
summary_file = fullfile('results', 'summary_statistics.csv');
stats_file   = fullfile('results', 'statistics', 'statistical_tests.csv');
effect_file  = fullfile('results', 'statistics', 'effect_sizes.csv');

if ~exist(results_file, 'file')
    error('generate_execution_summary_report:FileNotFound', ...
        'results_table.csv not found. Run benchmark first.');
end
if ~exist(summary_file, 'file')
    error('generate_execution_summary_report:FileNotFound', ...
        'summary_statistics.csv not found. Run benchmark first.');
end

R = readtable(results_file);
S = readtable(summary_file);

total_experiments = height(R);
datasets   = unique(R.dataset);
sigmas     = unique(R.sigma);
methods    = unique(R.method);

num_nan_psnr = sum(isnan(R.psnr));
num_inf_psnr = sum(isinf(R.psnr));
num_nan_ssim = sum(isnan(R.ssim));
num_inf_ssim = sum(isinf(R.ssim));
num_failed   = num_nan_psnr;

valid = ~isnan(R.psnr);
best_psnr_row = R(valid & R.psnr == max(R.psnr(valid)), :);
best_psnr = best_psnr_row.psnr(1);
best_psnr_img  = best_psnr_row.image{1};
best_psnr_ds   = best_psnr_row.dataset{1};
best_psnr_meth = best_psnr_row.method{1};
best_psnr_sig  = best_psnr_row.sigma(1);

best_ssim_row = R(valid & R.ssim == max(R.ssim(valid)), :);
best_ssim = best_ssim_row.ssim(1);
best_ssim_img  = best_ssim_row.image{1};
best_ssim_ds   = best_ssim_row.dataset{1};
best_ssim_meth = best_ssim_row.method{1};
best_ssim_sig  = best_ssim_row.sigma(1);

method_runtimes = splitapply(@(x) mean(x, 'omitnan'), R.runtime, ...
    findgroups(R.method));
method_names_for_rt = unique(R.method);
[fastest_val, fastest_idx] = min(method_runtimes);
[slowest_val, slowest_idx] = max(method_runtimes);
fastest_method = method_names_for_rt{fastest_idx};
slowest_method = method_names_for_rt{slowest_idx};

a_o_gain_by_ds = zeros(length(datasets), 1);
a_l_gain_by_ds = zeros(length(datasets), 1);

for d = 1:length(datasets)
    ds = datasets{d};
    idx = strcmp(S.dataset, ds);
    sub = S(idx, :);

    a_idx = find(strcmp(sub.method, 'adaptive'), 1);
    o_idx = find(strcmp(sub.method, 'original'), 1);
    l_idx = find(strcmp(sub.method, 'lgss'), 1);

    if ~isempty(a_idx) && ~isempty(o_idx)
        a_o_gain_by_ds(d) = sub.mean_psnr(a_idx) - sub.mean_psnr(o_idx);
    end
    if ~isempty(a_idx) && ~isempty(l_idx)
        a_l_gain_by_ds(d) = sub.mean_psnr(a_idx) - sub.mean_psnr(l_idx);
    end
end

adaptive_vs_original_mean = mean(a_o_gain_by_ds);
adaptive_vs_lgss_mean     = mean(a_l_gain_by_ds);

superior_datasets = {};
worse_datasets    = {};

if exist(stats_file, 'file') && exist(effect_file, 'file')
    ST = readtable(stats_file);
    ES = readtable(effect_file);

    comp_name = 'adaptive_vs_original';
    es_idx = strcmp(ES.Comparison, comp_name) & strcmp(ES.Metric, 'PSNR');
    if any(es_idx)
        es_sub = ES(es_idx, :);
        for d = 1:length(datasets)
            ds = datasets{d};
            ds_es = es_sub(strcmp(es_sub.Dataset, ds), :);
            if ~isempty(ds_es)
                mean_diff = mean(ds_es.Mean_Diff);
                if mean_diff > 0
                    superior_datasets{end+1} = ds;
                else
                    worse_datasets{end+1} = ds;
                end
            end
        end
    end
end

total_runtime = sum(R.runtime, 'omitnan');
total_images  = length(unique(R.image));
total_combos  = length(datasets) * length(sigmas) * 5;

fid = fopen('EXECUTION_SUMMARY.md', 'w');

fprintf(fid, '# Execution Summary\n\n');
fprintf(fid, '**Generated:** %s\n\n', datestr(now));

fprintf(fid, '## Overview\n\n');
fprintf(fid, '| Metric | Value |\n');
fprintf(fid, '|--------|-------|\n');
fprintf(fid, '| Total experiments executed | %d |\n', total_experiments);
fprintf(fid, '| Successful experiments | %d |\n', total_experiments - num_failed);
fprintf(fid, '| Failed experiments | %d |\n', num_failed);
fprintf(fid, '| Datasets | %s |\n', strjoin(datasets, ', '));
fprintf(fid, '| Noise levels (sigma) | %s |\n', num2str(sigmas'));
fprintf(fid, '| Methods | %s |\n', strjoin(methods, ', '));
fprintf(fid, '| Total images | %d |\n', total_images);
fprintf(fid, '| Total runtime | %.1f s (%.1f min, %.2f hours) |\n', ...
    total_runtime, total_runtime/60, total_runtime/3600);
fprintf(fid, '\n');

fprintf(fid, '## Best Performance\n\n');
fprintf(fid, '| Metric | Value | Image | Dataset | Method | Sigma |\n');
fprintf(fid, '|--------|-------|-------|---------|--------|-------|\n');
fprintf(fid, '| Best PSNR | %.2f dB | %s | %s | %s | %d |\n', ...
    best_psnr, best_psnr_img, best_psnr_ds, best_psnr_meth, best_psnr_sig);
fprintf(fid, '| Best SSIM | %.4f | %s | %s | %s | %d |\n', ...
    best_ssim, best_ssim_img, best_ssim_ds, best_ssim_meth, best_ssim_sig);
fprintf(fid, '\n');

fprintf(fid, '## Runtime Rankings\n\n');
fprintf(fid, '| Rank | Method | Mean Runtime (s) |\n');
fprintf(fid, '|------|--------|------------------|\n');
[sorted_rt, sort_idx] = sort(method_runtimes);
for i = 1:length(sort_idx)
    fprintf(fid, '| %d | %s | %.4f |\n', ...
        i, method_names_for_rt{sort_idx(i)}, sorted_rt(i));
end
fprintf(fid, '\n');
fprintf(fid, '- **Fastest method:** %s (%.4f s)\n', fastest_method, fastest_val);
fprintf(fid, '- **Slowest method:** %s (%.4f s)\n\n', slowest_method, slowest_val);

fprintf(fid, '## Adaptive Method Gains\n\n');
fprintf(fid, '### Adaptive vs Original (mean PSNR gain across datasets)\n\n');
fprintf(fid, '| Dataset | Gain (dB) |\n');
fprintf(fid, '|---------|----------:|\n');
for d = 1:length(datasets)
    fprintf(fid, '| %s | %+.2f |\n', datasets{d}, a_o_gain_by_ds(d));
end
fprintf(fid, '| **Overall mean** | **%+.2f** |\n', adaptive_vs_original_mean);
fprintf(fid, '\n');

fprintf(fid, '### Adaptive vs LGSS (mean PSNR gain across datasets)\n\n');
fprintf(fid, '| Dataset | Gain (dB) |\n');
fprintf(fid, '|---------|----------:|\n');
for d = 1:length(datasets)
    fprintf(fid, '| %s | %+.2f |\n', datasets{d}, a_l_gain_by_ds(d));
end
fprintf(fid, '| **Overall mean** | **%+.2f** |\n', adaptive_vs_lgss_mean);
fprintf(fid, '\n');

fprintf(fid, '### Statistical Superiority\n\n');
if ~isempty(superior_datasets)
    fprintf(fid, '- Datasets where Adaptive is statistically superior to Original: **%s**\n', ...
        strjoin(superior_datasets, ', '));
else
    fprintf(fid, '- Datasets where Adaptive is statistically superior to Original: **None detected**\n');
end
if ~isempty(worse_datasets)
    fprintf(fid, '- Datasets where Adaptive performs worse: **%s**\n', ...
        strjoin(worse_datasets, ', '));
else
    fprintf(fid, '- Datasets where Adaptive performs worse: **None detected**\n');
end
fprintf(fid, '\n');

fprintf(fid, '## Data Integrity\n\n');
fprintf(fid, '| Check | Result |\n');
fprintf(fid, '|-------|--------|\n');
fprintf(fid, '| NaN in PSNR | %s |\n', conditional_str(num_nan_psnr == 0, 'None', sprintf('%d found', num_nan_psnr)));
fprintf(fid, '| Inf in PSNR | %s |\n', conditional_str(num_inf_psnr == 0, 'None', sprintf('%d found', num_inf_psnr)));
fprintf(fid, '| NaN in SSIM | %s |\n', conditional_str(num_nan_ssim == 0, 'None', sprintf('%d found', num_nan_ssim)));
fprintf(fid, '| Inf in SSIM | %s |\n', conditional_str(num_inf_ssim == 0, 'None', sprintf('%d found', num_inf_ssim)));
fprintf(fid, '| Runtime values present | %s |\n', conditional_str(all(valid), 'Yes', 'No'));
fprintf(fid, '\n');

fprintf(fid, '## Expected Methods Check\n\n');
expected_methods = {'original', 'adaptive', 'lgss', 'bilateral', 'guided', 'tv', 'l0'};
for i = 1:length(expected_methods)
    present = any(strcmp(methods, expected_methods{i}));
    fprintf(fid, '| %s | %s |\n', expected_methods{i}, conditional_str(present, 'PRESENT', 'MISSING'));
end
fprintf(fid, '\n');

fprintf(fid, '## Expected Datasets Check\n\n');
expected_datasets = {'custom', 'Set12', 'BSD68', 'Kodak24'};
for i = 1:length(expected_datasets)
    present = any(strcmp(datasets, expected_datasets{i}));
    fprintf(fid, '| %s | %s |\n', expected_datasets{i}, conditional_str(present, 'PRESENT', 'MISSING'));
end
fprintf(fid, '\n');

fprintf(fid, '## Expected Noise Levels Check\n\n');
expected_sigmas = [10, 20, 25, 50];
for i = 1:length(expected_sigmas)
    present = any(sigmas == expected_sigmas(i));
    fprintf(fid, '| sigma=%d | %s |\n', expected_sigmas(i), conditional_str(present, 'PRESENT', 'MISSING'));
end
fprintf(fid, '\n');

fprintf(fid, '## Warnings\n\n');
warnings_found = {};
if num_nan_psnr > 0
    warnings_found{end+1} = sprintf('%d NaN values in PSNR column', num_nan_psnr);
end
if num_inf_psnr > 0
    warnings_found{end+1} = sprintf('%d Inf values in PSNR column', num_inf_psnr);
end
if any(strcmp(methods, 'tv'))
    tv_summary = S(strcmp(S.method, 'tv'), :);
    if any(tv_summary.mean_psnr < 0)
        warnings_found{end+1} = 'TV method has negative PSNR values (expected for overly aggressive smoothing)';
    end
end
if isempty(warnings_found)
    fprintf(fid, '- None.\n\n');
else
    for w = 1:length(warnings_found)
        fprintf(fid, '- %s\n', warnings_found{w});
    end
    fprintf(fid, '\n');
end

fprintf(fid, '---\n');
fprintf(fid, '*Generated by `generate_execution_summary_report.m`*\n');

fclose(fid);
fprintf('EXECUTION_SUMMARY.md written.\n');

end

function s = conditional_str(condition, true_str, false_str)
if condition
    s = true_str;
else
    s = false_str;
end
end
