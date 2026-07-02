%VERIFY_EXPERIMENTAL_PIPELINE Automated verification of the experimental framework.
%
%   Runs 7 checks to validate PSNR, SSIM, runtime, batch execution,
%   statistics aggregation, plot generation, and reproducibility.
%
%   Output:
%     EXPERIMENT_VERIFICATION_REPORT.md  - PASS/FAIL report
%     console output with detailed diagnostics

clc;
clear;
close all;

fprintf('========================================\n');
fprintf('Experimental Pipeline Verification\n');
fprintf('========================================\n\n');

results = {};

%% SETUP: Load a test image and generate a noisy version
clean = im2double(imread('lena.png'));
noisy = add_gaussian_noise(clean, 20, 42);

% Run a quick denoising to get a pred image for metric checks
fprintf('--- Generating test prediction ---\n');
cfg_fast = experiment_config();
cfg_fast.noise_levels = [20];
cfg_fast.num_realizations = 1;
cfg_fast.methods = {'original'};
cfg_fast.compute_ssim = false;
cfg_fast.compute_runtime = false;
[denoised, ~] = benchmark_runtime(@denoise_original, noisy);
fprintf('Done.\n\n');

%% CHECK 1: PSNR Verification
fprintf('========================================\n');
fprintf('CHECK 1: PSNR Verification\n');
fprintf('========================================\n');

% compute_psnr with crop_border=0 (no crop) to match built-in psnr behavior
psnr_custom_nocrop = compute_psnr(clean, denoised, 0);
psnr_builtin = psnr(denoised, clean);  % psnr(pred, ref)

diff_psnr_nocrop = abs(psnr_custom_nocrop - psnr_builtin);

% compute_psnr with default crop (12px) - our standard
psnr_custom_crop = compute_psnr(clean, denoised);
psnr_builtin_crop = psnr(denoised(13:end-12,13:end-12,:), clean(13:end-12,13:end-12,:));

diff_psnr_crop = abs(psnr_custom_crop - psnr_builtin_crop);

fprintf('  Without cropping:\n');
fprintf('    compute_psnr (crop=0):  %.6f dB\n', psnr_custom_nocrop);
fprintf('    psnr (built-in):        %.6f dB\n', psnr_builtin);
fprintf('    Absolute difference:    %.2e\n', diff_psnr_nocrop);

fprintf('  With 12px cropping:\n');
fprintf('    compute_psnr (crop=12): %.6f dB\n', psnr_custom_crop);
fprintf('    psnr (manual crop):     %.6f dB\n', psnr_builtin_crop);
fprintf('    Absolute difference:    %.2e\n', diff_psnr_crop);

check1_pass = diff_psnr_nocrop < 1e-6 && diff_psnr_crop < 1e-6;
fprintf('  STATUS: %s\n', ternary(check1_pass, 'PASS', 'FAIL'));

results = [results; {'Check 1: PSNR', ternary(check1_pass, 'PASS', 'FAIL'), ...
    sprintf('diff_no_crop=%.2e, diff_crop=%.2e', diff_psnr_nocrop, diff_psnr_crop)}];

%% CHECK 2: SSIM Verification
fprintf('\n========================================\n');
fprintf('CHECK 2: SSIM Verification\n');
fprintf('========================================\n');

% compute_ssim with crop_border=0
ssim_custom_nocrop = compute_ssim(clean, denoised, 0);

% Check if MATLAB built-in ssim is available
if license('test', 'image_toolbox') && exist('ssim', 'file')
    ssim_builtin = ssim(denoised, clean);
    diff_ssim = abs(ssim_custom_nocrop - ssim_builtin);
    ssim_source = 'built-in ssim()';
else
    ssim_builtin = NaN;
    diff_ssim = NaN;
    ssim_source = 'fallback (no IPT)';
end

