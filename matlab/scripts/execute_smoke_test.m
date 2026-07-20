cd('D:\Adaptive-and-Learning-Guided-Extensions-of-Semi-Sparsity-for-Image-Smoothing');
addpath('matlab\config');
addpath('matlab\datasets');
addpath('matlab\methods');
addpath('matlab\utils');
addpath('matlab\core');
addpath('matlab\evaluation');
addpath('matlab\scripts');

fprintf('Starting smoke test at %s...\n', datestr(now));
results = run_smoke_test();
fprintf('\nSMOKE TEST COMPLETED at %s\n', datestr(now));
disp(results);
exit;
