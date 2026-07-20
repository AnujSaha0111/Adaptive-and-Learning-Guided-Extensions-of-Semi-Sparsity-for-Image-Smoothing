function [result, runtime] = benchmark_runtime(func_handle, varargin)
%BENCHMARK_RUNTIME Measure execution time of a denoising function.
%   [RESULT, RUNTIME] = BENCHMARK_RUNTIME(FUNC_HANDLE, ARGS...)
%   calls FUNC_HANDLE(ARGS{:}) and measures wall-clock time.
%
%   RUNTIME is in seconds, measured via tic/toc excluding:
%     - function call overhead
%     - argument passing

t_start = tic;
result = func_handle(varargin{:});
runtime = toc(t_start);

end
