clc;
clear;
close all;

I0 = im2double(imread('strip_gt.png'));
I  = im2double(imread('strip_noise.png'));

I_down = imresize(I, 0.5);

S_coarse = semi_sparsity_solver(I_down);

S_coarse_up = imresize(S_coarse, [size(I,1) size(I,2)]);

S_multi = semi_sparsity_solver(I, S_coarse_up);

psnr_val = compute_psnr(I0, S_multi);

fprintf('Coarse-to-Fine Multi-scale PSNR = %.4f dB\n', psnr_val);

imshow([I S_multi]);
title(['Coarse-to-Fine Multi-Scale (PSNR = ',num2str(psnr_val),' dB)']);
