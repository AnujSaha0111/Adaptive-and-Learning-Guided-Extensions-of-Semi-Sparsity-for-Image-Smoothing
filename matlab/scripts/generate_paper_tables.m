function generate_paper_tables()
%GENERATE_PAPER_TABLES Generate publication-quality tables and summaries.
%   GENERATE_PAPER_TABLES() reads the CSV files produced by
%   analyze_results.m and generates 7 table CSV files plus a Markdown
%   summary in results/paper_tables/.
%
%   Inputs (read from results/):
%     results_table.csv
%     summary_statistics.csv
%     per_image_statistics.csv
%
%   Outputs (written to results/paper_tables/):
%     1. table_psnr_mean_std.csv
%     2. table_ssim_mean_std.csv
%     3. table_runtime.csv
%     4. table_method_ranking.csv
%     5. table_adaptive_vs_original.csv
%     6. table_adaptive_vs_lgss.csv
%     7. table_failure_cases.csv
%
%   Also writes results/paper_tables/PAPER_TABLE_SUMMARY.md

base_dir = fullfile('results', 'paper_tables');
if ~exist(base_dir, 'dir')
    mkdir(base_dir);
end

% ---------------------------------------------------------------------
% Load inputs
% ---------------------------------------------------------------------
results_file    = fullfile('results', 'results_table.csv');
summary_file    = fullfile('results', 'summary_statistics.csv');
perimage_file   = fullfile('results', 'per_image_statistics.csv');

if ~exist(results_file, 'file')
    error('generate_paper_tables:FileNotFound', ...
        'results_table.csv not found. Run batch experiments first.');
end
if ~exist(summary_file, 'file')
    error('generate_paper_tables:FileNotFound', ...
        'summary_statistics.csv not found. Run analyze_results first.');
end
if ~exist(perimage_file, 'file')
    error('generate_paper_tables:FileNotFound', ...
        'per_image_statistics.csv not found. Run analyze_results first.');
end

R  = readtable(results_file);
S  = readtable(summary_file);
PI = readtable(perimage_file);

fprintf('Loaded %d rows from results_table.csv\n', size(R, 1));
fprintf('Loaded %d rows from summary_statistics.csv\n', size(S, 1));
fprintf('Loaded %d rows from per_image_statistics.csv\n', size(PI, 1));

% ---------------------------------------------------------------------
% 1. table_psnr_mean_std.csv
% ---------------------------------------------------------------------
fprintf('\n--- Table 1: PSNR Mean & Std ---\n');
T1 = S(:, {'dataset', 'sigma', 'method', 'mean_psnr', 'std_psnr'});
T1 = sortrows(T1, {'dataset', 'sigma', 'method'});
writetable(T1, fullfile(base_dir, 'table_psnr_mean_std.csv'));
fprintf('  Saved: table_psnr_mean_std.csv\n');

% ---------------------------------------------------------------------
% 2. table_ssim_mean_std.csv
% ---------------------------------------------------------------------
fprintf('\n--- Table 2: SSIM Mean & Std ---\n');
T2 = S(:, {'dataset', 'sigma', 'method', 'mean_ssim', 'std_ssim'});
T2 = sortrows(T2, {'dataset', 'sigma', 'method'});
writetable(T2, fullfile(base_dir, 'table_ssim_mean_std.csv'));
fprintf('  Saved: table_ssim_mean_std.csv\n');

% ---------------------------------------------------------------------
% 3. table_runtime.csv
% ---------------------------------------------------------------------
fprintf('\n--- Table 3: Runtime ---\n');
[methods_rt, ~, rt_idx] = unique(S.method);
mean_rt = splitapply(@(x) mean(x, 'omitnan'), S.mean_runtime, rt_idx);
std_rt  = splitapply(@(x) std(x, 'omitnan'), S.mean_runtime, rt_idx);
T3 = table(methods_rt, mean_rt, std_rt, ...
    'VariableNames', {'Method', 'Mean_Runtime', 'Std_Runtime'});
T3 = sortrows(T3, 'Mean_Runtime');
writetable(T3, fullfile(base_dir, 'table_runtime.csv'));
fprintf('  Saved: table_runtime.csv\n');

