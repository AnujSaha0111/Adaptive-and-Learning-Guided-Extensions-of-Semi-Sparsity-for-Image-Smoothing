function S = semi_sparsity_lgss(I, W)
%SEMI_SPARSITY_LGSS Learning-guided semi-sparsity denoising.
%   S = SEMI_SPARSITY_LGSS(I, W) denoises image I using the original
%   FFT-based HQS semi-sparsity solver with a spatially varying L0
%   threshold THRESH = (BETA .* W) / LAMBDA.

I = im2double(I);
[N, M, D] = size(I);
sizeI2D = [N M];

if ndims(W) == 3
    W = mean(W, 3);
end

if ~isequal(size(W), sizeI2D)
    error('semi_sparsity_lgss:SizeMismatch', ...+-
        'W must have size %d-by-%d to match the spatial size of I.', N, M);
end

W = im2double(W);
W = min(max(W, 0), 1);

Dx = [1 -1] / 2;
Dy = Dx';

fxx = [1 -2 1] / 4;
fyy = fxx';
fuu = [1 0 0; 0 -2 0; 0 0 1] / 4;
fvv = [0 0 1; 0 -2 0; 1 0 0] / 4;

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
    Denormin1 = repmat(Denormin1, [1 1 D]);
    Denormin2 = repmat(Denormin2, [1 1 D]);
end

% Parameters matched to the original semi-sparsity implementation.
alpha = 0.1;
beta = 0.02;
lambda = 10 * beta;
lambda_max = 1e8;
kappa = 1.2;
tau = 0.95;
iter_max = 500;

S = I;
Normin0 = fft2(I);
iter = 1;

while lambda <= lambda_max && iter <= iter_max
    Denormin = 1 + alpha * Denormin1 + lambda * Denormin2;

    % First-order term, kept identical to the original FFT/HQS solver.
    gx = imfilter(S, Dx, 'circular');
    gy = imfilter(S, Dy, 'circular');

    % Second-order semi-sparsity terms
    gxx = imfilter(S, fxx, 'circular');
    gyy = imfilter(S, fyy, 'circular');
    guu = imfilter(S, fuu, 'circular');
    gvv = imfilter(S, fvv, 'circular');

    thresh = (beta .* W) / lambda;
    if D == 1
        mask = (gxx.^2 + gyy.^2 + guu.^2 + gvv.^2) < thresh;
    else
        grad2 = sum(gxx.^2 + gyy.^2 + guu.^2 + gvv.^2, 3);
        mask = repmat(grad2 < thresh, [1 1 D]);
    end

    gxx(mask) = 0;
    gyy(mask) = 0;
    guu(mask) = 0;
    gvv(mask) = 0;

    Normin1 = circshift(imfilter(gx, Dx(end:-1:1), 'circular'), [0 1]) + ...
              circshift(imfilter(gy, Dy(end:-1:1), 'circular'), [1 0]);

    Normin2 = imfilter(gxx, fxx(end:-1:1), 'circular') + ...
              imfilter(gyy, fyy(end:-1:1), 'circular') + ...
              imfilter(guu, fuu(end:-1:1, end:-1:1), 'circular') + ...
              imfilter(gvv, fvv(end:-1:1, end:-1:1), 'circular');

    FS = (Normin0 + alpha * fft2(Normin1) + lambda * fft2(Normin2)) ./ Denormin;
    S = real(ifft2(FS));

    alpha = tau * alpha;
    lambda = kappa * lambda;
    iter = iter + 1;
end