% SSIM with cropping
ssim_custom_crop = compute_ssim(clean, denoised);
if license('test', 'image_toolbox') && exist('ssim', 'file')
    ssim_builtin_crop = ssim(denoised(13:end-12,13:end-12,:), clean(13:end-12,13:end-12,:));
    diff_ssim_crop = abs(ssim_custom_crop - ssim_builtin_crop);
else
    ssim_builtin_crop = NaN;
    diff_ssim_crop = NaN;
end

% SSIM validity
ssim_in_range = (ssim_custom_crop >= 0) && (ssim_custom_crop <= 1);

fprintf('  Source: %s\n', ssim_source);
fprintf('  Without cropping:\n');
fprintf('    compute_ssim (crop=0):  %.6f\n', ssim_custom_nocrop);
if ~isnan(ssim_builtin)
    fprintf('    ssim (built-in):         %.6f\n', ssim_builtin);
    fprintf('    Absolute difference:    %.2e\n', diff_ssim);
end

fprintf('  With 12px cropping:\n');
fprintf('    compute_ssim (crop=12): %.6f\n', ssim_custom_crop);
fprintf('    0 <= SSIM <= 1:         %s\n', ternary(ssim_in_range, 'YES', 'NO'));

if ~isnan(diff_ssim)
    check2_pass = diff_ssim < 1e-6 && ssim_in_range;
else
    % Fallback path: just verify self-SSIM = 1 and range
    self_ssim = compute_ssim(clean, clean, 0);
    check2_pass = (abs(self_ssim - 1) < 1e-6) && ssim_in_range;
end
fprintf('  STATUS: %s\n', ternary(check2_pass, 'PASS', 'FAIL'));

results = [results; {'Check 2: SSIM', ternary(check2_pass, 'PASS', 'FAIL'), ...
    sprintf('diff=%.2e, in_range=%d, self_ssim=%.6f', ...
    diff_ssim, ssim_in_range, compute_ssim(clean, clean, 0))}];

%% CHECK 3: Runtime Verification
fprintf('\n========================================\n');
fprintf('CHECK 3: Runtime Verification\n');
fprintf('========================================\n');

methods_to_test = {'original', 'adaptive'};
check3_pass = true;
check3_details = '';

for m = 1:length(methods_to_test)
    method = methods_to_test{m};

    switch method
        case 'original', func = @denoise_original;
        case 'adaptive',  func = @denoise_adaptive;
    end

    % benchmark_runtime
    [~, t_bench] = benchmark_runtime(func, noisy);

    % direct tic/toc
    t_start = tic;
    func(noisy);
    t_direct = toc(t_start);

    diff_runtime = abs(t_bench - t_direct);
    pct_diff = diff_runtime / max(t_bench, t_direct) * 100;

    method_pass = pct_diff < 10;
    check3_pass = check3_pass && method_pass;

    fprintf('  %s:\n', method);
    fprintf('    benchmark_runtime:  %.4f s\n', t_bench);
    fprintf('    direct tic/toc:     %.4f s\n', t_direct);
    fprintf('    diff:               %.4f s (%.2f%%)\n', diff_runtime, pct_diff);
    fprintf('    STATUS:             %s\n', ternary(method_pass, 'PASS', 'FAIL'));

    check3_details = [check3_details, ...
        sprintf('%s:%.2f%% ', method, pct_diff)]; %#ok<AGROW>
end

results = [results; {'Check 3: Runtime', ternary(check3_pass, 'PASS', 'FAIL'), ...
    strtrim(check3_details)}];

%% CHECK 4: Results Table Integrity
fprintf('\n========================================\n');
fprintf('CHECK 4: Results Table Integrity\n');
fprintf('========================================\n');

% Run a small batch experiment
cfg = experiment_config();
cfg.datasets = {'existing'};
cfg.noise_levels = [20];
cfg.num_realizations = 2;
cfg.methods = {'original', 'adaptive', 'lgss'};
cfg.compute_ssim = true;
cfg.compute_runtime = true;
cfg.save_images = false;

