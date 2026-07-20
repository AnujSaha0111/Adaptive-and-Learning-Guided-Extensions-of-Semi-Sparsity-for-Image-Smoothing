function [output, metadata] = denoise_tv(input, varargin)
%DENOISE_TV Total Variation denoising (ROF model).
%   OUTPUT = DENOISE_TV(I) denoises image I using total variation
%   minimization (Rudin, Osher & Fatemi, 1992):
%     min_u  ||u - f||^2 + lambda * TV(u)
%
%   [OUTPUT, METADATA] = DENOISE_TV(I) also returns a struct with:
%     .runtime    - wall-clock time in seconds
%     .parameters - parameter struct used
%     .iterations - number of iterations performed
%
%   Uses explicit gradient descent with a dual variable formulation
%   (Chambolle, 2004) for improved convergence.

t_start = tic;

p = default_params('tv');
if nargin >= 2 && ~isempty(varargin{1})
    p = varargin{1};
end

lambda  = p.lambda;
iter_max = p.iter_max;
dt       = p.dt;
tol      = p.tol;

f = double(input);
[N, M, D] = size(f);

u = f;

% Gradient operators
Dx = [1, -1];
Dy = [1; -1];

for iter = 1:iter_max
    u_prev = u;

    for c = 1:D
        uc = u(:, :, c);

        % Compute gradient: grad_u = (ux, uy)
        ux = imfilter(uc, Dx, 'replicate');
        uy = imfilter(uc, Dy, 'replicate');

        % Gradient magnitude
        grad_mag = sqrt(ux.^2 + uy.^2 + eps);

        % Divergence of normalized gradient: div(grad_u / |grad_u|)
        % div(p) = backward difference of p
        % ux / |grad_u| -> forward diff in x, then backward diff in y
        px = ux ./ grad_mag;
        py = uy ./ grad_mag;

        % Backward difference (negative of forward difference of adjoint)
        div_p = imfilter(px, -Dx(end:-1:1), 'replicate') + ...
                imfilter(py, -Dy(end:-1:1), 'replicate');

        % Gradient descent step
        uc = uc + dt * (div_p - (uc - f(:, :, c)) / lambda);
        u(:, :, c) = uc;
    end

    % Check convergence
    change = max(abs(u(:) - u_prev(:)));
    if change < tol
        break;
    end
end

output = min(max(u, 0), 1);

runtime = toc(t_start);

metadata = struct();
metadata.runtime    = runtime;
metadata.parameters = p;
metadata.iterations = iter;

end
