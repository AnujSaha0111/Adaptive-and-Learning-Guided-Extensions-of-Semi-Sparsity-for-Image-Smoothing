function run_stages_3_and_4()

setup_paths();

checkpoint_dir = 'checkpoints';
if ~exist(checkpoint_dir, 'dir'), mkdir(checkpoint_dir); end

completed = false(1, 4);
for k = 1:4
    cp = fullfile(checkpoint_dir, sprintf('stage_%d_complete.mat', k));
    if exist(cp, 'file')
        completed(k) = true;
    end
end

pipeline_start = tic;

if ~completed(3)
    fprintf('============================================\n');
    fprintf('  STAGE 3: Large Benchmark (1 realization)\n');
    fprintf('============================================\n\n');

    stage_start = tic;

    try
        cfg = experiment_config();
        cfg.datasets = {'Set12', 'BSD68'};
        cfg.noise_levels = [10 20 25 50];
        cfg.num_realizations = 1;
        cfg.save_images = false;

        results3 = run_batch_experiments(cfg);
        summary3 = analyze_results();
        generate_paper_tables();
        perform_statistical_tests();

        stage3_time = toc(stage_start);
        fprintf('\nStage 3 completed in %.2f s (%.2f min)\n', stage3_time, stage3_time/60);

        validate_and_report_stage3(results3, summary3, stage3_time);

        cp3 = fullfile(checkpoint_dir, 'stage_3_complete.mat');
        stage_num = 3; stage_time = stage3_time;
        timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
        save(cp3, 'stage_num', 'stage_time', 'timestamp');
        fprintf('Checkpoint saved: %s\n', cp3);

    catch ME
        fprintf('\n*** STAGE 3 FAILED ***\n');
        fprintf('Error: %s\n', ME.message);
        for s = 1:length(ME.stack)
            fprintf('  %s (line %d)\n', ME.stack(s).name, ME.stack(s).line);
        end
        diary off;
        rethrow(ME);
    end

    fprintf('\nPipeline elapsed: %.2f s (%.2f min)\n\n', toc(pipeline_start), toc(pipeline_start)/60);
else
    fprintf('Stage 3 already completed. Skipping.\n\n');
end

if ~completed(4)
    fprintf('============================================\n');
    fprintf('  STAGE 4: Full Benchmark (1 realization)\n');
    fprintf('============================================\n\n');

    stage_start = tic;

    try
        cfg = experiment_config();
        cfg.datasets = {'custom', 'Set12', 'BSD68', 'Kodak24'};
        cfg.noise_levels = [10 20 25 50];
        cfg.num_realizations = 1;
        cfg.save_images = false;

        results4 = run_batch_experiments(cfg);
        summary4 = analyze_results();
        generate_result_plots();
        generate_paper_tables();
        perform_statistical_tests();

        stage4_time = toc(stage_start);
        fprintf('\nStage 4 completed in %.2f s (%.2f min)\n', stage4_time, stage4_time/60);

        validate_and_report_stage4(results4, summary4, stage4_time);

        cp4 = fullfile(checkpoint_dir, 'stage_4_complete.mat');
        stage_num = 4; stage_time = stage4_time;
        timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
        save(cp4, 'stage_num', 'stage_time', 'timestamp');
        fprintf('Checkpoint saved: %s\n', cp4);

    catch ME
        fprintf('\n*** STAGE 4 FAILED ***\n');
        fprintf('Error: %s\n', ME.message);
        for s = 1:length(ME.stack)
            fprintf('  %s (line %d)\n', ME.stack(s).name, ME.stack(s).line);
        end
        rethrow(ME);
    end
else
    fprintf('Stage 4 already completed. Skipping.\n\n');
end

pipeline_total = toc(pipeline_start);
fprintf('\n============================================\n');
fprintf('  STAGES 3 & 4 COMPLETED SUCCESSFULLY\n');
fprintf('  Total pipeline time: %.2f s (%.2f min)\n', pipeline_total, pipeline_total/60);
fprintf('============================================\n');

end

function validate_and_report_stage3(R, S, elapsed)
check_file(fullfile('results', 'results_table.csv'));
check_file(fullfile('results', 'summary_statistics.csv'));
check_file(fullfile('results', 'per_image_statistics.csv'));
check_dir(fullfile('results', 'paper_tables'));
check_dir(fullfile('results', 'statistics'));

R2 = readtable(fullfile('results', 'results_table.csv'));
if any(isnan(R2.psnr)) || any(isinf(R2.psnr))
    error('NaN/Inf in PSNR'); end
if any(isnan(R2.ssim)) || any(isinf(R2.ssim))
    error('NaN/Inf in SSIM'); end
if any(isnan(R2.runtime)) || any(isinf(R2.runtime))
    error('NaN/Inf in runtime'); end

fid = fopen('STAGE3_REPORT.md', 'w');
fprintf(fid, '# Stage 3 Report -- Large Benchmark\n\n');
fprintf(fid, '## Configuration\n\n');
fprintf(fid, '- Datasets: Set12, BSD68\n');
fprintf(fid, '- Noise levels: sigma = [10, 20, 25, 50]\n');
fprintf(fid, '- Realizations: 1 (reduced from 3 for time budget)\n');
fprintf(fid, '- Methods: original, adaptive, lgss, bilateral, guided, tv, l0\n\n');
fprintf(fid, '## Results\n\n');
fprintf(fid, '- **Total experiments**: %d\n', height(R));
fprintf(fid, '- **Runtime**: %.2f s (%.2f min)\n\n', elapsed, elapsed/60);

