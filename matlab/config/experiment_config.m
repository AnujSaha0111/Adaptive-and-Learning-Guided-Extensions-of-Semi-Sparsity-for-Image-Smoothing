function cfg = experiment_config()
%EXPERIMENT_CONFIG Default configuration for batch experiments.
%   CFG = EXPERIMENT_CONFIG() returns a struct with all experiment
%   parameters.
%
%   Default configuration runs the full benchmark across all available
%   datasets and methods. Override individual fields to run subsets.
%
%   Datasets:    'existing' (root-level images),
%                'Set12', 'BSD68', 'Kodak24', 'custom'
%   Noise:       sigma = [10, 20, 25, 50]
%   Realizations: 5 per image per sigma
%   Methods:     original, adaptive, lgss, bilateral, guided, tv, l0

% Supported datasets: 'existing', 'Set12', 'BSD68', 'Kodak24', 'custom'
cfg.datasets = {'custom', 'Set12', 'BSD68', 'Kodak24'};

% Noise levels (standard deviation)
cfg.noise_levels = [10, 20, 25, 50];

% Number of random noise realizations per image per sigma
cfg.num_realizations = 5;

% Methods to evaluate
cfg.methods = {'original', 'adaptive', 'lgss', 'bilateral', 'guided', 'tv', 'l0'};

% Save output images
cfg.save_images = false;

% Compute SSIM
cfg.compute_ssim = true;

% Compute runtime
cfg.compute_runtime = true;

% Seed offset: each realization uses seed = base_seed + realization_idx
cfg.base_seed = 2026;

% Output directory
cfg.output_dir = 'results';

% Image extension for saving
cfg.image_ext = 'png';

end
