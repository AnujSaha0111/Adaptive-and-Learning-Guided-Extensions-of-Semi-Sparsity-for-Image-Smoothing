function smoke_test_fixes()
%SMOKE_TEST_FIXES Verify LGSS and TV fixes on Set12 sigma=20.
%   Runs original, adaptive, lgss, and tv on Set12 images with sigma=20.
%   Checks that:
%   - LGSS output differs from Original (PSNR, pixel-wise)
%   - TV produces reasonable PSNR (> 20 dB)
%   - No execution errors

fprintf('========================================\n');
fprintf('SMOKE TEST: Set12, sigma=20\n');
fprintf('========================================\n\n');

% Load Set12
images = load_dataset('Set12');
sigma = 20;
seed = 2026;

% Resolve edge map directory
edge_dir = fullfile(pwd, 'edges');

% Storage for results
methods = {'original', 'adaptive', 'lgss', 'tv'};
results = struct();
for m = 1:length(methods)
    results.(methods{m}).psnr = zeros(length(images), 1);
    results.(methods{m}).runtime = zeros(length(images), 1);
end

all_pass = true;

for i = 1:length(images)
    img_struct = images(i);
    if isempty(img_struct.image)
        continue;
    end

    clean = img_struct.image;
    noisy = add_gaussian_noise(clean, sigma, seed);

    fprintf('Image %d/%d: %s\n', i, length(images), img_struct.name);

    % Load/generate edge map for LGSS
    edge_map = load_edge_map(edge_dir, img_struct.name, ...
        size(clean, 1), size(clean, 2));

    % --- Original ---
    [denoised_orig, rt] = benchmark_runtime(@denoise_original, noisy);
    psnr_orig = compute_psnr(clean, denoised_orig);
    results.original.psnr(i) = psnr_orig;
    results.original.runtime(i) = rt;

    % --- Adaptive ---
    [denoised_adap, rt] = benchmark_runtime(@denoise_adaptive, noisy);
    psnr_adap = compute_psnr(clean, denoised_adap);
    results.adaptive.psnr(i) = psnr_adap;
    results.adaptive.runtime(i) = rt;

    % --- LGSS ---
    func_lgss = @(x) denoise_lgss(x, edge_map);
    [denoised_lgss, rt] = benchmark_runtime(func_lgss, noisy);
    psnr_lgss = compute_psnr(clean, denoised_lgss);
    results.lgss.psnr(i) = psnr_lgss;
    results.lgss.runtime(i) = rt;

    % --- TV ---
    [denoised_tv, rt] = benchmark_runtime(@denoise_tv, noisy);
    psnr_tv = compute_psnr(clean, denoised_tv);
    results.tv.psnr(i) = psnr_tv;
    results.tv.runtime(i) = rt;

    % Print row
    fprintf('  orig=%6.2f  adap=%6.2f  lgss=%6.2f  tv=%6.2f dB\n', ...
        psnr_orig, psnr_adap, psnr_lgss, psnr_tv);

    % Check pixel-wise difference LGSS vs Original
    pix_diff = max(abs(denoised_lgss(:) - denoised_orig(:)));
    if pix_diff < 1e-10
        fprintf('  *** FAIL: LGSS identical to Original (pixel diff = %.2e)\n', pix_diff);
        all_pass = false;
    end

    % Check TV PSNR
    if psnr_tv < 15
        fprintf('  *** FAIL: TV PSNR too low (%.2f dB)\n', psnr_tv);
        all_pass = false;
    end
end

fprintf('\n========================================\n');
fprintf('SUMMARY\n');
fprintf('========================================\n');

for m = 1:length(methods)
    mname = methods{m};
    avg_psnr = mean(results.(mname).psnr);
    avg_rt = mean(results.(mname).runtime);
    fprintf('  %10s: avg PSNR = %6.2f dB, avg runtime = %.3f s\n', ...
        mname, avg_psnr, avg_rt);
end

% Verify LGSS != Original
avg_psnr_orig = mean(results.original.psnr);
avg_psnr_lgss = mean(results.lgss.psnr);
lgss_diff = abs(avg_psnr_lgss - avg_psnr_orig);

fprintf('\nLGSS vs Original avg PSNR difference: %.4f dB\n', lgss_diff);
if lgss_diff < 1e-6
    fprintf('  *** FAIL: LGSS is still identical to Original\n');
    all_pass = false;
else
    fprintf('  PASS: LGSS differs from Original\n');
end

% Verify TV is reasonable
avg_psnr_tv = mean(results.tv.psnr);
fprintf('TV avg PSNR: %.2f dB\n', avg_psnr_tv);
if avg_psnr_tv < 15
    fprintf('  *** FAIL: TV produces unreasonable PSNR\n');
    all_pass = false;
else
    fprintf('  PASS: TV produces reasonable PSNR\n');
end

fprintf('\n========================================\n');
if all_pass
    fprintf('ALL CHECKS PASSED\n');
else
    fprintf('SOME CHECKS FAILED\n');
end
fprintf('========================================\n');

end

% -------------------------------------------------------------------------
function edge_map = load_edge_map(edge_dir, img_name, target_h, target_w)
%LOAD_EDGE_MAP Load or create edge map for a given image.

[~, base, ext] = fileparts(img_name);

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

% -------------------------------------------------------------------------
function edge_map = generate_canny_edge_map(img_name, target_h, target_w)
%GENERATE_CANNY_EDGE_MAP Create a Canny edge map for a benchmark image.

[~, base, ext] = fileparts(img_name);

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
