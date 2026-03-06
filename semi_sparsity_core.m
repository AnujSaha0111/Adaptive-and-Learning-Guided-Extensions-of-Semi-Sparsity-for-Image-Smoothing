function S = semi_sparsity_core(I, S_init)

if nargin < 2
    S = I;
else
    S = S_init;
end

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

% Parameters
alpha_quad = 0.05;    % quadratic first-order
beta1  = 0.005;       % L0 first-order (small)
beta2  = 0.02;        % L0 second-order

lambda1 = 10 * beta1;
lambda2 = 10 * beta2;

lambda_max = 1e8;
kappa = 1.2;
tau   = 0.95;
iter_max = 300;

Normin0 = fft2(I);
iter = 1;

while lambda2 <= lambda_max && iter <= iter_max

    Denormin = 1 + alpha_quad*Denormin1 + ...
               lambda1*Denormin1 + ...
               lambda2*Denormin2;

    % First-order
    gx = imfilter(S, Dx, 'circular');
    gy = imfilter(S, Dy, 'circular');

    mask1 = (gx.^2 + gy.^2) < beta1/lambda1;
    gx(mask1)=0; gy(mask1)=0;

    % Second-order
    gxx = imfilter(S, fxx, 'circular');
    gyy = imfilter(S, fyy, 'circular');
    guu = imfilter(S, fuu, 'circular');
    gvv = imfilter(S, fvv, 'circular');

    mask2 = (gxx.^2 + gyy.^2 + guu.^2 + gvv.^2) < beta2/lambda2;
    gxx(mask2)=0; gyy(mask2)=0; guu(mask2)=0; gvv(mask2)=0;

    Normin1 = circshift(imfilter(gx, Dx(end:-1:1),'circular'),[0 1]) + ...
              circshift(imfilter(gy, Dy(end:-1:1),'circular'),[1 0]);

    Normin2 = imfilter(gxx,fxx(end:-1:1),'circular') + ...
              imfilter(gyy,fyy(end:-1:1),'circular') + ...
              imfilter(guu,fuu(end:-1:1,end:-1:1),'circular') + ...
              imfilter(gvv,fvv(end:-1:1,end:-1:1),'circular');

    FS = (Normin0 + ...
          alpha_quad*fft2(Normin1) + ...
          lambda1*fft2(Normin1) + ...
          lambda2*fft2(Normin2)) ./ Denormin;

    S  = real(ifft2(FS));

    lambda1 = kappa * lambda1;
    lambda2 = kappa * lambda2;
    iter = iter + 1;
end