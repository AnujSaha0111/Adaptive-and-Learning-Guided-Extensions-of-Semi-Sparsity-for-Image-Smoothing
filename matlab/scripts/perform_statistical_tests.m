function perform_statistical_tests()
%PERFORM_STATISTICAL_TESTS Statistical significance analysis.
%   PERFORM_STATISTICAL_TESTS() reads per_image_statistics.csv and runs
%   paired tests comparing Adaptive Semi-Sparsity against all other
%   methods across each (dataset, sigma) combination.
%
%   Tests performed:
%     1. Paired t-test (parametric)
%     2. Wilcoxon signed-rank test (non-parametric)
%     3. Cohen's d effect size
%     4. 95% confidence interval for mean difference
%
%   Inputs:
%     results/per_image_statistics.csv
%       Columns: dataset, image, sigma, method, mean_psnr, std_psnr,
%                mean_ssim, std_ssim, num_samples
%
%   Outputs (results/statistics/):
%     1. statistical_tests.csv   — p-values & significance (α=0.05)
%     2. effect_sizes.csv        — Cohen's d
%     3. confidence_intervals.csv — 95% CI for mean difference
%     4. STATISTICAL_ANALYSIS_REPORT.md

REF_METHOD = 'adaptive';
COMPARISONS = {'original', 'lgss', 'bilateral', 'guided', 'tv', 'l0'};
ALPHA = 0.05;

out_dir = fullfile('results', 'statistics');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

pi_file = fullfile('results', 'per_image_statistics.csv');
if ~exist(pi_file, 'file')
    error('perform_statistical_tests:FileNotFound', ...
        'per_image_statistics.csv not found. Run analyze_results first.');
end

PI = readtable(pi_file);
fprintf('Loaded %d rows from per_image_statistics.csv\n', size(PI, 1));

% Validate required columns
required_cols = {'dataset', 'image', 'sigma', 'method', 'mean_psnr', 'mean_ssim'};
for i = 1:length(required_cols)
    if ~ismember(required_cols{i}, PI.Properties.VariableNames)
        error('perform_statistical_tests:MissingColumn', ...
            'Required column "%s" not found.', required_cols{i});
    end
end

% Check that REF_METHOD is present
if ~any(strcmp(PI.method, REF_METHOD))
    error('perform_statistical_tests:MethodNotFound', ...
        'Reference method "%s" not found in data.', REF_METHOD);
end

% Group by (dataset, sigma)
[groups, group_ids] = findgroups(PI(:, {'dataset', 'sigma'}));
num_groups = size(group_ids, 1);

% Result accumulators (each row includes Metric at the start)
test_rows = {};
effect_rows = {};
ci_rows = {};

