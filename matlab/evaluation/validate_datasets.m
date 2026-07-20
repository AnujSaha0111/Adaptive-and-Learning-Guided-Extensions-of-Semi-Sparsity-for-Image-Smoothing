function report_path = validate_datasets()
%VALIDATE_DATASETS Validate all registered datasets for loading and integrity.
%   VALIDATE_DATASETS() checks each supported dataset for:
%     - Directory existence
%     - File readability (imread succeeds)
%     - Dimensions (height, width)
%     - Duplicate filenames across datasets
%     - Grayscale vs color channels
%     - Missing files vs expected list
%
%   Output:
%     Console log with per-dataset diagnostics
%     DATASET_VALIDATION_REPORT.md  — written to repo root
%     REPORT_PATH = VALIDATE_DATASETS() returns the report file path.

clc;

datasets_to_check = {'existing', 'Set12', 'BSD68', 'Kodak24', 'custom'};

fprintf('========================================\n');
fprintf('Dataset Validation\n');
fprintf('========================================\n\n');

global_pass = true;
all_details = struct([]);

for d = 1:length(datasets_to_check)
    ds_name = datasets_to_check{d};
    fprintf('--- %s ---\n', ds_name);

    [pass, stats, details] = check_dataset(ds_name);
    global_pass = global_pass && pass;

    all_details(end+1).name = ds_name;
    all_details(end).pass = pass;
    all_details(end).stats = stats;
    all_details(end).details = details;

    if pass
        fprintf('  STATUS: PASS (%d images loaded)\n', stats.num_loaded);
    else
        fprintf('  STATUS: FAIL\n');
    end
    fprintf('\n');
end

%% Duplicate check across datasets
fprintf('--- Cross-Dataset Duplicate Check ---\n');
dup_check = check_duplicates(all_details);
if dup_check.num_duplicates > 0
    global_pass = false;
    fprintf('  Found %d duplicate image(s) across datasets:\n', ...
        dup_check.num_duplicates);
    for i = 1:length(dup_check.duplicates)
        fprintf('    %s\n', dup_check.duplicates{i});
    end
    fprintf('  STATUS: FAIL\n');
else
    fprintf('  STATUS: PASS (no duplicates)\n');
end
fprintf('\n');

%% Summary
fprintf('========================================\n');
fprintf('Validation Summary\n');
fprintf('========================================\n');
for d = 1:length(all_details)
    fprintf('  %-12s: %s (%d/%d images, %s)\n', ...
        all_details(d).name, ...
        ternary(all_details(d).pass, 'PASS', 'FAIL'), ...
        all_details(d).stats.num_loaded, ...
        all_details(d).stats.num_expected, ...
        ternary(all_details(d).stats.all_grayscale, 'all gray', 'has color'));
end
fprintf('------------------------------------------------\n');
fprintf('  OVERALL: %s\n', ternary(global_pass, 'ALL PASS', 'SOME CHECKS FAILED'));
fprintf('\n');

%% Write report
report_path = write_report(all_details, dup_check, global_pass);
fprintf('Report written to: %s\n', report_path);

end

% -------------------------------------------------------------------------
function [pass, stats, details] = check_dataset(ds_name)

pass = true;
stats = struct( ...
    'num_expected', 0, ...
    'num_loaded',   0, ...
    'num_missing',  0, ...
    'num_unreadable', 0, ...
    'all_grayscale', true, ...
    'dims',         [], ...
    'errors',       {{}} ...
);
details = struct('file', {}, 'h', {}, 'w', {}, 'channels', {}, 'status', {});

% Check directory / file source
switch lower(ds_name)
    case 'existing'
        base_dir = pwd;
        expected = get_image_list(ds_name);
    otherwise
        base_dir = fullfile(pwd, 'datasets', ds_name);
        if ~exist(base_dir, 'dir')
            pass = false;
            stats.errors{end+1} = sprintf('Directory not found: %s', base_dir);
            stats.num_expected = 0;
            return;
        end
        try
            expected = get_image_list(ds_name);
        catch ME
            pass = false;
            stats.errors{end+1} = ME.message;
            stats.num_expected = 0;
            return;
        end
