function images = get_image_list(dataset_name)
%GET_IMAGE_LIST Get list of image filenames for a given dataset.
%   IMAGES = GET_IMAGE_LIST(DATASET_NAME) returns a cell array of
%   filenames (relative to the dataset directory).
%
%   Supported datasets:
%     'existing'  - Lena, Barbara, Cameraman, Strip (in repo root)
%     'Set12'     - 12 grayscale test images (datasets/Set12/)
%     'BSD68'     - 68 grayscale test images (datasets/BSD68/)
%     'Kodak24'   - 24 grayscale test images (datasets/Kodak24/)
%     'custom'    - user-provided images (datasets/custom/, scanned from directory)

switch lower(dataset_name)

    case 'existing'
        images = { ...
            'lena.png'
            'Barbara.jpg'
            'Cameraman.jpg'
            'strip_gt.png'
            };

    case 'set12'
        images = { ...
            '01.png', '02.png', '03.png', '04.png', '05.png', ...
            '06.png', '07.png', '08.png', '09.png', '10.png', ...
            '11.png', '12.png'
            };

    case 'bsd68'
        images = cell(68, 1);
        for i = 1:68
            images{i} = sprintf('test%03d.png', i);
        end

    case 'kodak24'
        images = cell(24, 1);
        for i = 1:24
            images{i} = sprintf('kodim%02d.png', i);
        end

    case 'custom'
        custom_dir = fullfile(pwd, 'datasets', 'custom');
        if ~exist(custom_dir, 'dir')
            error('get_image_list:CustomDirNotFound', ...
                'Custom dataset directory not found: %s', custom_dir);
        end
        files = dir(fullfile(custom_dir, '*.png'));
        files = [files; dir(fullfile(custom_dir, '*.jpg'))];  %#ok<AGROW>
        files = [files; dir(fullfile(custom_dir, '*.jpeg'))]; %#ok<AGROW>
        images = sort({files.name})';
        if isempty(images)
            warning('get_image_list:CustomDirEmpty', ...
                'No PNG/JPG images found in %s', custom_dir);
        end

    otherwise
        error('get_image_list:UnknownDataset', ...
            ['Unknown dataset "%s". ', ...
             'Supported: existing, Set12, BSD68, Kodak24, custom'], ...
            dataset_name);
end

end
