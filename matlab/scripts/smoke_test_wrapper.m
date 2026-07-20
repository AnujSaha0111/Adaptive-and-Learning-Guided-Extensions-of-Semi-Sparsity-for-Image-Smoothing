% smoke_test_wrapper.m - runs the smoke test with full path setup
try
    cd('D:\Adaptive-and-Learning-Guided-Extensions-of-Semi-Sparsity-for-Image-Smoothing');
    addpath('matlab\config');
    addpath('matlab\datasets');
    addpath('matlab\methods');
    addpath('matlab\utils');
    addpath('matlab\core');
    addpath('matlab\evaluation');
    addpath('matlab\scripts');
    
    fprintf('Paths added. Running smoke test...\n');
    smoke_test_fixes;
    fprintf('Smoke test completed.\n');
catch e
    fprintf('ERROR: %s\n', e.message);
    fprintf('File: %s, Line: %d\n', e.stack(1).file, e.stack(1).line);
end