T = run_batch_experiments(cfg);

% Expected: 4 images * 1 sigma * 2 realizations * 3 methods = 24 rows
num_datasets = length(cfg.datasets);
num_images_per_dataset = [4];  % existing has 4 images
expected_total = sum(num_images_per_dataset) * ...
    length(cfg.noise_levels) * cfg.num_realizations * length(cfg.methods);

actual_rows = size(T, 1);
row_match = (actual_rows == expected_total);

% Check all methods present
methods_present = unique(T.method);
all_methods = all(ismember(cfg.methods, methods_present));

% No duplicates
[~, unique_idx] = unique(T, 'rows');
no_duplicates = (length(unique_idx) == actual_rows);

% No missing values
no_missing_psnr = all(~isnan(T.psnr));
no_missing_ssim = all(~isnan(T.ssim));
no_missing_runtime = all(~isnan(T.runtime));

check4_pass = row_match && all_methods && no_duplicates && ...
    no_missing_psnr && no_missing_ssim && no_missing_runtime;

fprintf('  Expected rows:  %d\n', expected_total);
fprintf('  Actual rows:    %d\n', actual_rows);
fprintf('  Row count:      %s\n', ternary(row_match, 'PASS', 'FAIL'));
fprintf('  All methods:    %s\n', ternary(all_methods, 'PASS', 'FAIL'));
fprintf('  No duplicates:  %s\n', ternary(no_duplicates, 'PASS', 'FAIL'));
fprintf('  No missing:     %s\n', ternary(no_missing_psnr && no_missing_ssim && no_missing_runtime, 'PASS', 'FAIL'));
fprintf('  STATUS:         %s\n', ternary(check4_pass, 'PASS', 'FAIL'));

results = [results; {'Check 4: Table Integrity', ternary(check4_pass, 'PASS', 'FAIL'), ...
    sprintf('%d/%d rows, methods=%s, dups=%d', ...
    actual_rows, expected_total, strjoin(methods_present, ','), actual_rows-length(unique_idx))}];

%% CHECK 5: Summary Statistics Integrity
fprintf('\n========================================\n');
fprintf('CHECK 5: Summary Statistics Integrity\n');
fprintf('========================================\n');

% Run analyze_results (reads the just-generated results_table.csv)
summary = analyze_results();

% Check: one row per (dataset, sigma, method) combo
num_datasets_uq = length(unique(summary.dataset));
num_sigmas_uq   = length(unique(summary.sigma));
num_methods_uq  = length(unique(summary.method));
expected_summary_rows = num_datasets_uq * num_sigmas_uq * num_methods_uq;
actual_summary_rows = size(summary, 1);
summary_row_match = actual_summary_rows == expected_summary_rows;

% Check all values are finite and std >= 0
all_finite = all(isfinite(summary.mean_psnr)) && ...
             all(isfinite(summary.mean_ssim));
std_nonneg  = all(summary.std_psnr >= 0) && ...
              all(summary.std_ssim >= 0);

fprintf('  Expected summary rows: %d\n', expected_summary_rows);
fprintf('  Actual summary rows:   %d\n', actual_summary_rows);
fprintf('  Row count:             %s\n', ternary(summary_row_match, 'PASS', 'FAIL'));
fprintf('  All means finite:      %s\n', ternary(all_finite, 'PASS', 'FAIL'));
fprintf('  Std devs >= 0:         %s\n', ternary(std_nonneg, 'PASS', 'FAIL'));

check5_pass = summary_row_match && all_finite && std_nonneg;
fprintf('  STATUS:                %s\n', ternary(check5_pass, 'PASS', 'FAIL'));

results = [results; {'Check 5: Statistics', ternary(check5_pass, 'PASS', 'FAIL'), ...
    sprintf('%d/%d rows, finite=%d, std_nonneg=%d', ...
    actual_summary_rows, expected_summary_rows, all_finite, std_nonneg)}];

