# Dataset Download Instructions

This document describes where to obtain the three standard denoising benchmarks and how to organize them for use with this codebase.

---

## Directory Structure

After downloading all datasets, the `datasets/` folder should look like this:

```
datasets/
├── Set12/             # 12 grayscale test images
│   ├── 01.png
│   ├── 02.png
│   ├── ...
│   └── 12.png
├── BSD68/             # 68 grayscale test images from Berkeley Segmentation Dataset
│   ├── 001.png
│   ├── 002.png
│   ├── ...
│   └── 068.png
├── Kodak24/           # 24 color (converted to grayscale) test images from Kodak PhotoCD
│   ├── kodim01.png
│   ├── kodim02.png
│   ├── ...
│   └── kodim24.png
├── custom/            # (optional) user-provided images
│   ├── my_image.png
│   └── ...
├── download_instructions.md
├── get_image_list.m
└── load_dataset.m
```

## File Format
- All images: **PNG format** (lossless, no compression artifacts)
- Bit depth: **8-bit** (converted to double [0,1] at load time)
- Color space: **Grayscale** (converted automatically if RGB; see note below)

---

## Set12

**Source:** https://github.com/cszn/FFDNet/tree/master/testsets/Set12

**Files:** 12 grayscale `.png` images, named `01.png` through `12.png`.

**Download:**
1. Visit the FFDNet repository above.
2. Download the entire `Set12` folder.
3. Copy all 12 `.png` files into `datasets/Set12/`.

**Original Resolution:**
| Image | Name    | Resolution  |
|-------|---------|-------------|
| 01    | C.man   | 256 × 256   |
| 02    | House   | 256 × 256   |
| 03    | Peppers | 256 × 256   |
| 04    | Starfish| 256 × 256   |
| 05    | Monar   | 256 × 256   |
| 06    | Airpl   | 256 × 256   |
| 07    | Parrot  | 256 × 256   |
| 08    | Lena    | 256 × 256   |
| 09    | Barb    | 256 × 256   |
| 10    | Boat    | 256 × 256   |
| 11    | Man     | 256 × 256   |
| 12    | Couple  | 256 × 256   |

---

## BSD68

**Source:** https://github.com/cszn/FFDNet/tree/master/testsets/BSD68

**Files:** 68 grayscale `.png` images, named `001.png` through `068.png`.

**Download:**
1. Visit the FFDNet repository above.
2. Download the entire `BSD68` folder.
3. Copy all 68 `.png` files into `datasets/BSD68/`.

**Original Resolution:** Mixed (typically 321 × 481 or 481 × 321).

---

## Kodak24

**Source:** http://r0k.us/graphics/kodak/ (original Kodak PhotoCD)
**Mirror (convenience):** https://github.com/cszn/FFDNet/tree/master/testsets/Kodak24

**Files:** 24 grayscale `.png` images, named `kodim01.png` through `kodim24.png`.

**Download:**
1. Visit one of the sources above.
2. Download all 24 `.png` files.
3. Copy them into `datasets/Kodak24/`.

**Original Resolution:** 768 × 512 or 512 × 768.

---

## Custom Dataset (Optional)

Place any user-provided test images in `datasets/custom/`. Supported formats: `.png`, `.jpg`, `.jpeg`. All images are automatically converted to grayscale via `rgb2gray` at load time.

---

## Verification

After downloading, run the validation script to check that all images load correctly:

```matlab
validate_datasets()
```

This checks readability, dimensions, duplicates, and reports any missing files.
