function [S, runtime] = denoise_lgss(I, edge_map)
%DENOISE_LGSS Learning-guided semi-sparsity denoising.
%   S = DENOISE_LGSS(I, EDGE_MAP) denoises image I using LGSS with
%   the provided edge confidence map.
%
%   [S, RUNTIME] = DENOISE_LGSS(I, EDGE_MAP) also returns wall-clock time.
%
%   EDGE_MAP is a soft edge confidence map in [0, 1] (high = likely edge).
%   If EDGE_MAP is empty, a uniform weight map is used (equivalent to
%   original semi-sparsity).

if nargin < 2 || isempty(edge_map)
    edge_map = zeros(size(I, 1), size(I, 2));
end

if nargout >= 2
    t_start = tic;
end

W = 1 - min(max(edge_map, 0), 1);

S = semi_sparsity_lgss(I, W);
S = min(max(S, 0), 1);

if nargout >= 2
    runtime = toc(t_start);
end

end