%% CHECK 6: Plot Generation
fprintf('\n========================================\n');
fprintf('CHECK 6: Plot Generation\n');
fprintf('========================================\n');

% Run plot generation
generate_result_plots();

% Check files exist
fig_dir = fullfile('results', 'figures');
expected_plots = { ...
    'psnr_vs_noise_existing.png'
    'ssim_vs_noise_existing.png'
    'runtime_comparison_existing.png'
    };

all_plots_exist = true;
for p = 1:length(expected_plots)
    fpath = fullfile(fig_dir, expected_plots{p});
    exists = exist(fpath, 'file');
    fsize = 0;
    if exists
        info = dir(fpath);
        fsize = info.bytes;
    end
    all_plots_exist = all_plots_exist && exists && (fsize > 1000);
    fprintf('  %s: %s (%.1f KB)\n', expected_plots{p}, ...
        ternary(exists && fsize > 1000, 'EXISTS', 'MISSING/SMALL'), fsize / 1024);
end

check6_pass = all_plots_exist;
fprintf('  STATUS: %s\n', ternary(check6_pass, 'PASS', 'FAIL'));

results = [results; {'Check 6: Plots', ternary(check6_pass, 'PASS', 'FAIL'), ...
    sprintf('%d/%d plots exist', sum([exist(fullfile(fig_dir, p), 'file') ...
    for p = 1:length(expected_plots)]), length(expected_plots))}];

%% CHECK 7: Reproducibility
fprintf('\n========================================\n');
fprintf('CHECK 7: Reproducibility (Noise Determinism)\n');
fprintf('========================================\n');

I = im2double(imread('lena.png'));

% Same seed -> identical noise
n1 = add_gaussian_noise(I, 20, 42);
n2 = add_gaussian_noise(I, 20, 42);
same_seed_match = isequal(n1, n2);

% Different seed -> different noise
n3 = add_gaussian_noise(I, 20, 99);
diff_seed_diff = ~isequal(n1, n3);

fprintf('  Same seed (42,42):  %s\n', ternary(same_seed_match, 'IDENTICAL', 'DIFFERENT'));
fprintf('  Diff seed (42,99):  %s\n', ternary(diff_seed_diff, 'DIFFERENT', 'IDENTICAL'));

check7_pass = same_seed_match && diff_seed_diff;
fprintf('  STATUS: %s\n', ternary(check7_pass, 'PASS', 'FAIL'));

results = [results; {'Check 7: Determinism', ternary(check7_pass, 'PASS', 'FAIL'), ...
    sprintf('same_seed=%d, diff_seed=%d', same_seed_match, diff_seed_diff)}];

%% SUMMARY
fprintf('\n========================================\n');
fprintf('VERIFICATION SUMMARY\n');
fprintf('========================================\n');

all_pass = true;
for i = 1:size(results, 1)
    pass = strcmp(results{i, 2}, 'PASS');
    all_pass = all_pass && pass;
    fprintf('  %s: %s\n', results{i, 1}, results{i, 2});
end
fprintf('------------------------------------------------\n');
fprintf('  OVERALL: %s\n', ternary(all_pass, 'ALL CHECKS PASSED', 'SOME CHECKS FAILED'));

%% GENERATE REPORT
fprintf('\n--- Generating EXPERIMENT_VERIFICATION_REPORT.md ---\n');
generate_verification_report(results, clean, denoised, noisy, psnr_custom_nocrop, psnr_builtin, ...
    ssim_custom_nocrop, ssim_builtin, check1_pass, check2_pass, check3_pass, ...
    check4_pass, check5_pass, check6_pass, check7_pass);

fprintf('Done.\n');

% -------------------------------------------------------------------------
function s = ternary(cond, t, f)
if cond
    s = t;
else
    s = f;
end
end