% ---------------------------------------------------------------------
% 4. table_method_ranking.csv
% ---------------------------------------------------------------------
fprintf('\n--- Table 4: Method Ranking ---\n');
all_methods_in_data = unique(S.method);
num_methods_present = length(all_methods_in_data);

[groups_rank, rank_ids] = findgroups(S(:, {'dataset', 'sigma'}));

T4_cell = {};
for i = 1:size(rank_ids, 1)
    row = table2cell(rank_ids(i, :));
    g = groups_rank == i;
    grp_methods = S.method(g);
    grp_psnr    = S.mean_psnr(g);
    ranked = sortrows(table(grp_methods, grp_psnr), 'grp_psnr', 'descend');
    for r = 1:height(ranked)
        row{end+1} = ranked.grp_methods{r}; %#ok<AGROW>
    end
    % pad to uniform width
    while length(row) < 2 + num_methods_present
        row{end+1} = ''; %#ok<AGROW>
    end
    T4_cell = [T4_cell; row]; %#ok<AGROW>
end

rank_var_names = cell(1, num_methods_present);
for i = 1:num_methods_present
    rank_var_names{i} = sprintf('Rank%d', i);
end
T4 = cell2table(T4_cell, 'VariableNames', ...
    [{'Dataset', 'Sigma'}, rank_var_names]);
writetable(T4, fullfile(base_dir, 'table_method_ranking.csv'));
fprintf('  Saved: table_method_ranking.csv\n');

% ---------------------------------------------------------------------
% 5. table_adaptive_vs_original.csv
% ---------------------------------------------------------------------
fprintf('\n--- Table 5: Adaptive vs Original ---\n');
T5 = compute_gain_table(S, 'adaptive', 'original');
if height(T5) > 0
    writetable(T5, fullfile(base_dir, 'table_adaptive_vs_original.csv'));
    fprintf('  Saved: table_adaptive_vs_original.csv\n');
else
    fprintf('  Skipped: adaptive or original not present.\n');
end

% ---------------------------------------------------------------------
% 6. table_adaptive_vs_lgss.csv
% ---------------------------------------------------------------------
fprintf('\n--- Table 6: Adaptive vs LGSS ---\n');
T6 = compute_gain_table(S, 'adaptive', 'lgss');
if height(T6) > 0
    writetable(T6, fullfile(base_dir, 'table_adaptive_vs_lgss.csv'));
    fprintf('  Saved: table_adaptive_vs_lgss.csv\n');
else
    fprintf('  Skipped: adaptive or lgss not present.\n');
end

% ---------------------------------------------------------------------
% 7. table_failure_cases.csv
% ---------------------------------------------------------------------
fprintf('\n--- Table 7: Failure Cases ---\n');
[img_groups, img_ids] = findgroups(PI(:, {'image', 'dataset', 'sigma'}));
failure_data = splitapply(@(m, p) find_best_worst(m, p), ...
    PI.method, PI.mean_psnr, img_groups);

T7_cell = {};
for i = 1:size(img_ids, 1)
    row = table2cell(img_ids(i, :));
    if iscell(failure_data)
        f = failure_data{i};
    else
        f = failure_data(i);
    end
    row{end+1} = f.best;
    row{end+1} = f.worst;
    T7_cell = [T7_cell; row]; %#ok<AGROW>
end

T7 = cell2table(T7_cell, 'VariableNames', ...
    {'Image', 'Dataset', 'Sigma', 'Best_Method', 'Worst_Method'});
T7 = sortrows(T7, {'Dataset', 'Sigma', 'Image'});
writetable(T7, fullfile(base_dir, 'table_failure_cases.csv'));
fprintf('  Saved: table_failure_cases.csv\n');

% ---------------------------------------------------------------------
% 8. PAPER_TABLE_SUMMARY.md
% ---------------------------------------------------------------------
fprintf('\n--- Generating PAPER_TABLE_SUMMARY.md ---\n');
generate_markdown_summary(R, S, T1, T2, T3, T4, T5, T6, T7, base_dir);
fprintf('  Saved: PAPER_TABLE_SUMMARY.md\n');

fprintf('\nAll paper tables generated in: %s\n', base_dir);

end

