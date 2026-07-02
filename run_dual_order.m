clc;
clear;
close all;

% I0 = im2double(imread('strip_gt.png'));
% I  = im2double(imread('strip_noise.png'));
% I = im2double(imread('Barbara_noisy.png'));
% I0  = im2double(imread('Barbara.jpg'));
% I = im2double(imread('Cameraman_noisy.png'));
% I0  = im2double(imread('Cameraman.jpg'));
I = im2double(imread('lena_noisy.png'));
I0  = im2double(imread('lena.jpg'));

S_dual = semi_sparsity_core(I);

psnr_val = compute_psnr(I0, S_dual);

fprintf('Dual-Order PSNR = %.4f dB\n', psnr_val);

imshow([I S_dual]);
title(['Dual-Order Semi-Sparsity (PSNR = ',num2str(psnr_val),' dB)']);