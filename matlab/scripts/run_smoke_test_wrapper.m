try
    cd('D:\Adaptive-and-Learning-Guided-Extensions-of-Semi-Sparsity-for-Image-Smoothing');
    addpath('matlab\config');
    addpath('matlab\datasets');
    addpath('matlab\methods');
    addpath('matlab\utils');
    addpath('matlab\core');
    addpath('matlab\evaluation');
    addpath('matlab\scripts');
    
    fprintf('Starting smoke test...\n');
    results = run_smoke_test();
    fprintf('\nSMOKE TEST COMPLETED SUCCESSFULLY\n');
    disp(results);
catch e
    fprintf('\nSMOKE TEST FAILED\n');
    fprintf('Error: %s\n', e.message);
    for k = 1:length(e.stack)
        fprintf('  in %s (line %d)\n', e.stack(k).name, e.stack(k).line);
    end
end
exit;