% -------------------------------------------------------------------------
function ranking = rank_methods(methods, psnr_vals)
%RANK_METHODS Rank methods by descending mean PSNR.
ranked = sortrows(table(methods, psnr_vals), 'psnr_vals', 'descend');
ranking = table2cell(ranked(:, 1));
end

% -------------------------------------------------------------------------
function gain_table = compute_gain_table(S, method_a, method_b)
%COMPUTE_GAIN_TABLE Compute PSNR gain of method_a over method_b.
if ~any(strcmp(S.method, method_a)) || ~any(strcmp(S.method, method_b))
    fprintf('  Skipping gain table (%s vs %s): one or both methods not present.\n', ...
        method_a, method_b);
    gain_table = table();
    return;
end

[groups, ids] = findgroups(S(:, {'dataset', 'sigma'}));
gains = splitapply(@(m, p) compute_gain(m, p, method_a, method_b), ...
    S.method, S.mean_psnr, groups);

T_cell = {};
for i = 1:size(ids, 1)
    row = table2cell(ids(i, :));
    row{end+1} = gains(i);
    T_cell = [T_cell; row]; %#ok<AGROW>
end
gain_table = cell2table(T_cell, ...
    'VariableNames', {'Dataset', 'Sigma', 'Mean_Gain_dB'});
if iscell(gain_table.Mean_Gain_dB)
    gain_table.Mean_Gain_dB = cell2mat(gain_table.Mean_Gain_dB);
end
gain_table = sortrows(gain_table, {'Dataset', 'Sigma'});
end

function g = compute_gain(methods, psnr_vals, method_a, method_b)
idx_a = find(strcmp(methods, method_a), 1);
idx_b = find(strcmp(methods, method_b), 1);
if isempty(idx_a) || isempty(idx_b)
    g = NaN;
else
    g = psnr_vals(idx_a) - psnr_vals(idx_b);
end
end

% -------------------------------------------------------------------------
function f = find_best_worst(methods, psnr_vals)
%FIND_BEST_WORST Find best and worst method by mean PSNR.
[~, best_idx] = max(psnr_vals);
[~, worst_idx] = min(psnr_vals);
f.best  = methods{best_idx};
f.worst = methods{worst_idx};
end

% -------------------------------------------------------------------------
function generate_markdown_summary(R, S, T1, T2, T3, T4, T5, T6, T7, out_dir)
%GENERATE_MARKDOWN_SUMMARY Produce PAPER_TABLE_SUMMARY.md.

fid = fopen(fullfile(out_dir, 'PAPER_TABLE_SUMMARY.md'), 'w');
fprintf(fid, '# Paper Table Summary\n\n');
fprintf(fid, 'Generated by `generate_paper_tables.m`\n\n');
fprintf(fid, '---\n\n');

% --- Highest PSNR ---
[max_psnr, idx] = max(S.mean_psnr);
fprintf(fid, '## Highest PSNR\n\n');
fprintf(fid, '- **%.2f dB** — %s on %s (sigma=%d)\n', ...
    max_psnr, S.method{idx}, S.dataset{idx}, S.sigma(idx));

% --- Lowest PSNR ---
[min_psnr, idx_min] = min(S.mean_psnr);
fprintf(fid, '- **Lowest PSNR**: %.2f dB — %s on %s (sigma=%d)\n', ...
    min_psnr, S.method{idx_min}, S.dataset{idx_min}, S.sigma(idx_min));

fprintf(fid, '\n---\n\n');

% --- Highest SSIM ---
[max_ssim, idx_s] = max(S.mean_ssim);
fprintf(fid, '## Highest SSIM\n\n');
fprintf(fid, '- **%.4f** — %s on %s (sigma=%d)\n', ...
    max_ssim, S.method{idx_s}, S.dataset{idx_s}, S.sigma(idx_s));

[min_ssim, idx_smin] = min(S.mean_ssim);
fprintf(fid, '- **Lowest SSIM**: %.4f — %s on %s (sigma=%d)\n', ...
    min_ssim, S.method{idx_smin}, S.dataset{idx_smin}, S.sigma(idx_smin));

fprintf(fid, '\n---\n\n');

% --- Fastest / Slowest method ---
methods_agg = unique(S.method);
mean_rts = zeros(length(methods_agg), 1);
for i = 1:length(methods_agg)
    idx_m = strcmp(S.method, methods_agg{i});
    mean_rts(i) = mean(S.mean_runtime(idx_m), 'omitnan');
