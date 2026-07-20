clc;
clear;
close all;

I = im2double(imread('strip_gt.png'));

alpha = 0.05;
beta  = 0.1;
lambda = 10 * beta;
lambda_max = 1e8;
kappa = 1.2;
tau   = 0.95;
iter_max = 400;

[N,M,D] = size(I);
sizeI2D = [N M];

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
S = I;
Normin0 = fft2(S);
iter = 1;

while lambda <= lambda_max && iter <= iter_max
    Denormin = 1 + alpha*Denormin1 + lambda*Denormin2;
    gxx = imfilter(S, fxx, 'circular');
    gyy = imfilter(S, fyy, 'circular');
    guu = imfilter(S, fuu, 'circular');
    gvv = imfilter(S, fvv, 'circular');
    if D == 1
        mask = (gxx.^2 + gyy.^2 + guu.^2 + gvv.^2) < beta/lambda;
    else
        mask = sum(gxx.^2 + gyy.^2 + guu.^2 + gvv.^2,3) < beta/lambda;
        mask = repmat(mask,[1 1 D]);
    end
    gxx(mask)=0; gyy(mask)=0; guu(mask)=0; gvv(mask)=0;
    Normin2 = imfilter(gxx,fxx(end:-1:1),'circular') + ...
              imfilter(gyy,fyy(end:-1:1),'circular') + ...
              imfilter(guu,fuu(end:-1:1,end:-1:1),'circular') + ...
              imfilter(gvv,fvv(end:-1:1,end:-1:1),'circular');
    FS = (Normin0 + lambda*fft2(Normin2)) ./ Denormin;
    S  = real(ifft2(FS));
    lambda = kappa * lambda;
    alpha  = tau * alpha;
    iter = iter + 1;
end

imwrite(S,'output/strip_semi_sparsity_abstraction.png');
figure;
imshow([I S]);
title('Original | Semi-Sparsity Abstraction');