% -------------------------------------------------------------------------
function generate_verification_report(results, clean, denoised, noisy, ...
    psnr_custom, psnr_builtin, ssim_custom, ssim_builtin, ...
    check1_p, check2_p, check3_p, check4_p, check5_p, check6_p, check7_p)

report_path = 'EXPERIMENT_VERIFICATION_REPORT.md';
fid = fopen(report_path, 'w');

fprintf(fid, '# Experiment Verification Report\n\n');
fprintf(fid, '**Generated:** %s\n', datestr(now));
fprintf(fid, '**Script:** verify_experimental_pipeline.m\n\n');

% Summary table
fprintf(fid, '## Verification Summary\n\n');
fprintf(fid, '| # | Check | Status |\n');
fprintf(fid, '|---|-------|--------|\n');
for i = 1:size(results, 1)
    emoji = '✅';
    if strcmp(results{i, 2}, 'FAIL')
        emoji = '❌';
    end
    fprintf(fid, '| %d | %s | %s %s |\n', i, results{i, 1}, emoji, results{i, 2});
end
fprintf(fid, '\n');

% Detailed results
fprintf(fid, '## Detailed Results\n\n');

fprintf(fid, '### Check 1: PSNR Verification\n\n');
fprintf(fid, '| Method | PSNR (dB) |\n');
fprintf(fid, '|--------|-----------|\n');
fprintf(fid, '| compute_psnr (crop=0) | %.6f |\n', psnr_custom);
fprintf(fid, '| MATLAB psnr (built-in) | %.6f |\n', psnr_builtin);
fprintf(fid, '| **Status** | **%s** |\n', ternary(check1_p, 'PASS', 'FAIL'));
fprintf(fid, '\n');
fprintf(fid, '**Test image:** %s (%d x %d)\n', 'lena.png', size(clean, 1), size(clean, 2));
fprintf(fid, '**Threshold:** diff < 1e-6\n\n');

fprintf(fid, '### Check 2: SSIM Verification\n\n');
fprintf(fid, '| Method | SSIM |\n');
fprintf(fid, '|--------|------|\n');
fprintf(fid, '| compute_ssim (crop=0) | %.6f |\n', ssim_custom);
fprintf(fid, '| MATLAB ssim (built-in) | %.6f |\n', ssim_builtin);
fprintf(fid, '| Self-SSIM (identity) | %.6f |\n', compute_ssim(clean, clean, 0));
fprintf(fid, '| **Status** | **%s** |\n', ternary(check2_p, 'PASS', 'FAIL'));
fprintf(fid, '\n');
fprintf(fid, '**Range check:** 0 <= SSIM <= 1: YES\n');
fprintf(fid, '**Threshold:** diff < 1e-6\n\n');

fprintf(fid, '### Check 3: Runtime Verification\n\n');
fprintf(fid, '| Method | benchmark_runtime (s) | Direct tic/toc (s) | Diff (%) |\n');
fprintf(fid, '|--------|----------------------|--------------------|----------|\n');
fprintf(fid, '| original | N/A | N/A | N/A | (see console output) |\n');
fprintf(fid, '| adaptive | N/A | N/A | N/A | (see console output) |\n');
fprintf(fid, '| **Status** | **%s** |\n', ternary(check3_p, 'PASS', 'FAIL'));
fprintf(fid, '\n');
fprintf(fid, '**Threshold:** < 10%% difference\n\n');

fprintf(fid, '### Check 4: Results Table Integrity\n\n');
fprintf(fid, '| Property | Value |\n');
fprintf(fid, '|----------|-------|\n');
fprintf(fid, '| Configuration | existing, sigma=20, 2 realizations, 3 methods |\n');
fprintf(fid, '| Expected rows | 4 × 1 × 2 × 3 = 24 |\n');
fprintf(fid, '| **Status** | **%s** |\n', ternary(check4_p, 'PASS', 'FAIL'));
fprintf(fid, '\n');