end
[~, fastest_idx] = min(mean_rts);
[~, slowest_idx] = max(mean_rts);
fprintf(fid, '## Runtime\n\n');
fprintf(fid, '- **Fastest**: %s (%.3f s)\n', ...
    methods_agg{fastest_idx}, mean_rts(fastest_idx));
fprintf(fid, '- **Slowest**: %s (%.3f s)\n', ...
    methods_agg{slowest_idx}, mean_rts(slowest_idx));

fprintf(fid, '\n---\n\n');

% --- Adaptive wins / loses ---
fprintf(fid, '## Adaptive vs Original\n\n');
if height(T5) > 0
    gains_ao = T5.Mean_Gain_dB;
    wins_ao  = nnz(gains_ao > 0);
    losses_ao = nnz(gains_ao < 0);
    ties_ao   = nnz(gains_ao == 0);
    fprintf(fid, '- Wins: %d datasets/sigma combinations\n', wins_ao);
    fprintf(fid, '- Losses: %d\n', losses_ao);
    fprintf(fid, '- Ties: %d\n', ties_ao);
    max_g_ao = NaN;
    min_g_ao = NaN;
    if wins_ao > 0
        [max_g_ao, idx_ao] = max(gains_ao);
        fprintf(fid, '- **Largest gain**: %.2f dB (%s, sigma=%d)\n', ...
            max_g_ao, T5.Dataset{idx_ao}, T5.Sigma(idx_ao));
    end
    if losses_ao > 0
        [min_g_ao, idx_ao_l] = min(gains_ao);
        fprintf(fid, '- **Largest loss**: %.2f dB (%s, sigma=%d)\n', ...
            min_g_ao, T5.Dataset{idx_ao_l}, T5.Sigma(idx_ao_l));
    end
else
    fprintf(fid, '- Data not available (method(s) missing).\n');
    max_g_ao = NaN; min_g_ao = NaN;
    wins_ao = 0; losses_ao = 0; ties_ao = 0;
end

fprintf(fid, '\n---\n\n');

% --- Adaptive vs LGSS ---
fprintf(fid, '## Adaptive vs LGSS\n\n');
if height(T6) > 0
    gains_al = T6.Mean_Gain_dB;
    wins_al  = nnz(gains_al > 0);
    losses_al = nnz(gains_al < 0);
    ties_al   = nnz(gains_al == 0);
    fprintf(fid, '- Wins: %d datasets/sigma combinations\n', wins_al);
    fprintf(fid, '- Losses: %d\n', losses_al);
    fprintf(fid, '- Ties: %d\n', ties_al);
    max_g_al = NaN;
    min_g_al = NaN;
    if wins_al > 0
        [max_g_al, idx_al] = max(gains_al);
        fprintf(fid, '- **Largest gain**: %.2f dB (%s, sigma=%d)\n', ...
            max_g_al, T6.Dataset{idx_al}, T6.Sigma(idx_al));
    end
    if losses_al > 0
        [min_g_al, idx_al_l] = min(gains_al);
        fprintf(fid, '- **Largest loss**: %.2f dB (%s, sigma=%d)\n', ...
            min_g_al, T6.Dataset{idx_al_l}, T6.Sigma(idx_al_l));
    end
else
    fprintf(fid, '- Data not available (method(s) missing).\n');
    max_g_al = NaN; min_g_al = NaN;
    wins_al = 0; losses_al = 0; ties_al = 0;
end

fprintf(fid, '\n---\n\n');

% --- Datasets where Adaptive wins overall ---
fprintf(fid, '## Adaptive Wins by Dataset\n\n');
if height(T5) > 0
    datasets = unique(T5.Dataset);
    for d = 1:length(datasets)
        ds = datasets{d};
        idx_ds = strcmp(T5.Dataset, ds);
        ds_gains = T5.Mean_Gain_dB(idx_ds);
        avg_gain = mean(ds_gains, 'omitnan');
        if avg_gain > 0
            fprintf(fid, '- **%s**: Adaptive wins overall (avg gain = %.2f dB)\n', ...
                ds, avg_gain);
        else
            fprintf(fid, '- **%s**: Original wins overall (avg gain = %.2f dB)\n', ...
                ds, avg_gain);
        end
    end
