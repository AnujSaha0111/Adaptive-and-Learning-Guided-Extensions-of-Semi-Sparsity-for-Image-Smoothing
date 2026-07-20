clc;
clear;
close all;

I0 = im2double(imread('Barbara.jpg'));
I  = im2double(imread('Barbara_noisy.png'));
edge_map = im2double(imread('edges/edge_map_Barbara.png'));

if ~isequal(size(I0), size(I))
    error('run_lgss:ImageSizeMismatch', ...
        'clean_image.png and noisy_image.png must have the same size.');
end

if ndims(edge_map) == 3
    edge_map = mean(edge_map, 3);
end

[N, M, ~] = size(I);
if ~isequal(size(edge_map), [N M])
    error('run_lgss:EdgeMapSizeMismatch', ...
        'edge_map.png must have size %d-by-%d to match the input image.', N, M);
end

edge_map = min(max(edge_map, 0), 1);
W = 1 - edge_map;
W = min(max(W, 0), 1);

S = lgss_solver(I, W);
S = min(max(S, 0), 1);

psnr_val = compute_psnr(I0, S);
fprintf('LGSS PSNR = %.4f dB\n', psnr_val);

figure;
imshow([I, S]);
title(['Noisy Input | LGSS Result (PSNR = ', num2str(psnr_val), ' dB)']);

figure;
imshow(W, []);
title('Spatial Weight Map W = 1 - E');
