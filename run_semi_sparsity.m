clc;
clear;
close all;

% loading images input
% I0 = im2double(imread('strip_gt.png'));      % Ground truth
% I  = im2double(imread('strip_noise.png'));   % Noisy input
I = im2double(imread('Barbara_noisy.png'));
I0  = im2double(imread('Barbara.jpg'));
% I = im2double(imread('Cameraman_noisy.png'));
% I0  = im2double(imread('Cameraman.jpg'));
% I = im2double(imread('lena_noisy.png'));
% I0  = im2double(imread('lena.jpg'));

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

% parameters (as per the paper)
alpha = 0.1;
beta  = 0.02;
lambda = 10 * beta;
lambda_max = 1e8;
kappa = 1.2;
tau   = 0.95;
iter_max = 500;

% initialisation
S = I;
Normin0 = fft2(S);
errs = zeros(iter_max,1);
iter = 1;

% HQS OPTIMIZATION LOOP 
while lambda <= lambda_max && iter <= iter_max
    Denormin = 1 + alpha*Denormin1 + lambda*Denormin2;
    % First-order gradients
    gx = imfilter(S, Dx, 'circular');
    gy = imfilter(S, Dy, 'circular');
    % Second-order gradients (SEMI-SPARSITY)
    gxx = imfilter(S, fxx, 'circular');
    gyy = imfilter(S, fyy, 'circular');
    guu = imfilter(S, fuu, 'circular');
    gvv = imfilter(S, fvv, 'circular');
    % L0 thresholding (KEY PAPER STEP)
    if D == 1
        mask = (gxx.^2 + gyy.^2 + guu.^2 + gvv.^2) < beta/lambda;
    else
        mask = sum(gxx.^2 + gyy.^2 + guu.^2 + gvv.^2,3) < beta/lambda;
        mask = repmat(mask,[1 1 D]);
    end
    gxx(mask)=0; gyy(mask)=0; guu(mask)=0; gvv(mask)=0;
    % Divergence
    Normin1 = circshift(imfilter(gx, Dx(end:-1:1),'circular'),[0 1]) + ...
              circshift(imfilter(gy, Dy(end:-1:1),'circular'),[1 0]);
    Normin2 = imfilter(gxx,fxx(end:-1:1),'circular') + ...
              imfilter(gyy,fyy(end:-1:1),'circular') + ...
              imfilter(guu,fuu(end:-1:1,end:-1:1),'circular') + ...
              imfilter(gvv,fvv(end:-1:1,end:-1:1),'circular');
    % FFT-based solution
    FS = (Normin0 + alpha*fft2(Normin1) + lambda*fft2(Normin2)) ./ Denormin;
    S  = real(ifft2(FS));
    % Error (ONLY for evaluation)
    errs(iter) = mean((S(:)-I0(:)).^2);
    alpha  = tau * alpha;
    lambda = kappa * lambda;
    iter = iter + 1;
end

errs = errs(1:iter-1);

% psnr val cal
psnr_val = psnr( ...
    I0(13:end-12,13:end-12,:), ...
    min(1,max(0,S(13:end-12,13:end-12,:))) ...
);
fprintf('PSNR = %.4f dB\n', psnr_val);

% saving output images
imwrite(I0,'output/strip_semi_sparsity_gt.png');
imwrite(I ,'output/strip_semi_sparsity_noise.png');
imwrite(S ,'output/strip_semi_sparsity_res.png');

% display and show convergence plot
figure;
imshow([I S]);
title(['Noisy Input | Semi-Sparsity Result (PSNR = ',num2str(psnr_val),' dB)']);
figure;
plot(errs,'LineWidth',1.5);
xlabel('Iteration');
ylabel('MSE');
title('Convergence Curve');
grid on;
saveas(gcf,'output/strip_semi_sparsity_err_plot.png');