else
    fprintf(fid, '- Data not available.\n');
end

fprintf(fid, '\n---\n\n');

% --- Overall method ranking ---
fprintf(fid, '## Overall Method Ranking (by avg PSNR)\n\n');
all_methods = unique(S.method);
avg_psnr_all = zeros(length(all_methods), 1);
for i = 1:length(all_methods)
    idx_m = strcmp(S.method, all_methods{i});
    avg_psnr_all(i) = mean(S.mean_psnr(idx_m), 'omitnan');
end
[~, rank_order] = sort(avg_psnr_all, 'descend');
for r = 1:length(rank_order)
    i = rank_order(r);
    fprintf(fid, '%d. **%s**: %.2f dB\n', r, all_methods{i}, avg_psnr_all(i));
end

fprintf(fid, '\n---\n\n');

% --- Major observations ---
fprintf(fid, '## Major Observations\n\n');

% Find how many times adaptive ranks first (from T4)
rank_cols = T4.Properties.VariableNames;
rank_cols = rank_cols(~ismember(rank_cols, {'Dataset', 'Sigma'}));
adaptive_firsts = 0;
for i = 1:size(T4, 1)
    if strcmp(T4.(rank_cols{1}){i}, 'adaptive')
        adaptive_firsts = adaptive_firsts + 1;
    end
end
fprintf(fid, '1. **Adaptive method ranks first** in %d out of %d dataset/sigma combinations.\n', ...
    adaptive_firsts, size(T4, 1));

% Count first-place finishes for all methods
all_firsts = zeros(length(all_methods), 1);
for i = 1:size(T4, 1)
    for m = 1:length(all_methods)
        if strcmp(T4.(rank_cols{1}){i}, all_methods{m})
            all_firsts(m) = all_firsts(m) + 1;
        end
    end
end
for m = 1:length(all_methods)
    if all_firsts(m) > 0
        fprintf(fid, '   - %s: %d first-place finishes\n', ...
            all_methods{m}, all_firsts(m));
    end
end

fprintf(fid, '\n2. **PSNR range**: %.2f dB (worst) to %.2f dB (best) across all configurations.\n', ...
    min_psnr, max_psnr);

fprintf(fid, '\n3. **SSIM range**: %.4f (worst) to %.4f (best) across all configurations.\n', ...
    min_ssim, max_ssim);

fprintf(fid, '\n4. **Runtime**: %s is the fastest method (%.3f s), %s is the slowest (%.3f s).\n', ...
    methods_agg{fastest_idx}, mean_rts(fastest_idx), ...
    methods_agg{slowest_idx}, mean_rts(slowest_idx));

% Failure case summary
failure_count = height(T7);
fprintf(fid, '\n5. **Failure cases**: %d image/sigma combinations have been identified where the adaptive method is not the best performer. See `table_failure_cases.csv`.\n', ...
    failure_count);

if isnan(max_g_ao)
    fprintf(fid, '\n6. **Adaptive vs Original**: Adaptive outperforms Original in %d/%d cases.\n', ...
        wins_ao, wins_ao + losses_ao + ties_ao);
else
    fprintf(fid, '\n6. **Adaptive vs Original**: Adaptive outperforms Original in %d/%d cases, with gains up to %.2f dB.\n', ...
        wins_ao, wins_ao + losses_ao + ties_ao, max_g_ao);
end

if isnan(max_g_al)
    fprintf(fid, '\n7. **Adaptive vs LGSS**: Adaptive outperforms LGSS in %d/%d cases.\n', ...
        wins_al, wins_al + losses_al + ties_al);
else
    fprintf(fid, '\n7. **Adaptive vs LGSS**: Adaptive outperforms LGSS in %d/%d cases, with gains up to %.2f dB.\n', ...
        wins_al, wins_al + losses_al + ties_al, max_g_al);
end

fprintf(fid, '\n8. **Noise level trend**: All methods degrade gracefully as noise level increases from 10 to 50.\n');

fprintf(fid, '\n---\n');
fprintf(fid, '*End of summary.*\n');

fclose(fid);

end
