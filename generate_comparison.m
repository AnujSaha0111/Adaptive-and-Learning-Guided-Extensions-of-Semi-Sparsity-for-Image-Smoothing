clc;
clear;
close all;

images = {'lena', 'cameraman', 'barbara', 'strip'};
edge_files = {'edge_map_Lena.png', 'edge_map_Cameraman.png', 'edge_map_Barbara.png', 'edge_map_strip_noise.png'};
clean_files = {'lena.png', 'Cameraman.jpg', 'Barbara.jpg', 'strip_gt.png'};
noisy_files = {'lena_noisy.png', 'Cameraman_noisy.png', 'Barbara_noisy.png', 'strip_noise.png'};

for i = 1:length(images)
    name = images{i};
    fprintf('Processing %s...\n', name);
    
    I = im2double(imread(noisy_files{i}));
    I0 = im2double(imread(clean_files{i}));
    edge_map = im2double(imread(['edges/' edge_files{i}]));
    
    if ndims(edge_map) == 3
        edge_map = mean(edge_map, 3);
    end
    
    [N, M, D] = size(I);
    if ~isequal(size(edge_map), [N M])
        edge_map = imresize(edge_map, [N M]);
    end
    
    edge_map = min(max(edge_map, 0), 1);
    W = 1 - edge_map;
    W = min(max(W, 0), 1);
    
    S = semi_sparsity_lgss(I, W);
    S = min(max(S, 0), 1);
    
    lgss_path = ['output/' name '_semi_sparsity_lgss_res.png'];
    imwrite(S, lgss_path);
    fprintf('Saved: %s\n', lgss_path);
    
    psnr_val = compute_psnr(I0, S);
    fprintf('LGSS PSNR = %.4f dB\n', psnr_val);
end

fprintf('\n--- Generating comparison images ---\n');

for i = 1:length(images)
    name = images{i};
    
    noisy = im2double(imread(['output/' name '_semi_sparsity_noise.png']));
    semi = im2double(imread(['output/' name '_semi_sparsity_res.png']));
    adaptive = im2double(imread(['output/' name '_semi_sparsity_adaptive_res.png']));
    lgss = im2double(imread(['output/' name '_semi_sparsity_lgss_res.png']));
    
    sz = size(noisy);
    semi = imresize(semi, [sz(1) sz(2)]);
    adaptive = imresize(adaptive, [sz(1) sz(2)]);
    lgss = imresize(lgss, [sz(1) sz(2)]);
    
    comp_img = [noisy, semi, adaptive, lgss];
    
    out_path = ['output/' name '_comparison.png'];
    imwrite(comp_img, out_path);
    fprintf('Saved: %s\n', out_path);
end

fprintf('Done!\n');