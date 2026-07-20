clc;
clear;
close all;

I = im2double(imread('strip_gt.png'));
if size(I,3) == 3
    I = rgb2gray(I);
end

Dx = [1 -1]/2;
Dy = Dx';
gx = imfilter(I, Dx, 'circular');
gy = imfilter(I, Dy, 'circular');
mag1 = abs(gx) + abs(gy);

fxx = [1 -2 1]/4;
fyy = fxx';
fuu = [1 0 0; 0 -2 0; 0 0 1]/4;
fvv = [0 0 1; 0 -2 0; 1 0 0]/4;
gxx = imfilter(I, fxx, 'circular');
gyy = imfilter(I, fyy, 'circular');
guu = imfilter(I, fuu, 'circular');
gvv = imfilter(I, fvv, 'circular');

mag2 = abs(gxx) + abs(gyy) + abs(guu) + abs(gvv);

threshold = 1e-3;
sparsity_1st = sum(mag1(:) < threshold) / numel(mag1);
sparsity_2nd = sum(mag2(:) < threshold) / numel(mag2);
fprintf('1st-order sparsity  = %.2f %%\n', sparsity_1st*100);
fprintf('2nd-order sparsity  = %.2f %%\n', sparsity_2nd*100);

figure;
subplot(1,2,1);
imshow(log(1 + mag1), []);
title('1st-order Gradient Magnitude');
subplot(1,2,2);
imshow(log(1 + mag2), []);
title('2nd-order Gradient Magnitude');
saveas(gcf,'output/sparsity_visualization.png');
