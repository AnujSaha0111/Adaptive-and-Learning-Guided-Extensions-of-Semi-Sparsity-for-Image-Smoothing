function rerun_lgss_and_tv_resume()

results_file    = fullfile('results', 'results_table.csv');
done_keys_file  = fullfile('results', 'lgss_tv_done_keys.txt');
new_csv_file    = fullfile('results', 'lgss_tv_new.csv');
old_backup_dir  = fullfile('results');

done_keys = {};
if exist(done_keys_file, 'file')
    fid = fopen(done_keys_file, 'r');
    if fid ~= -1
        line = fgetl(fid);
        while ischar(line)
            done_keys{end+1} = strtrim(line);
            line = fgetl(fid);
        end
        fclose(fid);
    end
    fprintf('Resuming: %d combos already completed.\n', length(done_keys));
else
    fprintf('No checkpoint found -- starting from scratch.\n');
end

if ~exist(fullfile(old_backup_dir, 'lgss_old_backup.csv'), 'file')
    fprintf('Step 1: Backing up old LGSS/TV results...\n');
    old_results = readtable(results_file);
    old_lgss = old_results(strcmp(old_results.method, 'lgss'), :);
    old_tv   = old_results(strcmp(old_results.method, 'tv'), :);
    writetable(old_lgss, fullfile(old_backup_dir, 'lgss_old_backup.csv'));
    writetable(old_tv,   fullfile(old_backup_dir, 'tv_old_backup.csv'));
    fprintf('  Saved backups (%d LGSS + %d TV rows)\n\n', ...
        height(old_lgss), height(old_tv));
end

old_results = readtable(results_file);
unchanged_mask = ~strcmp(old_results.method, 'lgss') & ...
                 ~strcmp(old_results.method, 'tv');
unchanged = old_results(unchanged_mask, :);
fprintf('Step 2: Keeping %d rows for unchanged methods.\n\n', height(unchanged));

cfg = experiment_config();
cfg.num_realizations = 1;
edge_dir = fullfile(pwd, 'edges');

all_combos = {};
for d = 1:length(cfg.datasets)
    images = load_dataset(cfg.datasets{d});
    for i = 1:length(images)
        for s = 1:length(cfg.noise_levels)
            for r = 1:cfg.num_realizations
                all_combos{end+1} = struct( ...
                    'dataset', cfg.datasets{d}, ...
                    'image', images(i).name, ...
                    'sigma', cfg.noise_levels(s), ...
                    'realization', r, ...
                    'img_struct', images(i));
            end
        end
    end
end

remaining = {};
for c = 1:length(all_combos)
    combo = all_combos{c};
    key = sprintf('%s|%s|%d|%d', combo.dataset, combo.image, ...
        combo.sigma, combo.realization);
    if ~ismember(key, done_keys)
        remaining{end+1} = combo;
    end
end

fprintf('Total combos: %d   Already done: %d   Remaining: %d\n\n', ...
    length(all_combos), length(done_keys), length(remaining));

if isempty(remaining)
    fprintf('All combos completed. Proceeding to merge.\n\n');
end

if ~exist(new_csv_file, 'file')
    fid_csv = fopen(new_csv_file, 'w');
    fprintf(fid_csv, 'dataset,image,sigma,realization,method,psnr,ssim,runtime\n');
    fclose(fid_csv);
end

current_dataset = '';
for c = 1:length(remaining)
    combo = remaining{c};
    dataset_name = combo.dataset;

    if ~strcmp(dataset_name, current_dataset)
        fprintf('========================================\n');
        fprintf('Dataset: %s\n', dataset_name);
        fprintf('========================================\n');
        current_dataset = dataset_name;
    end

    img_struct = combo.img_struct;
    if isempty(img_struct.image)
        continue;
    end
    clean = img_struct.image;
    sigma = combo.sigma;
    r = combo.realization;
    key = sprintf('%s|%s|%d|%d', dataset_name, img_struct.name, sigma, r);

    seed = cfg.base_seed + (r - 1);
    noisy = add_gaussian_noise(clean, sigma, seed);

    edge_map = load_edge_map(edge_dir, img_struct.name, ...
        size(clean, 1), size(clean, 2));

    func_lgss = @(x) denoise_lgss(x, edge_map);
    [denoised_lgss, rt_lgss] = benchmark_runtime(func_lgss, noisy);
    psnr_lgss = compute_psnr(clean, denoised_lgss);
    ssim_lgss = compute_ssim(clean, denoised_lgss);
    fprintf('  %s | %s | sigma=%d | LGSS  PSNR=%.2f  SSIM=%.4f  rt=%.2fs\n', ...
        dataset_name, img_struct.name, sigma, psnr_lgss, ssim_lgss, rt_lgss);

    fid_csv = fopen(new_csv_file, 'a');
    fprintf(fid_csv, '%s,%s,%d,%d,lgss,%.10f,%.10f,%.10f\n', ...
        dataset_name, img_struct.name, sigma, r, psnr_lgss, ssim_lgss, rt_lgss);
    fclose(fid_csv);

    [denoised_tv, rt_tv] = benchmark_runtime(@denoise_tv, noisy);
    psnr_tv = compute_psnr(clean, denoised_tv);
    ssim_tv = compute_ssim(clean, denoised_tv);
    fprintf('  %s | %s | sigma=%d | TV    PSNR=%.2f  SSIM=%.4f  rt=%.2fs\n', ...
        dataset_name, img_struct.name, sigma, psnr_tv, ssim_tv, rt_tv);

    fid_csv = fopen(new_csv_file, 'a');
    fprintf(fid_csv, '%s,%s,%d,%d,tv,%.10f,%.10f,%.10f\n', ...
        dataset_name, img_struct.name, sigma, r, psnr_tv, ssim_tv, rt_tv);
    fclose(fid_csv);

    fid_k = fopen(done_keys_file, 'a');
    fprintf(fid_k, '%s\n', key);
    fclose(fid_k);
end

fprintf('\nStep 5: Merging results...\n');
if exist(new_csv_file, 'file')
    new_table = readtable(new_csv_file);
    fprintf('  Loaded %d new rows from checkpoint CSV\n', height(new_table));
    merged = [unchanged; new_table];
else
    fprintf('  No new results found.\n');
    merged = unchanged;
end
merged = sortrows(merged, {'dataset', 'sigma', 'image', 'realization', 'method'});
writetable(merged, results_file);
fprintf('  Saved results_table.csv (%d rows)\n\n', height(merged));

fprintf('Step 6: Regenerating summary statistics...\n');
analyze_results(results_file);

fprintf('\nStep 7: Regenerating paper tables...\n');
generate_paper_tables();

fprintf('\nStep 8: Regenerating result plots...\n');
generate_result_plots();

fprintf('\nStep 9: Regenerating statistical tests...\n');
perform_statistical_tests();

if exist(done_keys_file, 'file'), delete(done_keys_file); end
if exist(new_csv_file, 'file'),   delete(new_csv_file);   end
fprintf('\n========================================\n');
fprintf('LGSS + TV RERUN COMPLETE\n');
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
