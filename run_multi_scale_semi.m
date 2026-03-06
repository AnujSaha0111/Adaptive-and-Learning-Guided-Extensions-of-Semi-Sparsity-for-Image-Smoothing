clc;
clear;
close all;

I0 = im2double(imread('strip_gt.png'));
I  = im2double(imread('strip_noise.png'));

% coarse level (downsampled)
I_down = imresize(I, 0.5);

S_coarse = semi_sparsity_core(I_down, 1);

S_coarse_up = imresize(S_coarse, [size(I,1) size(I,2)]);

% fine level (coarse initialization)
S_multi = semi_sparsity_core(I, 1, S_coarse_up);

% psnr calculation
psnr_val = psnr( ...
    I0(13:end-12,13:end-12,:), ...
    min(1,max(0,S_multi(13:end-12,13:end-12,:))) ...
);

fprintf('Coarse-to-Fine Multi-scale PSNR = %.4f dB\n', psnr_val);

imshow([I S_multi]);
title(['Coarse-to-Fine Multi-Scale (PSNR = ',num2str(psnr_val),' dB)']);