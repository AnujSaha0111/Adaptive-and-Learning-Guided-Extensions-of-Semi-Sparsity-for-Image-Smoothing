function setup_paths()
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'matlab', 'config'));
addpath(fullfile(root, 'matlab', 'datasets'));
addpath(fullfile(root, 'matlab', 'methods'));
addpath(fullfile(root, 'matlab', 'utils'));
addpath(fullfile(root, 'matlab', 'core'));
addpath(fullfile(root, 'matlab', 'evaluation'));
addpath(fullfile(root, 'matlab', 'scripts'));
addpath(fullfile(root, 'results'));
fprintf('All paths added.\n');
end