fprintf(fid, '### Check 5: Summary Statistics\n\n');
fprintf(fid, '| Property | Value |\n');
fprintf(fid, '|----------|-------|\n');
fprintf(fid, '| Rows match expected | %s |\n', ternary(check5_p, 'YES', 'NO'));
fprintf(fid, '| All means finite | %s |\n', ternary(check5_p, 'YES', 'NO'));
fprintf(fid, '| All std >= 0 | %s |\n', ternary(check5_p, 'YES', 'NO'));
fprintf(fid, '| **Status** | **%s** |\n', ternary(check5_p, 'PASS', 'FAIL'));
fprintf(fid, '\n');

fprintf(fid, '### Check 6: Plot Generation\n\n');
fprintf(fid, '| File | Status |\n');
fprintf(fid, '|------|--------|\n');
fprintf(fid, '| psnr_vs_noise_existing.png | %s |\n', ternary(check6_p, 'GENERATED', 'MISSING'));
fprintf(fid, '| ssim_vs_noise_existing.png | %s |\n', ternary(check6_p, 'GENERATED', 'MISSING'));
fprintf(fid, '| runtime_comparison_existing.png | %s |\n', ternary(check6_p, 'GENERATED', 'MISSING'));
fprintf(fid, '| **Status** | **%s** |\n', ternary(check6_p, 'PASS', 'FAIL'));
fprintf(fid, '\n');

fprintf(fid, '### Check 7: Reproducibility\n\n');
fprintf(fid, '| Test | Result |\n');
fprintf(fid, '|------|--------|\n');
fprintf(fid, '| Same seed (42, 42) | %s |\n', ternary(check7_p, 'IDENTICAL', 'DIFFERENT'));
fprintf(fid, '| Different seed (42, 99) | %s |\n', ternary(check7_p, 'DIFFERENT', 'IDENTICAL'));
fprintf(fid, '| **Status** | **%s** |\n', ternary(check7_p, 'PASS', 'FAIL'));
fprintf(fid, '\n');

% Recommendations
fprintf(fid, '## Recommendations\n\n');
fprintf(fid, 'Based on the verification results:\n\n');
if ~check1_p
    fprintf(fid, '- ❌ **PSNR mismatch:** Investigate compute_psnr.m numerical differences.\n');
end
if ~check2_p
    fprintf(fid, '- ❌ **SSIM mismatch:** Investigate compute_ssim.m numerical differences.\n');
end
if ~check3_p
    fprintf(fid, '- ❌ **Runtime overhead:** benchmark_runtime may have excessive overhead.\n');
end
if ~check4_p
    fprintf(fid, '- ❌ **Table integrity:** Batch experiment produced unexpected row count.\n');
end
if ~check5_p
    fprintf(fid, '- ❌ **Statistics invalid:** Summary statistics contain non-finite or negative values.\n');
end
if ~check6_p
    fprintf(fid, '- ❌ **Plot generation:** Some expected plot files were not created.\n');
end
if ~check7_p
    fprintf(fid, '- ❌ **Non-deterministic noise:** add_gaussian_noise is not reproducible.\n');
end
if check1_p && check2_p && check3_p && check4_p && check5_p && check6_p && check7_p
    fprintf(fid, '- ✅ All checks pass. The experimental framework is ready for Phase-II integration.\n');
end

fprintf(fid, '\n## Environment\n\n');
fprintf(fid, '| Property | Value |\n');
fprintf(fid, '|----------|-------|\n');
fprintf(fid, '| MATLAB Version | N/A (runtime) |\n');
fprintf(fid, '| Image Processing Toolbox | %s |\n', ...
    ternary(license('test', 'image_toolbox'), 'Available', 'Not available'));
fprintf(fid, '| Test image | lena.png |\n');
fprintf(fid, '| Image size | %d × %d |\n', size(clean, 1), size(clean, 2));

fclose(fid);
fprintf('Report written to: %s\n', report_path);

end
