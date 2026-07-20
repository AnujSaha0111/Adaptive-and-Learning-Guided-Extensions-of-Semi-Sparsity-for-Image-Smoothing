clc;
clear;
close all;

I = im2double(imread('lena_noisy.png'));
I0  = im2double(imread('lena.jpg'));

S_dual = semi_sparsity_solver(I);

psnr_val = compute_psnr(I0, S_dual);

fprintf('Dual-Order PSNR = %.4f dB\n', psnr_val);

imshow([I S_dual]);
title(['Dual-Order Semi-Sparsity (PSNR = ',num2str(psnr_val),' dB)']);
