function val = compute_ssim(gt, pred, crop_border)
%COMPUTE_SSIM Unified SSIM computation with border cropping.
%   VAL = COMPUTE_SSIM(GT, PRED) computes SSIM with default 12-pixel
%   border cropping on all sides.
%
%   VAL = COMPUTE_SSIM(GT, PRED, CROP_BORDER) uses CROP_BORDER pixels
%   of border cropping. Use CROP_BORDER = 0 for no cropping.
%
%   Uses MATLAB's built-in ssim() if available (Image Processing Toolbox).
%   Falls back to a native implementation otherwise.
%
%   Both GT and PRED are double images in [0, 1] range.
%   PRED is clamped to [0, 1] before computation.

if nargin < 3
    crop_border = 12;
end

gt = im2double(gt);
pred = im2double(pred);
pred = min(max(pred, 0), 1);

if crop_border > 0
    gt = gt(1+crop_border:end-crop_border, ...
            1+crop_border:end-crop_border, :);
    pred = pred(1+crop_border:end-crop_border, ...
                1+crop_border:end-crop_border, :);
end

if license('test', 'image_toolbox') && exist('ssim', 'file')
    val = ssim(pred, gt);
else
    val = ssim_fallback(gt, pred);
end

end

% -------------------------------------------------------------------------
function val = ssim_fallback(gt, pred)
%SSIM_FALLBACK Native SSIM implementation.
%   Implements the standard SSIM index:
%     SSIM(x,y) = (2*mu_x*mu_y + C1)(2*sigma_xy + C2)
%                / (mu_x^2 + mu_y^2 + C1)(sigma_x^2 + sigma_y^2 + C2)
%
%   Uses 11x11 Gaussian weighting, K1=0.01, K2=0.03, L=1.

K1 = 0.01;
K2 = 0.03;
L = 1;
C1 = (K1 * L)^2;
C2 = (K2 * L)^2;

window = fspecial('gaussian', 11, 1.5);
window = window / sum(window(:));

if size(gt, 3) > 1
    window = repmat(window, [1, 1, size(gt, 3)]);
end

mu1 = imfilter(gt, window, 'replicate');
mu2 = imfilter(pred, window, 'replicate');

mu1_sq = mu1.^2;
mu2_sq = mu2.^2;
mu12 = mu1 .* mu2;

sigma1_sq = imfilter(gt.^2, window, 'replicate') - mu1_sq;
sigma2_sq = imfilter(pred.^2, window, 'replicate') - mu2_sq;
sigma12 = imfilter(gt .* pred, window, 'replicate') - mu12;

ssim_map = ((2 * mu12 + C1) .* (2 * sigma12 + C2)) ...
         ./ ((mu1_sq + mu2_sq + C1) .* (sigma1_sq + sigma2_sq + C2));

val = mean(ssim_map(:));

end
