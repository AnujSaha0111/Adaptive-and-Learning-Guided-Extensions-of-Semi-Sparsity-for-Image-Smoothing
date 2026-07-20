cd('D:\Adaptive-and-Learning-Guided-Extensions-of-Semi-Sparsity-for-Image-Smoothing');
addpath('matlab\config','matlab\datasets','matlab\methods','matlab\utils','matlab\core','matlab\evaluation','matlab\scripts');
diary('logs\smoke_diary.log');
fprintf('=== MATLAB SMOKE TEST STARTED at %s ===\n', datestr(now));
try
    results = run_smoke_test();
    fprintf('\n=== SMOKE TEST COMPLETED at %s ===\n', datestr(now));
    disp(results);
catch e
    fprintf('\n=== SMOKE TEST FAILED at %s ===\n', datestr(now));
    fprintf('Error: %s\n', e.message);
    for k=1:length(e.stack)
        fprintf('  in %s (line %d)\n', e.stack(k).name, e.stack(k).line);
    end
end
diary off;
exit;
