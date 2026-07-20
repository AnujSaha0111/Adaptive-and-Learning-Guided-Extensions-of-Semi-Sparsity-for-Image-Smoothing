clc; clear; close all;

images = {'lena', 'cameraman', 'barbara', 'strip'};

for i = 1:length(images)
    
    name = images{i};
    
    noisy = im2double(imread(['output/' name '_semi_sparsity_noise.png']));
    semi  = im2double(imread(['output/' name '_semi_sparsity_res.png']));
    adaptive = im2double(imread(['output/' name '_semi_sparsity_adaptive_res.png']));
    
    lgss_path = ['output/' name '_semi_sparsity_lgss_res.png'];
    if exist(lgss_path, 'file')
        lgss = im2double(imread(lgss_path));
    else
        lgss = zeros(size(noisy));
    end

    sz = size(noisy);
    semi = imresize(semi, [sz(1) sz(2)]);
    adaptive = imresize(adaptive, [sz(1) sz(2)]);
    lgss = imresize(lgss, [sz(1) sz(2)]);

    comp_img = [noisy, semi, adaptive, lgss];

    imwrite(comp_img, ['output/' name '_comparison.png']);

    fprintf('Saved: %s_comparison.png\n', name);
end
