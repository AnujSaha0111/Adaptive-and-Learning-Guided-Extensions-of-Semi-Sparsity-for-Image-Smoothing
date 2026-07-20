function val = tinv(p, df)
%TINV Inverse of Student's t-distribution CDF (no Statistics Toolbox).
%   VAL = TINV(P, DF) returns the inverse CDF value for the
%   Student's t-distribution with DF degrees of freedom at probability P.
%
%   Uses Newton-Raphson iteration on the t-distribution CDF.

if df <= 0
    val = Inf;
    return;
end

% Initial guess from normal approximation
val = norminv_approx(p);

for iter = 1:200
    cdf_val = t_cdf_local(val, df);
    pdf_val = t_pdf_local(val, df);
    if pdf_val < 1e-15
        break;
    end
    diff_val = cdf_val - p;
    val = val - diff_val / pdf_val;
    if abs(diff_val) < 1e-12
        break;
    end
end

end

function p = t_cdf_local(t, df)
x = df / (df + t^2);
p = 1 - 0.5 * betainc(x, df/2, 0.5);
if t < 0
    p = 1 - p;
end
end

function pdf = t_pdf_local(t, df)
coeff = gamma((df+1)/2) / (sqrt(df*pi) * gamma(df/2));
pdf = coeff * (1 + t^2/df)^(-(df+1)/2);
end

function x = norminv_approx(p)
if p <= 0
    x = -Inf; return;
end
if p >= 1
    x = Inf; return;
end
if p == 0.5
    x = 0; return;
end

if p < 0.5
    t_val = sqrt(-2*log(p));
    x = -(2.515517 + 0.802853*t_val + 0.010328*t_val^2) / ...
         (1 + 1.432788*t_val + 0.189269*t_val^2 + 0.001308*t_val^3);
else
    t_val = sqrt(-2*log(1-p));
    x = (2.515517 + 0.802853*t_val + 0.010328*t_val^2) / ...
        (1 + 1.432788*t_val + 0.189269*t_val^2 + 0.001308*t_val^3);
end
end
