function [output, metadata] = denoise_bilateral(input, varargin)
%DENOISE_BILATERAL Bilateral filter denoising.
%   OUTPUT = DENOISE_BILATERAL(I) denoises image I using the bilateral
%   filter (Tomasi & Manduchi, 1998).
%
%   [OUTPUT, METADATA] = DENOISE_BILATERAL(I) also returns a struct with:
%     .runtime    - wall-clock time in seconds
%     .parameters - parameter struct used
%     .iterations - not applicable (returns 1)
%
%   The bilateral filter at each pixel is a weighted average of neighbors,
%   where weights combine a spatial Gaussian (sigma_s) and a range Gaussian
%   (sigma_r) on intensity differences.

t_start = tic;

% Parse optional parameter overrides
p = default_params('bilateral');
if nargin >= 2 && ~isempty(varargin{1})
    p = varargin{1};
end

sigma_s = p.sigma_s;
sigma_r = p.sigma_r;
w       = p.window;

[N, M, D] = size(input);

% Construct spatial Gaussian kernel
half = floor(w / 2);
[X, Y] = meshgrid(-half:half, -half:half);
spatial_kernel = exp(-(X.^2 + Y.^2) / (2 * sigma_s^2));
spatial_kernel = spatial_kernel / sum(spatial_kernel(:));

% Pad input with replicate (edge extension)
pad_size = half;
padded = padarray(input, [pad_size, pad_size], 'replicate', 'both');

output = zeros(N, M, D);

for c = 1:D
    channel = input(:, :, c);
    padded_c = padded(:, :, c);

    accum = zeros(N, M);
    norm_f = zeros(N, M);

    for dx = -half:half
        for dy = -half:half
            shifted = padded_c((half+1+dx):(half+N+dx), ...
                               (half+1+dy):(half+M+dy));
            diff = shifted - channel;
            range_weight = exp(-(diff.^2) / (2 * sigma_r^2));
            w_combined = spatial_kernel(dx+half+1, dy+half+1) * range_weight;
            accum = accum + w_combined .* shifted;
            norm_f = norm_f + w_combined;
        end
    end

    output(:, :, c) = accum ./ max(norm_f, eps);
end

output = min(max(output, 0), 1);

runtime = toc(t_start);

metadata = struct();
metadata.runtime    = runtime;
metadata.parameters = p;
metadata.iterations = 1;

end