end

stats.num_expected = length(expected);
loaded_count = 0;
has_color = false;

for i = 1:length(expected)
    fname = expected{i};
    fpath = fullfile(base_dir, fname);

    if ~exist(fpath, 'file')
        details(end+1).file = fname; %#ok<AGROW>
        details(end).h = NaN;
        details(end).w = NaN;
        details(end).channels = NaN;
        details(end).status = 'MISSING';
        continue;
    end

    try
        img = imread(fpath);
        [h, w, c] = size(img);
        if c > 1
            has_color = true;
        end
        loaded_count = loaded_count + 1;
        details(end+1).file = fname; %#ok<AGROW>
        details(end).h = h;
        details(end).w = w;
        details(end).channels = c;
        details(end).status = 'OK';
    catch ME
        details(end+1).file = fname; %#ok<AGROW>
        details(end).h = NaN;
        details(end).w = NaN;
        details(end).channels = NaN;
        details(end).status = 'UNREADABLE';
        stats.errors{end+1} = sprintf('%s: %s', fname, ME.message);
    end
end

stats.num_loaded = loaded_count;
stats.num_missing = stats.num_expected - loaded_count;
stats.all_grayscale = ~has_color;

% Collect dimensions
dims_list = [];
for i = 1:length(details)
    if isfinite(details(i).h)
        dims_list(end+1, 1) = details(i).h; %#ok<AGROW>
        dims_list(end,   2) = details(i).w;
    end
end
stats.dims = dims_list;

if stats.num_missing > 0
    pass = false;
end
if stats.num_unreadable > 0
    pass = false;
end

end

% -------------------------------------------------------------------------
function result = check_duplicates(all_details)
%CHECK_DUPLICATES Check for identical filenames across datasets.

all_files = {};
all_sources = {};

for d = 1:length(all_details)
    for i = 1:length(all_details(d).details)
        fname = lower(all_details(d).details(i).file);
        all_files{end+1} = fname;  %#ok<AGROW>
        all_sources{end+1} = all_details(d).name; %#ok<AGROW>
    end
end

[unique_files, ~, ic] = unique(all_files);
counts = accumarray(ic, 1);

dups = {};
for i = 1:length(unique_files)
    if counts(i) > 1
        sources = unique(all_sources(ic == i));
        dups{end+1} = sprintf('%s (in: %s)', unique_files{i}, strjoin(sources, ', ')); %#ok<AGROW>
    end
end

result.num_duplicates = length(dups);
result.duplicates = dups;

end

% -------------------------------------------------------------------------
function report_path = write_report(all_details, dup_check, global_pass)
%WRITE_REPORT Generate DATASET_VALIDATION_REPORT.md.

report_path = fullfile(pwd, 'DATASET_VALIDATION_REPORT.md');
fid = fopen(report_path, 'w');
if fid == -1
    error('Cannot open %s for writing', report_path);
end

fprintf(fid, '# Dataset Validation Report\n\n');
fprintf(fid, '**Generated:** %s\n\n', datestr(now));
fprintf(fid, '**Script:** validate_datasets.m\n\n');
fprintf(fid, '---\n\n');

%% Summary table
fprintf(fid, '## Summary\n\n');
fprintf(fid, '| Dataset | Status | Loaded | Expected | Dimensions | Grayscale |\n');
fprintf(fid, '|---------|--------|--------|----------|------------|-----------|\n');

for d = 1:length(all_details)
    st = all_details(d).stats;
    if isempty(st.dims)
        dim_str = 'N/A';
    else
        min_h = min(st.dims(:,1));
        max_h = max(st.dims(:,1));
        min_w = min(st.dims(:,2));
        max_w = max(st.dims(:,2));
        if min_h == max_h && min_w == max_w
            dim_str = sprintf('%d x %d', min_h, min_w);
        else
            dim_str = sprintf('%d-%d x %d-%d', min_h, max_h, min_w, max_w);
        end
    end
    gray_str = ternary(st.all_grayscale, 'yes', 'no');
    status_str = ternary(all_details(d).pass, 'PASS', 'FAIL');
    fprintf(fid, '| %s | %s | %d | %d | %s | %s |\n', ...
        all_details(d).name, status_str, ...
        st.num_loaded, st.num_expected, dim_str, gray_str);