fprintf(fid, '### Mean PSNR per Method\n\n');
fprintf(fid, '| Method | Mean PSNR (dB) | Mean SSIM | Mean Runtime (s) |\n');
fprintf(fid, '|---|---:|---:|---:|\n');
methods = unique(S.method);
for m = 1:length(methods)
    idx = strcmp(S.method, methods{m});
    fprintf(fid, '| %s | %.2f | %.4f | %.4f |\n', ...
        methods{m}, ...
        mean(S.mean_psnr(idx), 'omitnan'), ...
        mean(S.mean_ssim(idx), 'omitnan'), ...
        mean(S.mean_runtime(idx), 'omitnan'));
end

fprintf(fid, '\n## Validation\n\n');
fprintf(fid, '- results/results_table.csv: **PASS**\n');
fprintf(fid, '- results/summary_statistics.csv: **PASS**\n');
fprintf(fid, '- results/per_image_statistics.csv: **PASS**\n');
fprintf(fid, '- No NaN or Inf values: **PASS**\n\n');
fprintf(fid, '## Verdict\n\n');
fprintf(fid, '**STAGE 3 PASSED.** Proceed to Stage 4.\n');
fprintf(fid, '\n---\n*Generated by `run_stages_3_and_4.m`*\n');
fclose(fid);
fprintf('STAGE3_REPORT.md written.\n');
end

function validate_and_report_stage4(R, S, elapsed)
check_file(fullfile('results', 'results_table.csv'));
check_file(fullfile('results', 'summary_statistics.csv'));
check_file(fullfile('results', 'per_image_statistics.csv'));
check_dir(fullfile('results', 'paper_tables'));
check_dir(fullfile('results', 'figures'));
check_dir(fullfile('results', 'statistics'));

R2 = readtable(fullfile('results', 'results_table.csv'));
if any(isnan(R2.psnr)) || any(isinf(R2.psnr))
    error('NaN/Inf in PSNR'); end
if any(isnan(R2.ssim)) || any(isinf(R2.ssim))
    error('NaN/Inf in SSIM'); end

datasets = unique(R.dataset);
sigmas = unique(R.sigma);
methods = unique(R.method);

fid = fopen('FULL_BENCHMARK_REPORT.md', 'w');
fprintf(fid, '# Full Benchmark Report\n\n');
fprintf(fid, '## Configuration\n\n');
fprintf(fid, '- Datasets: %s\n', strjoin(datasets, ', '));
fprintf(fid, '- Noise levels: sigma = [%s]\n', num2str(sigmas));
fprintf(fid, '- Realizations: 1 per image per sigma\n');
fprintf(fid, '- Methods: %s\n\n', strjoin(methods, ', '));

fprintf(fid, '## Results\n\n');
fprintf(fid, '- **Total experiments**: %d\n', height(R));
fprintf(fid, '- **Stage 4 runtime**: %.2f s (%.2f min)\n\n', elapsed, elapsed/60);

fprintf(fid, '## Mean PSNR Table\n\n');
fprintf(fid, '| Dataset | Sigma |');
for m = 1:length(methods)
    fprintf(fid, ' %s |', methods{m});
end
fprintf(fid, '\n|');
for m = 0:length(methods)
    fprintf(fid, ' --- |');
end
fprintf(fid, '\n');
for d = 1:length(datasets)
    ds = datasets{d};
    for s = 1:length(sigmas)
        sg = sigmas(s);
        fprintf(fid, '| %s | %d |', ds, sg);
        for m = 1:length(methods)
            idx = strcmp(S.dataset, ds) & S.sigma == sg & strcmp(S.method, methods{m});
            if any(idx)
                fprintf(fid, ' %.2f |', S.mean_psnr(idx));
            else
                fprintf(fid, ' N/A |');
            end
        end
        fprintf(fid, '\n');
    end
end

fprintf(fid, '\n## Runtime Table\n\n');
fprintf(fid, '| Method | Mean Runtime (s) | Std Runtime |\n');
fprintf(fid, '|---|---:|---:|\n');
for m = 1:length(methods)
    idx = strcmp(S.method, methods{m});
    fprintf(fid, '| %s | %.4f | %.4f |\n', ...
        methods{m}, mean(S.mean_runtime(idx), 'omitnan'), ...
        mean(S.std_runtime(idx), 'omitnan'));
end

fprintf(fid, '\n---\n*Generated by `run_stages_3_and_4.m`*\n');
fclose(fid);
fprintf('FULL_BENCHMARK_REPORT.md written.\n');
end

function check_file(fpath)
if ~exist(fpath, 'file')
    error('File not found: %s', fpath);
end
fprintf('  [OK] %s\n', fpath);
end

function check_dir(dpath)
if ~exist(dpath, 'dir')
    error('Dir not found: %s', dpath);
end
fprintf('  [OK] %s/\n', dpath);
end
