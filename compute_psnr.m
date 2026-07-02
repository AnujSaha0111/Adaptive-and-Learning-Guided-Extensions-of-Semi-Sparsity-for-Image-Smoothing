function val = compute_psnr(gt, pred, crop_border)
%COMPUTE_PSNR Unified PSNR computation with border cropping.
%   VAL = COMPUTE_PSNR(GT, PRED) computes PSNR with default 12-pixel
%   border cropping on all sides.
%
%   VAL = COMPUTE_PSNR(GT, PRED, CROP_BORDER) uses CROP_BORDER pixels
%   of border cropping. Use CROP_BORDER = 0 for no cropping.
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

mse_val = mean((gt(:) - pred(:)).^2);
if mse_val < eps
    val = inf;
else
    val = 10 * log10(1 / mse_val);
end

end
