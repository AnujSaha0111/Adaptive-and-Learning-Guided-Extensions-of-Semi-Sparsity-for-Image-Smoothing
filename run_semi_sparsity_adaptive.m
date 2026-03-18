clc;
clear;
close all;

% Load images
% I0 = im2double(imread('strip_gt.png'));
% I  = im2double(imread('strip_noise.png'));
I = im2double(imread('Barbara_noisy.png'));
I0  = im2double(imread('Barbara.jpg'));
% I = im2double(imread('Cameraman_noisy.png'));
% I0  = im2double(imread('Cameraman.jpg'));
% I = im2double(imread('lena_noisy.png'));
% I0  = im2double(imread('lena.png'));

[N,M,D] = size(I);
sizeI2D = [N M];

% gradient operators
Dx = [1 -1]/2;
Dy = Dx';

fxx = [1 -2 1]/4;
fyy = fxx';
fuu = [1 0 0; 0 -2 0; 0 0 1]/4;
fvv = [0 0 1; 0 -2 0; 1 0 0]/4;

otfDx  = psf2otf(Dx, sizeI2D);
otfDy  = psf2otf(Dy, sizeI2D);
otfFxx = psf2otf(fxx, sizeI2D);
otfFyy = psf2otf(fyy, sizeI2D);
otfFuu = psf2otf(fuu, sizeI2D);
otfFvv = psf2otf(fvv, sizeI2D);

Denormin1 = abs(otfDx).^2 + abs(otfDy).^2;
Denormin2 = abs(otfFxx).^2 + abs(otfFyy).^2 + ...
            abs(otfFuu).^2 + abs(otfFvv).^2;

if D > 1
    Denormin1 = repmat(Denormin1,[1 1 D]);
    Denormin2 = repmat(Denormin2,[1 1 D]);
end

% parameters
alpha = 0.1;
beta  = 0.02;
lambda = 10 * beta;
lambda_max = 1e8;
kappa = 1.2;
tau   = 0.95;
iter_max = 500;

S = I;
Normin0 = fft2(S);
errs = zeros(iter_max,1);
iter = 1;

% HQS Optimization Loop
while lambda <= lambda_max && iter <= iter_max

    Denormin = 1 + alpha*Denormin1 + lambda*Denormin2;

    % First-order gradients
    gx = imfilter(S, Dx, 'circular');
    gy = imfilter(S, Dy, 'circular');

    % Compute gradient magnitude (2D weight map)
    if D == 1
        grad_mag = sqrt(gx.^2 + gy.^2);
    else
        grad_mag = sqrt(sum(gx.^2 + gy.^2,3));
    end

    gamma = 10;     % try 5, 10, 15
    eta   = 2;   % try 2 or 3
    w = exp(-gamma * grad_mag);  % 2D weight map
    beta_map = beta * (w.^eta);               % 2D adaptive beta

    % Second-order gradients
    gxx = imfilter(S, fxx, 'circular');
    gyy = imfilter(S, fyy, 'circular');
    guu = imfilter(S, fuu, 'circular');
    gvv = imfilter(S, fvv, 'circular');

    % Adaptive L0 thresholding
    if D == 1
        mask = (gxx.^2 + gyy.^2 + guu.^2 + gvv.^2) < beta_map/lambda;
    else
        tmp = gxx.^2 + gyy.^2 + guu.^2 + gvv.^2;
        mask2D = sum(tmp,3) < beta_map/lambda;
        mask = repmat(mask2D,[1 1 D]);
    end

    gxx(mask)=0;
    gyy(mask)=0;
    guu(mask)=0;
    gvv(mask)=0;

    % Divergence
    Normin1 = circshift(imfilter(gx, Dx(end:-1:1),'circular'),[0 1]) + ...
              circshift(imfilter(gy, Dy(end:-1:1),'circular'),[1 0]);

    Normin2 = imfilter(gxx,fxx(end:-1:1),'circular') + ...
              imfilter(gyy,fyy(end:-1:1),'circular') + ...
              imfilter(guu,fuu(end:-1:1,end:-1:1),'circular') + ...
              imfilter(gvv,fvv(end:-1:1,end:-1:1),'circular');

    FS = (Normin0 + alpha*fft2(Normin1) + lambda*fft2(Normin2)) ./ Denormin;
    S  = real(ifft2(FS));

    errs(iter) = mean((S(:)-I0(:)).^2);

    alpha  = tau * alpha;
    lambda = kappa * lambda;
    iter = iter + 1;
end

errs = errs(1:iter-1);

% psnr
psnr_val = psnr( ...
    I0(13:end-12,13:end-12,:), ...
    min(1,max(0,S(13:end-12,13:end-12,:))) ...
);

fprintf('Adaptive PSNR = %.4f dB\n', psnr_val);

% imwrite(S,'output/strip_semi_sparsity_adaptive_res.png');
% imwrite(S,'output/lena_semi_sparsity_adaptive_res.png');
% imwrite(S,'output/cameraman_semi_sparsity_adaptive_res.png');
imwrite(S,'output/barbara_semi_sparsity_adaptive_res.png');

figure;
imshow([I S]);
title(['Adaptive Semi-Sparsity (PSNR = ',num2str(psnr_val),' dB)']);

figure;
plot(errs,'LineWidth',1.5);
xlabel('Iteration');
ylabel('MSE');
title('Adaptive Convergence Curve');
grid on;