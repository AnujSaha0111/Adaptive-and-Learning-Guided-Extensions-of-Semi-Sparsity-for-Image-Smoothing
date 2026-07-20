function generate_result_plots(summary_file)
%GENERATE_RESULT_PLOTS Generate result visualization figures.
%   GENERATE_RESULT_PLOTS() reads results/summary_statistics.csv.
%   GENERATE_RESULT_PLOTS(SUMMARY_FILE) reads custom summary file.
%
%   Generates:
%     results/figures/psnr_vs_noise.png   - PSNR vs noise level
%     results/figures/ssim_vs_noise.png   - SSIM vs noise level
%     results/figures/runtime_comparison.png - Runtime bar chart

if nargin < 1
    summary_file = fullfile('results', 'summary_statistics.csv');
end

if ~exist(summary_file, 'file')
    error('generate_result_plots:FileNotFound', ...
        'Summary file not found: %s', summary_file);
end

S = readtable(summary_file);

fig_dir = fullfile('results', 'figures');
if ~exist(fig_dir, 'dir')
    mkdir(fig_dir);
end

% Determine which datasets and methods are present
datasets = unique(S.dataset);
canonical_order = {'original', 'adaptive', 'lgss', 'bilateral', 'guided', 'tv', 'l0'};
methods_in_data = unique(S.method);
method_order = canonical_order(ismember(canonical_order, methods_in_data));
num_methods = length(method_order);
colors = lines(num_methods);

% Generate plots per dataset
for d = 1:length(datasets)

    ds = datasets{d};
    ds_mask = strcmp(S.dataset, ds);
    ds_data = S(ds_mask, :);

    % --- 1. PSNR vs Noise Level ---
    figure('Visible', 'off');
    hold on;
    legend_entries = {};

    for m = 1:length(method_order)
        method = method_order{m};
        if ~any(strcmp(ds_data.method, method))
            continue;
        end
        idx = strcmp(ds_data.method, method);
        sigma_vals = ds_data.sigma(idx);
        psnr_vals  = ds_data.mean_psnr(idx);
        std_vals   = ds_data.std_psnr(idx);
        [sigma_vals, sort_idx] = sort(sigma_vals);
        psnr_vals = psnr_vals(sort_idx);
        std_vals  = std_vals(sort_idx);

        errorbar(sigma_vals, psnr_vals, std_vals, ...
            'o-', 'Color', colors(m, :), 'LineWidth', 1.5, ...
            'MarkerSize', 6, 'MarkerFaceColor', colors(m, :));
        legend_entries{end+1} = strrep(method, '_', ' ');
    end

    xlabel('Noise Level \sigma');
    ylabel('PSNR (dB)');
    title(sprintf('PSNR vs Noise Level — %s', ds));
    legend(legend_entries, 'Location', 'southwest');
    grid on;
    hold off;

    saveas(gcf, fullfile(fig_dir, sprintf('psnr_vs_noise_%s.png', ds)));
    close(gcf);
    fprintf('Saved: psnr_vs_noise_%s.png\n', ds);

    % --- 2. SSIM vs Noise Level ---
    figure('Visible', 'off');
    hold on;
    legend_entries = {};

    for m = 1:length(method_order)
        method = method_order{m};
        if ~any(strcmp(ds_data.method, method))
            continue;
        end
        idx = strcmp(ds_data.method, method);
        sigma_vals = ds_data.sigma(idx);
        ssim_vals  = ds_data.mean_ssim(idx);
        std_vals   = ds_data.std_ssim(idx);
        [sigma_vals, sort_idx] = sort(sigma_vals);
        ssim_vals = ssim_vals(sort_idx);
        std_vals  = std_vals(sort_idx);

        errorbar(sigma_vals, ssim_vals, std_vals, ...
            's--', 'Color', colors(m, :), 'LineWidth', 1.5, ...
            'MarkerSize', 6, 'MarkerFaceColor', colors(m, :));
        legend_entries{end+1} = strrep(method, '_', ' ');
    end

    xlabel('Noise Level \sigma');
    ylabel('SSIM');
    title(sprintf('SSIM vs Noise Level — %s', ds));
    legend(legend_entries, 'Location', 'southwest');
    grid on;
    hold off;

    saveas(gcf, fullfile(fig_dir, sprintf('ssim_vs_noise_%s.png', ds)));
    close(gcf);
    fprintf('Saved: ssim_vs_noise_%s.png\n', ds);

    % --- 3. Runtime Comparison (bar chart, aggregate across sigmas) ---
    figure('Visible', 'off');

    methods_present = {};
    runtime_means = [];
    runtime_stds  = [];

    for m = 1:length(method_order)
        method = method_order{m};
        if ~any(strcmp(ds_data.method, method))
            continue;
        end
        idx = strcmp(ds_data.method, method);
        runtime_means(end+1) = mean(ds_data.mean_runtime(idx), 'omitnan'); %#ok<AGROW>
        runtime_stds(end+1)  = mean(ds_data.std_runtime(idx), 'omitnan'); %#ok<AGROW>
        methods_present{end+1} = strrep(method, '_', ' '); %#ok<AGROW>
    end

    bar_handle = bar(runtime_means);
    bar_handle.FaceColor = 'flat';
    for b = 1:length(runtime_means)
        bar_handle.CData(b, :) = colors(b, :);
    end
    hold on;
    errorbar(1:length(runtime_means), runtime_means, runtime_stds, ...
        'k.', 'LineWidth', 1.5);
    hold off;

    set(gca, 'XTickLabel', methods_present);
    ylabel('Runtime (s)');
    title(sprintf('Runtime Comparison — %s', ds));
    grid on;

    saveas(gcf, fullfile(fig_dir, sprintf('runtime_comparison_%s.png', ds)));
    close(gcf);
    fprintf('Saved: runtime_comparison_%s.png\n', ds);

end

fprintf('\nAll figures saved to: %s\n', fig_dir);

end
