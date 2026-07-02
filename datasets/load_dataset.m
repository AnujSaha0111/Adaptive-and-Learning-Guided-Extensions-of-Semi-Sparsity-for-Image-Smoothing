function images = load_dataset(dataset_name)
%LOAD_DATASET Load all images from a dataset.
%   IMAGES = LOAD_DATASET(DATASET_NAME) returns a struct array with fields:
%     .name   - image filename
%     .image  - image data (double, [0, 1])
%     .height - image height in pixels
%     .width  - image width in pixels
%
%   Supported datasets:
%     'existing'  - loads from repo root (lena.png, Barbara.jpg, etc.)
%     'Set12'     - loads from datasets/Set12/
%     'BSD68'     - loads from datasets/BSD68/
%     'Kodak24'   - loads from datasets/Kodak24/
%     'custom'    - loads from datasets/custom/ (directory scanned dynamically)

file_list = get_image_list(dataset_name);
num_images = length(file_list);

images = struct( ...
    'name',   cell(num_images, 1), ...
    'image',  cell(num_images, 1), ...
    'height', cell(num_images, 1), ...
    'width',  cell(num_images, 1)  ...
);

for i = 1:num_images
    fname = file_list{i};

    switch lower(dataset_name)
        case 'existing'
            full_path = fullfile(pwd, fname);
        otherwise
            full_path = fullfile(pwd, 'datasets', dataset_name, fname);
    end

    if ~exist(full_path, 'file')
        warning('load_dataset:FileNotFound', ...
            'File not found: %s. Skipping.', full_path);
        images(i).name = fname;
        images(i).image = [];
        images(i).height = 0;
        images(i).width = 0;
        continue;
    end

    img = im2double(imread(full_path));

    if size(img, 3) == 3
        img = rgb2gray(img);
    end

    images(i).name   = fname;
    images(i).image  = img;
    images(i).height = size(img, 1);
    images(i).width  = size(img, 2);
end

fprintf('load_dataset: loaded %d images from "%s"\n', num_images, dataset_name);

end
