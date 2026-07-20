function [h, p, ci, stats] = ttest(x, mu, varargin)
%TTEST One-sample t-test without Statistics Toolbox.
%   [H, P, CI, STATS] = TTEST(X, MU) performs a two-tailed paired
%   t-test of the null hypothesis that the data in X comes from a
%   distribution with mean MU.
%
%   Supports Name-Value pairs: 'Alpha' (default 0.05)

alpha_val = 0.05;
for k = 1:2:length(varargin)
    if strcmpi(varargin{k}, 'Alpha')
        alpha_val = varargin{k+1};
    end
end

x = x(~isnan(x));
n = length(x);
if n < 2
    h = 0; p = 1; ci = [-Inf Inf]; stats = struct('tstat', 0, 'df', 0, 'sd', 0);
    return;
end

xbar = mean(x);
s = std(x);
se = s / sqrt(n);
tstat = (xbar - mu) / se;
df = n - 1;

% Two-tailed p-value using manual t-distribution
p = 2 * (1 - t_cdf(abs(tstat), df));

% Confidence interval
t_crit_val = tinv(1 - alpha_val/2, df);
ci = [xbar - t_crit_val * se, xbar + t_crit_val * se];

h = double(p < alpha_val);

stats.tstat = tstat;
stats.df = df;
stats.sd = s;

end

function p = t_cdf(t, df)
%T_CDF Cumulative distribution function of Student's t-distribution.
%   Uses numerical integration (incomplete beta function).
if df <= 0
    p = 0.5;
    return;
end
x = df / (df + t^2);
p = 1 - 0.5 * betainc(x, df/2, 0.5);
if t < 0
    p = 1 - p;
end
end
