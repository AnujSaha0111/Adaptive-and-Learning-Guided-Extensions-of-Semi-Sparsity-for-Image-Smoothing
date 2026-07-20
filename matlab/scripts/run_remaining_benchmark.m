function run_remaining_benchmark()
%RUN_REMAINING_BENCHMARK Run only the missing datasets, append to existing results.
%   RUN_REMAINING_BENCHMARK() runs BSD68, Kodak24, and custom with:
%     - 1 realization per image per sigma
%     - All 4 noise levels [10, 20, 25, 50]
%     - All 7 methods
%     - Incremental saving (survives interruption)
%
%   Existing Set12 results are preserved.
%   After completion, calls analyze_results, generate_result_plots,
%   generate_paper_tables, perform_statistical_tests.

setup_paths();

%% Config
cfg.noise_levels = [10, 20, 25, 50];
cfg.num_realizations = 1;
cfg.methods = {'original', 'adaptive', 'lgss', 'bilateral', 'guided', 'tv', 'l0'};
cfg.base_seed = 2026;
cfg.save_images = false;
cfg.compute_ssim = true;
cfg.compute_runtime = true;
cfg.output_dir = 'results';

datasets = {'BSD68', 'Kodak24', 'custom'};

%% Estimate time
fprintf('\n========================================\n');
fprintf('  REMAINING BENCHMARK (no re-run of Set12)\n');
fprintf('========================================\n');
fprintf('Datasets:   %s\n', strjoin(datasets, ', '));
fprintf('Sigmas:     %s\n', num2str(cfg.noise_levels));
fprintf('Realizations: %d\n', cfg.num_realizations);
fprintf('Methods:    %s\n', strjoin(cfg.methods, ', '));
fprintf('\n');

total_images = 0;
for d = 1:length(datasets)
    imgs = load_dataset(datasets{d});
    n = sum(~cellfun(@isempty, {imgs.image}));
    total_images = total_images + n;
    fprintf('  %s: %d images\n', datasets{d}, n);
end

total_runs = total_images * length(cfg.noise_levels) * cfg.num_realizations * length(cfg.methods);
est_per_run = 12;  % conservative average seconds
est_total = total_runs * est_per_run;
fprintf('\nTotal experiments: %d\n', total_runs);
fprintf('Estimated time:    ~%.0f min (~%.1f hours)\n', est_total/60, est_total/3600);

edge_dir = fullfile(pwd, 'edges');

%% Load existing results
existing_csv = fullfile(cfg.output_dir, 'results_table.csv');
if exist(existing_csv, 'file')
    existing = readtable(existing_csv);
    fprintf('\nExisting results: %d rows (Set12)\n', height(existing));
else
    existing = cell2table({}, 'VariableNames', ...
        {'dataset','image','sigma','realization','method','psnr','ssim','runtime'});
    fprintf('No existing results found.\n');
end

%% Run experiments
pipeline_start = tic;
new_results = {};
total_done = 0;

for d = 1:length(datasets)
    dataset_name = datasets{d};
    images = load_dataset(dataset_name);
    
    fprintf('\n========================================\n');
    fprintf('Dataset: %s\n', dataset_name);
    fprintf('========================================\n');
    
    for i = 1:length(images)
        img_struct = images(i);
        if isempty(img_struct.image)
            fprintf('  Skipping %s (not found)\n', img_struct.name);
            continue;
        end
        
        clean = img_struct.image;
        fprintf('  Image: %s (%dx%d)\n', img_struct.name, img_struct.height, img_struct.width);
        
        % Load edge map once per image
        edge_map = load_edge_map_fn(edge_dir, img_struct.name, ...
            size(clean, 1), size(clean, 2));
        
        for s = 1:length(cfg.noise_levels)
            sigma = cfg.noise_levels(s);
            
            for r = 1:cfg.num_realizations
                seed = cfg.base_seed + (r - 1);
                noisy = add_gaussian_noise(clean, sigma, seed);
                
                for m = 1:length(cfg.methods)
                    method = cfg.methods{m};
                    
                    switch method
                        case 'original',  func = @denoise_original;
                        case 'adaptive',  func = @denoise_adaptive;
                        case 'lgss',      func = @(x) denoise_lgss(x, edge_map);
                        case 'bilateral', func = @(x) denoise_bilateral(x);
                        case 'guided',    func = @(x) denoise_guided(x);
                        case 'tv',        func = @(x) denoise_tv(x);
                        case 'l0',        func = @(x) denoise_l0(x);
                    end
                    
                    [denoised, runtime] = benchmark_runtime(func, noisy);
                    psnr_val = compute_psnr(clean, denoised);
                    ssim_val = compute_ssim(clean, denoised);
                    
                    row = {dataset_name, img_struct.name, sigma, r, ...
                           method, psnr_val, ssim_val, runtime};
                    new_results = [new_results; row]; %#ok<AGROW>
                    total_done = total_done + 1;
                end
                
                fprintf('    sigma=%d r=%d done (%d/%d total) [%.1f min elapsed]\n', ...
                    sigma, r, total_done, total_runs, toc(pipeline_start)/60);
            end
        end
        
        % Incremental save after each image
        merged = [existing; cell2table(new_results, 'VariableNames', ...
            {'dataset','image','sigma','realization','method','psnr','ssim','runtime'})];
        writetable(merged, existing_csv);
    end
end

elapsed = toc(pipeline_start);
fprintf('\n========================================\n');
fprintf('DONE in %.1f min (%.1f hours)\n', elapsed/60, elapsed/3600);
fprintf('New experiments: %d\n', total_done);
fprintf('Total rows: %d\n', height(merged));
fprintf('========================================\n');

%% Generate outputs
fprintf('\nGenerating analysis outputs...\n');
analyze_results(existing_csv);
generate_result_plots();
generate_paper_tables();
perform_statistical_tests();

fprintf('\nAll outputs generated.\n');
fprintf('Run generate_execution_summary next to create EXECUTION_SUMMARY.md.\n');

end

%% Helper
function edge_map = load_edge_map_fn(edge_dir, img_name, target_h, target_w)
[~, base, ~] = fileparts(img_name);
switch lower(base)
    case 'lena',      edge_fname = 'edge_map_Lena.png';
    case 'barbara',   edge_fname = 'edge_map_Barbara.png';
    case 'cameraman', edge_fname = 'edge_map_Cameraman.png';
    case 'strip_gt',  edge_fname = 'edge_map_strip_noise.png';
    otherwise,        edge_fname = sprintf('edge_map_%s.png', base);
end
edge_path = fullfile(edge_dir, edge_fname);
if exist(edge_path, 'file')
    edge_map = im2double(imread(edge_path));
    if ndims(edge_map) == 3, edge_map = mean(edge_map, 3); end
    if size(edge_map,1) ~= target_h || size(edge_map,2) ~= target_w
        edge_map = imresize(edge_map, [target_h, target_w]);
    end
else
    edge_map = zeros(target_h, target_w);
end
end
