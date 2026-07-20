clc;
clear;
close all;

I0 = im2double(imread('strip_gt.png'));
I  = im2double(imread('strip_noise.png'));

[N,M,D] = size(I);
sizeI2D = [N M];

Dx = [1 -1]/2;
Dy = Dx';
otfDx = psf2otf(Dx, sizeI2D);
otfDy = psf2otf(Dy, sizeI2D);
Denormin = abs(otfDx).^2 + abs(otfDy).^2;
if D > 1
    Denormin = repmat(Denormin,[1 1 D]);
end

beta = 0.02;
lambda = 10 * beta;
lambda_max = 1e8;
kappa = 1.2;
iter_max = 500;

S = I;
Normin0 = fft2(S);
iter = 1;

while lambda <= lambda_max && iter <= iter_max
    gx = imfilter(S, Dx, 'circular');
    gy = imfilter(S, Dy, 'circular');
    if D == 1
        mask = (gx.^2 + gy.^2) < beta/lambda;
    else
        mask = sum(gx.^2 + gy.^2,3) < beta/lambda;
        mask = repmat(mask,[1 1 D]);
    end
    gx(mask)=0;
    gy(mask)=0;
    Normin = circshift(imfilter(gx, Dx(end:-1:1),'circular'),[0 1]) + ...
             circshift(imfilter(gy, Dy(end:-1:1),'circular'),[1 0]);
    FS = (Normin0 + lambda*fft2(Normin)) ./ (1 + lambda*Denormin);
    S  = real(ifft2(FS));
    lambda = kappa * lambda;
    iter = iter + 1;
end

imwrite(S,'output/strip_l0_gradient_res.png');
fprintf('L0 gradient smoothing completed.\n');