end

fprintf(fid, '| **Duplicate check** | %s | — | — | — | — |\n', ...
    ternary(dup_check.num_duplicates == 0, 'PASS', 'FAIL'));
fprintf(fid, '\n');

%% Per-dataset details
fprintf(fid, '## Per-Dataset Details\n\n');

for d = 1:length(all_details)
    ds = all_details(d);
    st = ds.stats;

    fprintf(fid, '### %s\n\n', ds.name);
    fprintf(fid, '| Property | Value |\n');
    fprintf(fid, '|----------|-------|\n');
    fprintf(fid, '| Status | %s |\n', ternary(ds.pass, 'PASS', 'FAIL'));
    fprintf(fid, '| Directory | %s |\n', ...
        ternary(strcmpi(ds.name, 'existing'), 'repo root', ...
        fullfile('datasets', ds.name)));
    fprintf(fid, '| Expected images | %d |\n', st.num_expected);
    fprintf(fid, '| Successfully loaded | %d |\n', st.num_loaded);
    fprintf(fid, '| Missing | %d |\n', st.num_missing);
    fprintf(fid, '| All grayscale | %s |\n', ternary(st.all_grayscale, 'yes', 'no'));

    if ~isempty(st.dims)
        min_h = min(st.dims(:,1));
        max_h = max(st.dims(:,1));
        min_w = min(st.dims(:,2));
        max_w = max(st.dims(:,2));
        fprintf(fid, '| Height range | %d – %d px |\n', min_h, max_h);
        fprintf(fid, '| Width range | %d – %d px |\n', min_w, max_w);
    end

    fprintf(fid, '\n');

    % Per-file table
    if ~isempty(ds.details)
        fprintf(fid, '| File | Status | Width | Height | Channels |\n');
        fprintf(fid, '|------|--------|-------|--------|----------|\n');
        for i = 1:length(ds.details)
            det = ds.details(i);
            h_str = sprintf('%d', det.h);
            w_str = sprintf('%d', det.w);
            c_str = sprintf('%d', det.channels);
            if ~isfinite(det.h)
                h_str = '—';
                w_str = '—';
                c_str = '—';
            end
            fprintf(fid, '| %s | %s | %s | %s | %s |\n', ...
                det.file, det.status, w_str, h_str, c_str);
        end
        fprintf(fid, '\n');
    end

    % Errors
    if ~isempty(st.errors)
        fprintf(fid, '**Errors:**\n\n');
        for i = 1:length(st.errors)
            fprintf(fid, '- %s\n', st.errors{i});
        end
        fprintf(fid, '\n');
    end
end

%% Duplicates
if dup_check.num_duplicates > 0
    fprintf(fid, '## Duplicate Files\n\n');
    fprintf(fid, '| # | File | Across Datasets |\n');
    fprintf(fid, '|---|------|-----------------|\n');
    for i = 1:length(dup_check.duplicates)
        fprintf(fid, '| %d | %s |\n', i, dup_check.duplicates{i});
    end
    fprintf(fid, '\n');
else
    fprintf(fid, '## Duplicate Files\n\n');
    fprintf(fid, 'No duplicate filenames found across datasets.\n\n');
end

%% Final verdict
fprintf(fid, '---\n\n');
fprintf(fid, '## Verdict\n\n');
if global_pass
    fprintf(fid, '**All checks passed.** All datasets are correctly set up and images are readable.\n');
else
    fprintf(fid, '**Some checks failed.** Review the per-dataset details above for missing files, unreadable images, or other issues.\n');
end
fprintf(fid, '\n');

fclose(fid);

end

% -------------------------------------------------------------------------
function s = ternary(cond, t, f)
if cond
    s = t;
else
    s = f;
end
end
