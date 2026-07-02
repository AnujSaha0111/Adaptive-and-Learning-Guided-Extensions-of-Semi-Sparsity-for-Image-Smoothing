function p = default_params(method)
%DEFAULT_PARAMS Return default parameters for semi-sparsity methods.
%   P = DEFAULT_PARAMS() returns parameters for the base method.
%   P = DEFAULT_PARAMS('base')       - base semi-sparsity
%   P = DEFAULT_PARAMS('adaptive')   - adaptive semi-sparsity (+ gamma, eta)
%   P = DEFAULT_PARAMS('lgss')       - learning-guided semi-sparsity
%   P = DEFAULT_PARAMS('core')       - semi_sparsity_core (dual-beta)
%   P = DEFAULT_PARAMS('l0')         - L0 gradient minimization
%   P = DEFAULT_PARAMS('abstraction') - image abstraction

if nargin < 1
    method = 'base';
end

switch lower(method)
    case 'base'
        p.alpha      = 0.1;
        p.beta       = 0.02;
        p.lambda0    = 10 * p.beta;
        p.lambda_max = 1e8;
        p.kappa      = 1.2;
        p.tau        = 0.95;
        p.iter_max   = 500;

    case 'adaptive'
        p.alpha      = 0.1;
        p.beta       = 0.02;
        p.lambda0    = 10 * p.beta;
        p.lambda_max = 1e8;
        p.kappa      = 1.2;
        p.tau        = 0.95;
        p.iter_max   = 500;
        p.gamma      = 10;
        p.eta        = 2;

    case 'lgss'
        p.alpha      = 0.1;
        p.beta       = 0.02;
        p.lambda0    = 10 * p.beta;
        p.lambda_max = 1e8;
        p.kappa      = 1.2;
        p.tau        = 0.95;
        p.iter_max   = 500;

    case 'core'
        p.alpha_quad = 0.05;
        p.beta1      = 0.005;
        p.beta2      = 0.02;
        p.lambda1_0  = 10 * p.beta1;
        p.lambda2_0  = 10 * p.beta2;
        p.lambda_max = 1e8;
        p.kappa      = 1.2;
        p.tau        = 0.95;
        p.iter_max   = 300;

    case 'l0'
        p.beta       = 0.02;
        p.lambda0    = 10 * p.beta;
        p.lambda_max = 1e8;
        p.kappa      = 1.2;
        p.iter_max   = 500;

    case 'abstraction'
        p.alpha      = 0.05;
        p.beta       = 0.1;
        p.lambda0    = 10 * p.beta;
        p.lambda_max = 1e8;
        p.kappa      = 1.2;
        p.tau        = 0.95;
        p.iter_max   = 400;

    otherwise
        error('default_params:UnknownMethod', ...
              'Unknown method "%s".', method);
end

end
