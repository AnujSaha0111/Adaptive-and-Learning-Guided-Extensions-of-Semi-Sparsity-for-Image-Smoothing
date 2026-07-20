# Adaptive and Learning-Guided Extensions of Semi-Sparsity for Image Smoothing

Extensions of the semi-sparsity framework for edge-preserving image smoothing
with spatially adaptive thresholds and learning-guided priors.

## Key Contributions

1.  **Adaptive Semi-Sparsity** — Spatially varying threshold beta(x, y)
    modulated by local gradient magnitude. Achieves up to +4.45 dB PSNR
    improvement over the original method.
2.  **Learning-Guided Semi-Sparsity (LGSS)** — External edge priors from
    Canny detection modulate the sparsity threshold via weight maps.
3.  **Multi-scale Analysis** — Documented negative result: coarse-to-fine
    decomposition fails due to incompatibility with FFT-based global
    optimization.

## Repository Structure

```
project/
├── README.md                           # This file
├── METHODOLOGY.md                      # Detailed methodology
├── LICENSE                             # MIT License
├── matlab/
│   ├── core/                           # Core solvers
│   │   ├── semi_sparsity_solver.m
│   │   ├── lgss_solver.m
│   │   └── setup_paths.m
│   ├── methods/                        # Denoising wrappers (7 methods)
│   ├── utils/                          # Utilities (noise, timing, stats)
│   ├── evaluation/                     # PSNR, SSIM, verification
│   ├── scripts/                        # Run scripts and analysis
│   ├── config/                         # Parameter configuration
│   └── datasets/                       # Dataset loading helpers
├── datasets/                           # Set12, BSD68, Kodak24, custom
│   └── download_instructions.md
├── edges/                              # Pre-generated edge maps
├── output/                             # Result visualizations *
├── results/                            # Numerical results (CSV tables)
│   ├── figures/                        # PSNR/SSIM/runtime plots
│   ├── paper_tables/                   # Publication-ready tables
│   └── statistics/                     # Statistical tests
├── cvip_ipa_paper/                     # CVIP-IPA paper and materials *
└── ieee_trans_paper/                   # IEEE Transactions paper draft *
```

*Directories marked with * are frozen.*

## Installation

### Requirements

- **MATLAB** R2020+ with Image Processing Toolbox
- **Python** 3.8+ with OpenCV (optional, for edge map generation)

### Setup

Clone the repository and open MATLAB in the project root:

```matlab
setup_paths
```

## Datasets

Download test datasets following the instructions in
`datasets/download_instructions.md`. The repository includes:

| Dataset | Images | Type |
|---------|--------|------|
| Set12   | 12     | Grayscale |
| BSD68   | 68     | Grayscale |
| Kodak24 | 24     | Grayscale |
| Custom  | 3      | Grayscale |

## Running Experiments

### Quick Demo

```matlab
run_original_semi_sparsity       % Base semi-sparsity
run_adaptive_semi_sparsity       % Adaptive (recommended)
run_lgss                          % Learning-guided
run_l0_gradient_minimization      % L0 gradient baseline
```

### Full Benchmark

```matlab
run_staged_benchmark(1)           % Stage 1: sanity check
run_staged_benchmark(2)           % Stage 2: medium benchmark
run_stages_3_and_4                % Stages 3 & 4: full benchmark
```

### Smoke Test

```matlab
run_smoke_test
```

## Generating Outputs

### Figures

```matlab
generate_result_plots
```

### Tables

```matlab
generate_paper_tables
```

### Statistical Analysis

```matlab
perform_statistical_tests
```

### Edge Maps (for LGSS)

```bash
python matlab/scripts/generate_edge_map.py
```

## Reproducing the Paper

1.  Run `run_staged_benchmark(1)` to verify the pipeline
2.  Run `run_stages_3_and_4` for the full benchmark
3.  Run `generate_paper_tables` to produce publication tables
4.  Run `generate_result_plots` to produce figures
5.  Run `perform_statistical_tests` for significance analysis

All results are written to `results/` as CSV files.

## Output Description

| Directory | Contents |
|-----------|----------|
| `output/` | Denoised images, comparisons, convergence plots |
| `results/results_table.csv` | Per-image, per-method PSNR, SSIM, runtime |
| `results/summary_statistics.csv` | Aggregated results by method and dataset |
| `results/paper_tables/` | Publication-ready LaTeX tables |
| `results/figures/` | PSNR/SSIM vs noise level plots |

## Parameters

Default parameters are defined in `matlab/config/default_params.m`:

| Parameter | Value | Description |
|-----------|-------|-------------|
| alpha     | 0.1   | First-order smoothness weight |
| beta      | 0.02  | Second-order sparsity threshold |
| lambda_0  | 0.2   | Initial sparsity penalty |
| lambda_max| 1e8   | Maximum sparsity penalty |
| kappa     | 1.2   | Continuation growth rate |
| gamma     | 10    | Adaptive gradient modulation |
| eta       | 2     | Adaptive weight exponent |

## License

MIT License. See `LICENSE` for details.
