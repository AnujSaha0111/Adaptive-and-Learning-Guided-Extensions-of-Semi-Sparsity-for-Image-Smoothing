function [p, h] = signrank(x, varargin)
%SIGNRANK Wilcoxon signed-rank test without Statistics Toolbox.
%   [P, H] = SIGNRANK(X) performs a two-tailed Wilcoxon signed-rank
%   test of the null hypothesis that the data in X comes from a
%   distribution with median zero.
%
%   Supports Name-Value pairs: 'Alpha' (default 0.05)
%   Also accepts: SIGNRANK(X, MU, ...) where MU is the hypothesized median.

mu = 0;
alpha_val = 0.05;
idx = 1;
while idx <= length(varargin)
    if isnumeric(varargin{idx}) && idx == 1
        mu = varargin{idx};
        idx = idx + 1;
    elseif strcmpi(varargin{idx}, 'Alpha')
        alpha_val = varargin{idx+1};
        idx = idx + 2;
    else
        idx = idx + 1;
    end
end

% Remove NaN and compute differences
d = x(~isnan(x)) - mu;
d = d(d ~= 0);
n = length(d);

if n < 1
    p = 1; h = 0; return;
end

% Rank absolute differences
[sorted_abs, sort_idx] = sort(abs(d));
ranks = zeros(n, 1);
i = 1;
while i <= n
    j = i;
    while j <= n && sorted_abs(j) == sorted_abs(i)
        j = j + 1;
    end
    avg_rank = (i + j - 1) / 2;
    for k = i:j-1
        ranks(sort_idx(k)) = avg_rank;
    end
    i = j;
end

% Compute W+ and W-
pos_mask = d > 0;
W_plus = sum(ranks(pos_mask));
W_minus = sum(ranks(~pos_mask));

W = min(W_plus, W_minus);

% Normal approximation for n >= 10
mu_W = n * (n + 1) / 4;
sigma_W = sqrt(n * (n + 1) * (2*n + 1) / 24);

if sigma_W == 0
    p = 1; h = 0; return;
end

z = (W - mu_W) / sigma_W;

% Two-tailed p-value using normal approximation
p = 2 * (1 - norm_cdf(abs(z)));
p = min(p, 1);

h = double(p < alpha_val);

end

function p = norm_cdf(x)
%NORM_CDF Normal CDF using error function
p = 0.5 * (1 + erf(x / sqrt(2)));
end
