function [output, metadata] = denoise_l0(input, varargin)
%DENOISE_L0 L0 gradient minimization denoising.
%   OUTPUT = DENOISE_L0(I) denoises image I using L0 gradient
%   minimization (Xu, Lu, Xu & Jia, 2011):
%     min_S  ||S - I||^2 + beta * ||grad S||_0
%
%   [OUTPUT, METADATA] = DENOISE_L0(I) also returns a struct with:
%     .runtime    - wall-clock time in seconds
%     .parameters - parameter struct used
%     .iterations - number of iterations performed
%
%   Uses half-quadratic splitting (HQS) with FFT-based solver,
%   identical to the algorithm in run_l0_gradient.m.

t_start = tic;

p = default_params('l0');
if nargin >= 2 && ~isempty(varargin{1})
    p = varargin{1};
end

beta       = p.beta;
lambda0    = p.lambda0;
lambda_max = p.lambda_max;
kappa      = p.kappa;
iter_max   = p.iter_max;

[N, M, D] = size(input);
sizeI2D = [N, M];

% First-order gradient operators
Dx = [1, -1] / 2;
Dy = Dx';

otfDx = psf2otf(Dx, sizeI2D);
otfDy = psf2otf(Dy, sizeI2D);

Denormin = abs(otfDx).^2 + abs(otfDy).^2;
if D > 1
    Denormin = repmat(Denormin, [1, 1, D]);
end

S = input;
Normin0 = fft2(S);
lambda  = lambda0;
iter    = 1;

while lambda <= lambda_max && iter <= iter_max
    % First-order gradients
    gx = imfilter(S, Dx, 'circular');
    gy = imfilter(S, Dy, 'circular');

    % L0 thresholding on gradient magnitude
    if D == 1
        mask = (gx.^2 + gy.^2) < beta / lambda;
    else
        mask = sum(gx.^2 + gy.^2, 3) < beta / lambda;
        mask = repmat(mask, [1, 1, D]);
    end
    gx(mask) = 0;
    gy(mask) = 0;

    % Divergence
    Normin = circshift(imfilter(gx, Dx(end:-1:1), 'circular'), [0, 1]) + ...
             circshift(imfilter(gy, Dy(end:-1:1), 'circular'), [1, 0]);

    % FFT solution
    FS = (Normin0 + lambda * fft2(Normin)) ./ (1 + lambda * Denormin);
    S  = real(ifft2(FS));

    lambda = kappa * lambda;
    iter = iter + 1;
end

output = min(max(S, 0), 1);

runtime = toc(t_start);

metadata = struct();
metadata.runtime    = runtime;
metadata.parameters = p;
metadata.iterations = iter - 1;

end
