function [output, metadata] = denoise_guided(input, varargin)
%DENOISE_GUIDED Guided filter denoising.
%   OUTPUT = DENOISE_GUIDED(I) denoises image I using the guided filter
%   (He, Sun & Tang, 2013) with self-guidance (guidance = input).
%
%   [OUTPUT, METADATA] = DENOISE_GUIDED(I) also returns a struct with:
%     .runtime    - wall-clock time in seconds
%     .parameters - parameter struct used
%     .iterations - not applicable (returns 1)
%
%   The guided filter assumes the output q is a linear transform of the
%   guidance I in a local window: q_i = a_k * I_i + b_k for all i in w_k.
%   With self-guidance, this acts as an edge-preserving smoother.

t_start = tic;

p = default_params('guided');
if nargin >= 2 && ~isempty(varargin{1})
    p = varargin{1};
end

r   = p.radius;
eps = p.epsilon;

I = double(input);
[N, M, D] = size(I);

% Box filter (mean filter) kernel
box_k = fspecial('average', [2*r+1, 2*r+1]);

if D == 1
    % Single-channel: self-guidance
    mean_I = imfilter(I, box_k, 'replicate');
    mean_II = imfilter(I.^2, box_k, 'replicate');
    var_I = mean_II - mean_I.^2;

    a = var_I ./ (var_I + eps);
    b = mean_I - a .* mean_I;

    mean_a = imfilter(a, box_k, 'replicate');
    mean_b = imfilter(b, box_k, 'replicate');

    output = mean_a .* I + mean_b;
else
    % Multi-channel: apply per channel
    output = zeros(N, M, D);
    for c = 1:D
        Ic = I(:, :, c);
        mean_Ic = imfilter(Ic, box_k, 'replicate');
        mean_IcIc = imfilter(Ic.^2, box_k, 'replicate');
        var_Ic = mean_IcIc - mean_Ic.^2;

        a = var_Ic ./ (var_Ic + eps);
        b = mean_Ic - a .* mean_Ic;

        mean_a = imfilter(a, box_k, 'replicate');
        mean_b = imfilter(b, box_k, 'replicate');

        output(:, :, c) = mean_a .* Ic + mean_b;
    end
end

output = min(max(output, 0), 1);

runtime = toc(t_start);

metadata = struct();
metadata.runtime    = runtime;
metadata.parameters = p;
metadata.iterations = 1;

end
