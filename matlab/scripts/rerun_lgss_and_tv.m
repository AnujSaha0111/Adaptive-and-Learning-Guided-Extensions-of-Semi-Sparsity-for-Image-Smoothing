function rerun_lgss_and_tv()

fprintf('========================================\n');
fprintf('RERUN LGSS + TV ONLY\n');
fprintf('========================================\n\n');

fprintf('Step 1: Backing up old LGSS/TV results...\n');
old_results = readtable(fullfile('results', 'results_table.csv'));
old_lgss = old_results(strcmp(old_results.method, 'lgss'), :);
old_tv = old_results(strcmp(old_results.method, 'tv'), :);
writetable(old_lgss, fullfile('results', 'lgss_old_backup.csv'));
writetable(old_tv, fullfile('results', 'tv_old_backup.csv'));
fprintf('  Saved lgss_old_backup.csv (%d rows)\n', height(old_lgss));
fprintf('  Saved tv_old_backup.csv (%d rows)\n\n', height(old_tv));

unchanged_mask = ~strcmp(old_results.method, 'lgss') & ~strcmp(old_results.method, 'tv');
unchanged = old_results(unchanged_mask, :);
fprintf('Step 2: Keeping %d rows for unchanged methods\n\n', height(unchanged));

fprintf('Step 3: Rerunning LGSS and TV...\n\n');
cfg = experiment_config();
edge_dir = fullfile(pwd, 'edges');

new_results = {};

for d = 1:length(cfg.datasets)
    dataset_name = cfg.datasets{d};
    fprintf('========================================\n');
    fprintf('Dataset: %s\n', dataset_name);
    fprintf('========================================\n');

    images = load_dataset(dataset_name);

    for i = 1:length(images)
        img_struct = images(i);
        if isempty(img_struct.image)
            fprintf('  Skipping %s (not found)\n', img_struct.name);
            continue;
        end

        clean = img_struct.image;
        fprintf('  Image: %s (%d x %d)\n', img_struct.name, ...
            img_struct.height, img_struct.width);

        for s = 1:length(cfg.noise_levels)
            sigma = cfg.noise_levels(s);
            fprintf('    Sigma = %d\n', sigma);

            for r = 1:cfg.num_realizations
                seed = cfg.base_seed + (r - 1);

                noisy = add_gaussian_noise(clean, sigma, seed);

                edge_map = load_edge_map(edge_dir, img_struct.name, ...
                    size(clean, 1), size(clean, 2));

                func_lgss = @(x) denoise_lgss(x, edge_map);
                [denoised_lgss, rt_lgss] = benchmark_runtime(func_lgss, noisy);
                psnr_lgss = compute_psnr(clean, denoised_lgss);
                ssim_lgss = compute_ssim(clean, denoised_lgss);
                fprintf('        LGSS: PSNR = %.2f dB, SSIM = %.4f, runtime = %.2f s\n', ...
                    psnr_lgss, ssim_lgss, rt_lgss);
                new_results{end+1} = {dataset_name, img_struct.name, sigma, r, ...
                    'lgss', psnr_lgss, ssim_lgss, rt_lgss};

                [denoised_tv, rt_tv] = benchmark_runtime(@denoise_tv, noisy);
                psnr_tv = compute_psnr(clean, denoised_tv);
                ssim_tv = compute_ssim(clean, denoised_tv);
                fprintf('        TV:   PSNR = %.2f dB, SSIM = %.4f, runtime = %.2f s\n', ...
                    psnr_tv, ssim_tv, rt_tv);
                new_results{end+1} = {dataset_name, img_struct.name, sigma, r, ...
                    'tv', psnr_tv, ssim_tv, rt_tv};
            end
        end
    end
end

fprintf('\nStep 4: Merging results...\n');
new_table = cell2table(new_results, 'VariableNames', ...
    {'dataset', 'image', 'sigma', 'realization', 'method', 'psnr', 'ssim', 'runtime'});
merged = [unchanged; new_table];
merged = sortrows(merged, {'dataset', 'sigma', 'image', 'realization', 'method'});

writetable(merged, fullfile('results', 'results_table.csv'));
fprintf('  Merged results_table.csv (%d rows)\n\n', height(merged));

fprintf('Step 5: Regenerating summary statistics...\n');
analyze_results(fullfile('results', 'results_table.csv'));

fprintf('\nStep 6: Regenerating paper tables...\n');
generate_paper_tables();

fprintf('\nStep 7: Regenerating result plots...\n');
generate_result_plots();

fprintf('\nStep 8: Regenerating statistical tests...\n');
perform_statistical_tests();

fprintf('\n========================================\n');
fprintf('ALL OUTPUTS REGENERATED\n');
fprintf('========================================\n');

end

function edge_map = load_edge_map(edge_dir, img_name, target_h, target_w)
[~, base, ~] = fileparts(img_name);

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
    edge_map = generate_canny_edge_map(img_name, target_h, target_w);
    if ~exist(edge_dir, 'dir')
        mkdir(edge_dir);
    end
    imwrite(edge_map, edge_path);
end

end

function edge_map = generate_canny_edge_map(img_name, target_h, target_w)
[~, ~, ~] = fileparts(img_name);

dataset_dirs = {'Set12', 'BSD68', 'Kodak24', 'custom'};
img_path = '';
for d = 1:length(dataset_dirs)
    candidate = fullfile(pwd, 'datasets', dataset_dirs{d}, img_name);
    if exist(candidate, 'file')
        img_path = candidate;
        break;
    end
end

if isempty(img_path)
    candidate = fullfile(pwd, img_name);
    if exist(candidate, 'file')
        img_path = candidate;
    end
end

if isempty(img_path)
    warning('Cannot locate %s. Using zeros.', img_name);
    edge_map = zeros(target_h, target_w);
    return;
end

img = im2double(imread(img_path));
if size(img, 3) == 3
    img = rgb2gray(img);
end

img_smooth = imgaussfilt(img, 1.0);
edge_binary = edge(img_smooth, 'Canny');
D = bwdist(edge_binary);
sigma_scale = 3.0;
edge_map = exp(-D / sigma_scale);
edge_map = min(max(edge_map, 0), 1);

if size(edge_map, 1) ~= target_h || size(edge_map, 2) ~= target_w
    edge_map = imresize(edge_map, [target_h, target_w]);
end

end
