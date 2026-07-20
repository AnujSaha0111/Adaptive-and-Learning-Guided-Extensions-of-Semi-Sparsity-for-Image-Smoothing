function noisy = add_gaussian_noise(img, sigma, seed)
%ADD_GAUSSIAN_NOISE Add Gaussian noise to an image.
%   NOISY = ADD_GAUSSIAN_NOISE(IMG, SIGMA) adds zero-mean Gaussian noise
%   with standard deviation SIGMA to IMG.
%
%   NOISY = ADD_GAUSSIAN_NOISE(IMG, SIGMA, SEED) uses SEED for the random
%   number generator, enabling reproducible noise.
%
%   IMG is a double image in [0, 1]. SIGMA is in the same units.
%   If SIGMA is specified as an integer percentage (e.g. 25 for 25/255),
%   it is automatically normalized: sigma = sigma / 255.

if nargin < 3
    seed = [];
end

% Normalize sigma if it appears to be in [0, 255] range
% (common convention: sigma = 25 means 25/255)
if sigma > 1
    sigma = sigma / 255;
end

% Set random seed for reproducibility
if ~isempty(seed)
    rng(seed, 'twister');
else
    rng('default');
end

noise = sigma * randn(size(img));
noisy = img + noise;
noisy = min(max(noisy, 0), 1);

end