for g = 1:num_groups
    ds = group_ids.dataset{g};
    sg = group_ids.sigma(g);

    % Subset for this group
    mask = groups == g;
    subset = PI(mask, :);

    % Get unique images in this group
    images = unique(subset.image);
    methods_in_group = unique(subset.method);

    % Extract adaptive data (reference)
    ref_mask = strcmp(subset.method, REF_METHOD);
    ref_data_psnr = subset.mean_psnr(ref_mask);
    ref_data_ssim = subset.mean_ssim(ref_mask);

    for c = 1:length(COMPARISONS)
        comp = COMPARISONS{c};

        if ~any(strcmp(methods_in_group, comp))
            fprintf('  (dataset=%s, sigma=%d): method "%s" not present, skipping\n', ...
                ds, sg, comp);
            continue;
        end

        % Extract comparison method data, aligned by image
        comp_mask = strcmp(subset.method, comp);
        comp_data_psnr = subset.mean_psnr(comp_mask);
        comp_data_ssim = subset.mean_ssim(comp_mask);

        % Align by image (in case images differ — they shouldn't, but be safe)
        ref_images = subset.image(ref_mask);
        comp_images = subset.image(comp_mask);

        [common_images, ia, ib] = intersect(ref_images, comp_images, 'stable');
        if length(common_images) < 3
            fprintf('  (dataset=%s, sigma=%d): too few common images (%d) for %s, skipping\n', ...
                ds, sg, length(common_images), comp);
            continue;
        end

        ref_aligned_psnr = ref_data_psnr(ia);
        comp_aligned_psnr = comp_data_psnr(ib);
        ref_aligned_ssim = ref_data_ssim(ia);
        comp_aligned_ssim = comp_data_ssim(ib);

        diff_psnr = ref_aligned_psnr - comp_aligned_psnr;
        diff_ssim = ref_aligned_ssim - comp_aligned_ssim;
        n = length(diff_psnr);

        % --- 1. Paired t-test ---
        [h_psnr, p_psnr] = ttest(diff_psnr, 0, 'Alpha', ALPHA);
        [h_ssim, p_ssim] = ttest(diff_ssim, 0, 'Alpha', ALPHA);

        % --- 2. Wilcoxon signed-rank test ---
        [p_w_psnr, h_w_psnr] = signrank(diff_psnr, 0, 'Alpha', ALPHA);
        [p_w_ssim, h_w_ssim] = signrank(diff_ssim, 0, 'Alpha', ALPHA);

        % --- 3. Cohen's d ---
        mean_diff_psnr = mean(diff_psnr, 'omitnan');
        std_diff_psnr  = std(diff_psnr, 'omitnan');
        if std_diff_psnr > 0
            d_psnr = mean_diff_psnr / std_diff_psnr;
        else
            d_psnr = 0;
        end

        mean_diff_ssim = mean(diff_ssim, 'omitnan');
        std_diff_ssim  = std(diff_ssim, 'omitnan');
        if std_diff_ssim > 0
            d_ssim = mean_diff_ssim / std_diff_ssim;
        else
            d_ssim = 0;
        end

        % --- 4. 95% CI ---
        se_psnr = std_diff_psnr / sqrt(n);
        se_ssim = std_diff_ssim / sqrt(n);
        t_crit = tinv(1 - ALPHA/2, n - 1);

        ci_psnr_low  = mean_diff_psnr - t_crit * se_psnr;
        ci_psnr_high = mean_diff_psnr + t_crit * se_psnr;
        ci_ssim_low  = mean_diff_ssim - t_crit * se_ssim;
        ci_ssim_high = mean_diff_ssim + t_crit * se_ssim;

        % --- Store results (PSNR) ---
        test_rows(end+1, :) = {'PSNR', ds, sg, sprintf('Adaptive vs %s', comp), ...
            p_psnr, h_psnr, p_w_psnr, h_w_psnr, n}; %#ok<AGROW>

        effect_rows(end+1, :) = {'PSNR', ds, sg, sprintf('Adaptive vs %s', comp), ...
            d_psnr, mean_diff_psnr, std_diff_psnr, n}; %#ok<AGROW>

        ci_rows(end+1, :) = {'PSNR', ds, sg, sprintf('Adaptive vs %s', comp), ...
            mean_diff_psnr, ci_psnr_low, ci_psnr_high, std_diff_psnr, n}; %#ok<AGROW>

        % --- Store results (SSIM) ---
        test_rows(end+1, :) = {'SSIM', ds, sg, sprintf('Adaptive vs %s', comp), ...
            p_ssim, h_ssim, p_w_ssim, h_w_ssim, n}; %#ok<AGROW>

        effect_rows(end+1, :) = {'SSIM', ds, sg, sprintf('Adaptive vs %s', comp), ...
            d_ssim, mean_diff_ssim, std_diff_ssim, n}; %#ok<AGROW>

        ci_rows(end+1, :) = {'SSIM', ds, sg, sprintf('Adaptive vs %s', comp), ...
            mean_diff_ssim, ci_ssim_low, ci_ssim_high, std_diff_ssim, n}; %#ok<AGROW>

        sig_str = 'significant';
        if ~h_psnr
            sig_str = 'not significant';
        end
        fprintf('  %s sigma=%d: Adaptive vs %s: p=%.4f (%s), d=%.3f, CI=[%.3f, %.3f]\n', ...
            ds, sg, comp, p_psnr, sig_str, d_psnr, ci_psnr_low, ci_psnr_high);
    end
end

% ---------------------------------------------------------------------
% Build output tables
% ---------------------------------------------------------------------
test_var_names = {'Metric', 'Dataset', 'Sigma', 'Comparison', ...
    'PairedT_pval', 'PairedT_significant', ...
    'Wilcoxon_pval', 'Wilcoxon_significant', 'N'};

% --- 1. statistical_tests.csv ---
tt_all = cell2table(test_rows, 'VariableNames', test_var_names);
tt_all = sortrows(tt_all, {'Dataset', 'Sigma', 'Metric', 'Comparison'});
writetable(tt_all, fullfile(out_dir, 'statistical_tests.csv'));
fprintf('\nSaved: statistical_tests.csv (%d rows)\n', height(tt_all));

% Split for report generation
tt_psnr = tt_all(strcmp(tt_all.Metric, 'PSNR'), :);
tt_ssim = tt_all(strcmp(tt_all.Metric, 'SSIM'), :);

% --- 2. effect_sizes.csv ---
effect_var_names = {'Metric', 'Dataset', 'Sigma', 'Comparison', ...
    'Cohens_d', 'Mean_Diff', 'Std_Diff', 'N'};
et_all = cell2table(effect_rows, 'VariableNames', effect_var_names);
et_all = sortrows(et_all, {'Dataset', 'Sigma', 'Metric', 'Comparison'});
writetable(et_all, fullfile(out_dir, 'effect_sizes.csv'));
fprintf('Saved: effect_sizes.csv (%d rows)\n', height(et_all));

et_psnr = et_all(strcmp(et_all.Metric, 'PSNR'), :);
et_ssim = et_all(strcmp(et_all.Metric, 'SSIM'), :);

% --- 3. confidence_intervals.csv ---
ci_var_names = {'Metric', 'Dataset', 'Sigma', 'Comparison', ...
    'Mean_Diff', 'CI_Lower', 'CI_Upper', 'Std_Diff', 'N'};
cit_all = cell2table(ci_rows, 'VariableNames', ci_var_names);
cit_all = sortrows(cit_all, {'Dataset', 'Sigma', 'Metric', 'Comparison'});
writetable(cit_all, fullfile(out_dir, 'confidence_intervals.csv'));
fprintf('Saved: confidence_intervals.csv (%d rows)\n', height(cit_all));

cit_psnr = cit_all(strcmp(cit_all.Metric, 'PSNR'), :);
cit_ssim = cit_all(strcmp(cit_all.Metric, 'SSIM'), :);

% ---------------------------------------------------------------------
% 4. STATISTICAL_ANALYSIS_REPORT.md
% ---------------------------------------------------------------------
generate_statistical_report(tt_psnr, tt_ssim, ...
    et_psnr, et_ssim, ...
    cit_psnr, cit_ssim, out_dir, ALPHA);

fprintf('\nAll statistical test results saved to: %s\n', out_dir);

end

% -------------------------------------------------------------------------
function generate_statistical_report(tp, ts, ep, es, cp, cs, out_dir, ALPHA)
%GENERATE_STATISTICAL_REPORT Produce STATISTICAL_ANALYSIS_REPORT.md.

fid = fopen(fullfile(out_dir, 'STATISTICAL_ANALYSIS_REPORT.md'), 'w');

fprintf(fid, '# Statistical Significance Analysis Report\n\n');
fprintf(fid, 'Adaptive Semi-Sparsity vs all baseline methods.\n\n');
fprintf(fid, '- Significance level: α = %.2f\n', ALPHA);
fprintf(fid, '- Metric: PSNR (primary), SSIM (secondary)\n');
fprintf(fid, '- Tests: Paired t-test, Wilcoxon signed-rank test\n');
fprintf(fid, '- Effect size: Cohen''s d\n');
fprintf(fid, '- Confidence interval: 95%%\n\n');
fprintf(fid, '---\n\n');

% ---- PSNR Results ----
fprintf(fid, '## PSNR Results\n\n');

datasets = unique(tp.Dataset);
sigmas   = unique(tp.Sigma);

for d = 1:length(datasets)
    ds = datasets{d};
    fprintf(fid, '### Dataset: %s\n\n', ds);
    fprintf(fid, '| Comparison | Sigma | p (t-test) | Significant? | p (Wilcoxon) | Significant? | Cohen''s d | 95%% CI | N |\n');
    fprintf(fid, '|---|---|---:|---|---:|---|---:|---:|---:|\n');

    ds_mask = strcmp(tp.Dataset, ds);
    ds_rows = tp(ds_mask, :);

    for r = 1:size(ds_rows, 1)
        row = ds_rows(r, :);
        comp = row.Comparison{1};
        sg   = row.Sigma;

        % Find matching effect size
        e_mask = strcmp(ep.Dataset, ds) & (ep.Sigma == sg) & ...
            strcmp(ep.Comparison, comp);
        e_row = ep(e_mask, :);

        % Find matching CI
        c_mask = strcmp(cp.Dataset, ds) & (cp.Sigma == sg) & ...
            strcmp(cp.Comparison, comp);
        c_row = cp(c_mask, :);

        d_val = e_row.Cohens_d(1);
        ci_str = sprintf('[%.3f, %.3f]', c_row.CI_Lower(1), c_row.CI_Upper(1));
        d_str = interpret_cohens_d(d_val);

        sig_tt = iff_logical(row.PairedT_significant(1), 'Yes ✓', 'No ✗');
        sig_w  = iff_logical(row.Wilcoxon_significant(1), 'Yes ✓', 'No ✗');

        fprintf(fid, '| %s | %d | %.4f | %s | %.4f | %s | %.3f (%s) | %s | %d |\n', ...
            comp, sg, row.PairedT_pval(1), sig_tt, ...
            row.Wilcoxon_pval(1), sig_w, ...
            d_val, d_str, ci_str, row.N(1));
    end
    fprintf(fid, '\n');
end

% ---- SSIM Results ----
fprintf(fid, '---\n\n## SSIM Results\n\n');

for d = 1:length(datasets)
    ds = datasets{d};
    fprintf(fid, '### Dataset: %s\n\n', ds);
    fprintf(fid, '| Comparison | Sigma | p (t-test) | Significant? | p (Wilcoxon) | Significant? | Cohen''s d | 95%% CI | N |\n');
    fprintf(fid, '|---|---:|---:|---|---:|---:|---:|---:|---:|\n');

    ds_mask = strcmp(ts.Dataset, ds);
    ds_rows = ts(ds_mask, :);

    for r = 1:size(ds_rows, 1)
        row = ds_rows(r, :);
        comp = row.Comparison{1};
        sg   = row.Sigma;

        e_mask = strcmp(es.Dataset, ds) & (es.Sigma == sg) & ...
            strcmp(es.Comparison, comp);
        e_row = es(e_mask, :);

        c_mask = strcmp(cs.Dataset, ds) & (cs.Sigma == sg) & ...
            strcmp(cs.Comparison, comp);
        c_row = cs(c_mask, :);

        d_val = e_row.Cohens_d(1);
        ci_str = sprintf('[%.4f, %.4f]', c_row.CI_Lower(1), c_row.CI_Upper(1));
        d_str = interpret_cohens_d(d_val);

        sig_tt = iff_logical(row.PairedT_significant(1), 'Yes ✓', 'No ✗');
        sig_w  = iff_logical(row.Wilcoxon_significant(1), 'Yes ✓', 'No ✗');

        fprintf(fid, '| %s | %d | %.4f | %s | %.4f | %s | %.3f (%s) | %s | %d |\n', ...
            comp, sg, row.PairedT_pval(1), sig_tt, ...
            row.Wilcoxon_pval(1), sig_w, ...
            d_val, d_str, ci_str, row.N(1));
    end
    fprintf(fid, '\n');
end

% ---- Summary ----
fprintf(fid, '---\n\n## Summary\n\n');

% Collect decision per dataset per comparison
all_comparisons = unique(tp.Comparison);
fprintf(fid, '### PSNR — Significance Decisions\n\n');

for c = 1:length(all_comparisons)
    comp = all_comparisons{c};
    fprintf(fid, '**%s**: ', comp);

    wins   = 0;
    losses = 0;
    ns     = 0;
    for d = 1:length(datasets)
        ds = datasets{d};
        for s = 1:length(sigmas)
            sg = sigmas(s);
            mask = strcmp(tp.Dataset, ds) & (tp.Sigma == sg) & ...
                strcmp(tp.Comparison, comp);
            if any(mask)
                row = tp(mask, :);
                if row.PairedT_significant(1) == 1
                    % Significant: check direction via mean diff
                    e_mask = strcmp(ep.Dataset, ds) & (ep.Sigma == sg) & ...
                        strcmp(ep.Comparison, comp);
                    e_row = ep(e_mask, :);
                    if e_row.Mean_Diff(1) > 0
                        wins = wins + 1;
                    else
                        losses = losses + 1;
                    end
                else
                    ns = ns + 1;
                end
            end
        end
    end

    fprintf(fid, 'Adaptive wins significantly in %d, loses in %d, not significant in %d (out of %d).\n', ...
        wins, losses, ns, wins + losses + ns);
end

fprintf(fid, '\n### SSIM — Significance Decisions\n\n');

for c = 1:length(all_comparisons)
    comp = all_comparisons{c};
    fprintf(fid, '**%s**: ', comp);

    wins   = 0;
    losses = 0;
    ns     = 0;
    for d = 1:length(datasets)
        ds = datasets{d};
        for s = 1:length(sigmas)
            sg = sigmas(s);
            mask = strcmp(ts.Dataset, ds) & (ts.Sigma == sg) & ...
                strcmp(ts.Comparison, comp);
            if any(mask)
                row = ts(mask, :);
                if row.PairedT_significant(1) == 1
                    e_mask = strcmp(es.Dataset, ds) & (es.Sigma == sg) & ...
                        strcmp(es.Comparison, comp);
                    e_row = es(e_mask, :);
                    if e_row.Mean_Diff(1) > 0
                        wins = wins + 1;
                    else
                        losses = losses + 1;
                    end
                else
                    ns = ns + 1;
                end
            end
        end
    end

    fprintf(fid, 'Adaptive wins significantly in %d, loses in %d, not significant in %d (out of %d).\n', ...
        wins, losses, ns, wins + losses + ns);
end

fprintf(fid, '\n### Key Observations\n\n');

% Overall effect size summary
fprintf(fid, '1. **Effect sizes (Cohen''s d)** across all comparisons:\n');
all_d_psnr = ep.Cohens_d;
mean_d = mean(all_d_psnr, 'omitnan');
max_d  = max(all_d_psnr);
min_d  = min(all_d_psnr);
fprintf(fid, '   - PSNR: mean d = %.3f, range [%.3f, %.3f]\n', mean_d, min_d, max_d);
all_d_ssim = es.Cohens_d;
mean_ds = mean(all_d_ssim, 'omitnan');
max_ds  = max(all_d_ssim);
min_ds  = min(all_d_ssim);
fprintf(fid, '   - SSIM: mean d = %.3f, range [%.3f, %.3f]\n', mean_ds, min_ds, max_ds);

fprintf(fid, '\n2. **Datasets where Adaptive is consistently superior** (all comparisons significant with positive gain):\n');
for d = 1:length(datasets)
    ds = datasets{d};
    mask = strcmp(tp.Dataset, ds);
    all_sig = all(tp.PairedT_significant(mask) == 1);
    if all_sig
        e_mask = strcmp(ep.Dataset, ds);
        all_pos = all(ep.Mean_Diff(e_mask) > 0);
        if all_pos
            fprintf(fid, '   - **%s**: All comparisons significant and positive.\n', ds);
        end
    end
end

fprintf(fid, '\n3. **Datasets where differences are mostly not significant**:\n');
for d = 1:length(datasets)
    ds = datasets{d};
    mask = strcmp(tp.Dataset, ds);
    n_sig = nnz(tp.PairedT_significant(mask) == 1);
    n_total = nnz(mask);
    if n_sig < n_total / 2
        fprintf(fid, '   - **%s**: Only %d/%d comparisons significant.\n', ds, n_sig, n_total);
    end
end

fprintf(fid, '\n4. **Datasets where Adaptive performs worse** (significant negative gains):\n');
for d = 1:length(datasets)
    ds = datasets{d};
    mask = strcmp(tp.Dataset, ds);
    neg_mask = mask & (tp.PairedT_significant == 1);
    for r = 1:size(tp, 1)
        if neg_mask(r)
            comp = tp.Comparison{r};
            e_mask = strcmp(ep.Dataset, ds) & strcmp(ep.Comparison, comp) & ...
                (ep.Sigma == tp.Sigma(r));
            e_row = ep(e_mask, :);
            if ~isempty(e_row) && e_row.Mean_Diff(1) < 0
                fprintf(fid, '   - %s (sigma=%d): Adaptive loses by %.3f dB (p=%.4f)\n', ...
                    ds, tp.Sigma(r), abs(e_row.Mean_Diff(1)), tp.PairedT_pval(r));
            end
        end
    end
end

fprintf(fid, '\n5. **Effect size interpretation** (Cohen, 1988):\n');
fprintf(fid, '   - |d| < 0.2: negligible\n');
fprintf(fid, '   - 0.2 ≤ |d| < 0.5: small\n');
fprintf(fid, '   - 0.5 ≤ |d| < 0.8: medium\n');
fprintf(fid, '   - |d| ≥ 0.8: large\n');

fprintf(fid, '\n---\n');
fprintf(fid, '*Report generated by `perform_statistical_tests.m`*\n');

fclose(fid);

end

% -------------------------------------------------------------------------
function s = interpret_cohens_d(d)
%INTERPRET_COHENS_D Return text interpretation of Cohen's d.
abs_d = abs(d);
if abs_d < 0.2
    s = 'negligible';
elseif abs_d < 0.5
    s = 'small';
elseif abs_d < 0.8
    s = 'medium';
else
    s = 'large';
end
end

% -------------------------------------------------------------------------
function s = iff_logical(cond, true_str, false_str)
%IFF_LOGICAL Inline if for string selection.
if cond
    s = true_str;
else
    s = false_str;
end
end
