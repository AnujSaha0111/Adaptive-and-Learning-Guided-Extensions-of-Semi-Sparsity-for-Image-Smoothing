# Statistical Significance Analysis Report

Adaptive Semi-Sparsity vs all baseline methods.

- Significance level: α = 0.05
- Metric: PSNR (primary), SSIM (secondary)
- Tests: Paired t-test, Wilcoxon signed-rank test
- Effect size: Cohen's d
- Confidence interval: 95%

---

## PSNR Results

### Dataset: BSD68

| Comparison | Sigma | p (t-test) | Significant? | p (Wilcoxon) | Significant? | Cohen's d | 95% CI | N |
|---|---|---:|---|---:|---|---:|---:|---:|
| Adaptive vs bilateral | 10 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -3.607 (large) | [-8.930, -7.807] | 68 |
| Adaptive vs guided | 10 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -3.173 (large) | [-7.713, -6.620] | 68 |
| Adaptive vs l0 | 10 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | 0.796 (medium) | [0.734, 1.375] | 68 |
| Adaptive vs lgss | 10 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -2.338 (large) | [-3.204, -2.603] | 68 |
| Adaptive vs original | 10 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | 2.334 (large) | [2.742, 3.376] | 68 |
| Adaptive vs tv | 10 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | 3.355 (large) | [4.440, 5.131] | 68 |
| Adaptive vs bilateral | 20 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -2.196 (large) | [-2.607, -2.090] | 68 |
| Adaptive vs guided | 20 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -1.747 (large) | [-2.308, -1.746] | 68 |
| Adaptive vs l0 | 20 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | 2.920 (large) | [2.409, 2.845] | 68 |
| Adaptive vs lgss | 20 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -1.163 (large) | [-1.226, -0.803] | 68 |
| Adaptive vs original | 20 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | 4.854 (large) | [4.339, 4.794] | 68 |
| Adaptive vs tv | 20 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | 6.298 (large) | [6.991, 7.549] | 68 |
| Adaptive vs bilateral | 25 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -3.124 (large) | [-1.046, -0.895] | 68 |
| Adaptive vs guided | 25 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -2.470 (large) | [-1.052, -0.864] | 68 |
| Adaptive vs l0 | 25 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | 1.616 (large) | [1.211, 1.638] | 68 |
| Adaptive vs lgss | 25 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -1.323 (large) | [-0.932, -0.644] | 68 |
| Adaptive vs original | 25 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | 2.644 (large) | [2.916, 3.504] | 68 |
| Adaptive vs tv | 25 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | 7.201 (large) | [6.632, 7.093] | 68 |
| Adaptive vs bilateral | 50 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -8.770 (large) | [-1.390, -1.315] | 68 |
| Adaptive vs guided | 50 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -10.147 (large) | [-1.796, -1.712] | 68 |
| Adaptive vs l0 | 50 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -5.954 (large) | [-2.310, -2.130] | 68 |
| Adaptive vs lgss | 50 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -2.376 (large) | [-1.018, -0.830] | 68 |
| Adaptive vs original | 50 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -4.947 (large) | [-2.551, -2.313] | 68 |
| Adaptive vs tv | 50 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | 11.685 (large) | [1.866, 1.945] | 68 |

### Dataset: Kodak24

| Comparison | Sigma | p (t-test) | Significant? | p (Wilcoxon) | Significant? | Cohen's d | 95% CI | N |
|---|---|---:|---|---:|---|---:|---:|---:|
| Adaptive vs bilateral | 10 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -3.901 (large) | [-9.585, -7.712] | 24 |
| Adaptive vs guided | 10 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -3.425 (large) | [-8.342, -6.511] | 24 |
| Adaptive vs l0 | 10 | 0.0022 | Yes ✓ | 0.0030 | Yes ✓ | 0.703 (medium) | [0.339, 1.360] | 24 |
| Adaptive vs lgss | 10 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -2.927 (large) | [-3.791, -2.835] | 24 |
| Adaptive vs original | 10 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | 2.767 (large) | [2.421, 3.293] | 24 |
| Adaptive vs tv | 10 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | 4.339 (large) | [4.901, 5.958] | 24 |
| Adaptive vs bilateral | 20 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -2.356 (large) | [-2.408, -1.676] | 24 |
| Adaptive vs guided | 20 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -1.826 (large) | [-2.200, -1.373] | 24 |
| Adaptive vs l0 | 20 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | 4.548 (large) | [2.486, 2.995] | 24 |
| Adaptive vs lgss | 20 | 0.0000 | Yes ✓ | 0.0001 | Yes ✓ | -1.357 (large) | [-1.698, -0.892] | 24 |
| Adaptive vs original | 20 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | 5.264 (large) | [4.352, 5.111] | 24 |
| Adaptive vs tv | 20 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | 7.383 (large) | [7.681, 8.613] | 24 |
| Adaptive vs bilateral | 25 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -4.607 (large) | [-0.957, -0.797] | 24 |
| Adaptive vs guided | 25 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -3.491 (large) | [-1.039, -0.814] | 24 |
| Adaptive vs l0 | 25 | 0.0000 | Yes ✓ | 0.0001 | Yes ✓ | 1.161 (large) | [0.711, 1.524] | 24 |
| Adaptive vs lgss | 25 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -1.795 (large) | [-1.507, -0.933] | 24 |
| Adaptive vs original | 25 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | 2.702 (large) | [2.504, 3.431] | 24 |
| Adaptive vs tv | 25 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | 8.886 (large) | [6.985, 7.682] | 24 |
| Adaptive vs bilateral | 50 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -10.790 (large) | [-1.483, -1.371] | 24 |
| Adaptive vs guided | 50 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -11.604 (large) | [-1.896, -1.763] | 24 |
| Adaptive vs l0 | 50 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -7.364 (large) | [-2.519, -2.245] | 24 |
| Adaptive vs lgss | 50 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -3.718 (large) | [-1.054, -0.839] | 24 |
| Adaptive vs original | 50 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -6.733 (large) | [-2.650, -2.337] | 24 |
| Adaptive vs tv | 50 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | 14.743 (large) | [1.831, 1.939] | 24 |

### Dataset: Set12

| Comparison | Sigma | p (t-test) | Significant? | p (Wilcoxon) | Significant? | Cohen's d | 95% CI | N |
|---|---|---:|---|---:|---|---:|---:|---:|
| Adaptive vs bilateral | 10 | 0.0000 | Yes ✓ | 0.0022 | Yes ✓ | -5.914 (large) | [-10.094, -8.135] | 12 |
| Adaptive vs guided | 10 | 0.0000 | Yes ✓ | 0.0022 | Yes ✓ | -4.612 (large) | [-8.546, -6.477] | 12 |
| Adaptive vs l0 | 10 | 0.9660 | No ✗ | 0.6949 | No ✗ | 0.013 (negligible) | [-0.622, 0.648] | 12 |
| Adaptive vs lgss | 10 | 0.0000 | Yes ✓ | 0.0022 | Yes ✓ | -3.633 (large) | [-3.158, -2.218] | 12 |
| Adaptive vs original | 10 | 0.0000 | Yes ✓ | 0.0022 | Yes ✓ | 4.278 (large) | [2.933, 3.956] | 12 |
| Adaptive vs tv | 10 | 0.0000 | Yes ✓ | 0.0022 | Yes ✓ | 3.217 (large) | [3.902, 5.823] | 12 |
| Adaptive vs bilateral | 20 | 0.0000 | Yes ✓ | 0.0022 | Yes ✓ | -2.957 (large) | [-2.401, -1.552] | 12 |
| Adaptive vs guided | 20 | 0.0001 | Yes ✓ | 0.0022 | Yes ✓ | -1.658 (large) | [-2.000, -0.892] | 12 |
| Adaptive vs l0 | 20 | 0.0000 | Yes ✓ | 0.0022 | Yes ✓ | 4.116 (large) | [1.935, 2.642] | 12 |
| Adaptive vs lgss | 20 | 0.0021 | Yes ✓ | 0.0060 | Yes ✓ | -1.152 (large) | [-1.001, -0.289] | 12 |
| Adaptive vs original | 20 | 0.0000 | Yes ✓ | 0.0022 | Yes ✓ | 5.900 (large) | [4.781, 5.935] | 12 |
| Adaptive vs tv | 20 | 0.0000 | Yes ✓ | 0.0022 | Yes ✓ | 8.181 (large) | [7.260, 8.483] | 12 |
| Adaptive vs bilateral | 25 | 0.0000 | Yes ✓ | 0.0022 | Yes ✓ | -5.225 (large) | [-0.760, -0.595] | 12 |
| Adaptive vs guided | 25 | 0.0001 | Yes ✓ | 0.0029 | Yes ✓ | -1.701 (large) | [-0.740, -0.338] | 12 |
| Adaptive vs l0 | 25 | 0.0113 | Yes ✓ | 0.0229 | Yes ✓ | 0.877 (large) | [0.227, 1.422] | 12 |
| Adaptive vs lgss | 25 | 0.0002 | Yes ✓ | 0.0022 | Yes ✓ | -1.552 (large) | [-1.330, -0.557] | 12 |
| Adaptive vs original | 25 | 0.0000 | Yes ✓ | 0.0022 | Yes ✓ | 2.774 (large) | [2.799, 4.462] | 12 |
| Adaptive vs tv | 25 | 0.0000 | Yes ✓ | 0.0022 | Yes ✓ | 16.848 (large) | [6.976, 7.522] | 12 |
| Adaptive vs bilateral | 50 | 0.0000 | Yes ✓ | 0.0022 | Yes ✓ | -15.666 (large) | [-1.431, -1.319] | 12 |
| Adaptive vs guided | 50 | 0.0000 | Yes ✓ | 0.0022 | Yes ✓ | -15.262 (large) | [-1.813, -1.668] | 12 |
| Adaptive vs l0 | 50 | 0.0000 | Yes ✓ | 0.0022 | Yes ✓ | -11.261 (large) | [-2.479, -2.214] | 12 |
| Adaptive vs lgss | 50 | 0.0000 | Yes ✓ | 0.0022 | Yes ✓ | -3.987 (large) | [-1.264, -0.917] | 12 |
| Adaptive vs original | 50 | 0.0000 | Yes ✓ | 0.0022 | Yes ✓ | -10.956 (large) | [-2.656, -2.365] | 12 |
| Adaptive vs tv | 50 | 0.0000 | Yes ✓ | 0.0022 | Yes ✓ | 33.472 (large) | [1.826, 1.896] | 12 |

### Dataset: custom

| Comparison | Sigma | p (t-test) | Significant? | p (Wilcoxon) | Significant? | Cohen's d | 95% CI | N |
|---|---|---:|---|---:|---|---:|---:|---:|
| Adaptive vs bilateral | 10 | 0.0400 | Yes ✓ | 0.1088 | No ✗ | -2.800 (large) | [-16.576, -0.991] | 3 |
| Adaptive vs guided | 10 | 0.0617 | No ✗ | 0.1088 | No ✗ | -2.215 (large) | [-15.162, 0.869] | 3 |
| Adaptive vs l0 | 10 | 0.9969 | No ✗ | 1.0000 | No ✗ | 0.003 (negligible) | [-4.323, 4.332] | 3 |
| Adaptive vs original | 10 | 0.0389 | Yes ✓ | 0.1088 | No ✗ | 2.842 (large) | [0.376, 5.597] | 3 |
| Adaptive vs bilateral | 20 | 0.0959 | No ✗ | 0.1088 | No ✗ | -1.727 (large) | [-4.413, 0.793] | 3 |
| Adaptive vs guided | 20 | 0.3384 | No ✗ | 0.1088 | No ✗ | -0.720 (medium) | [-4.760, 2.620] | 3 |
| Adaptive vs l0 | 20 | 0.0175 | Yes ✓ | 0.1088 | No ✗ | 4.302 (large) | [0.807, 3.011] | 3 |
| Adaptive vs lgss | 20 | 0.5530 | No ✗ | 0.5930 | No ✗ | -0.408 (small) | [-1.216, 0.873] | 3 |
| Adaptive vs original | 20 | 0.0141 | Yes ✓ | 0.1088 | No ✗ | 4.815 (large) | [2.195, 6.872] | 3 |
| Adaptive vs tv | 20 | 0.0034 | Yes ✓ | 0.1088 | No ✗ | 9.920 (large) | [6.239, 10.407] | 3 |
| Adaptive vs bilateral | 25 | 0.0026 | Yes ✓ | 0.1088 | No ✗ | -11.274 (large) | [-0.756, -0.483] | 3 |
| Adaptive vs guided | 25 | 0.2941 | No ✗ | 0.2850 | No ✗ | -0.814 (large) | [-1.243, 0.629] | 3 |
| Adaptive vs l0 | 25 | 0.5319 | No ✗ | 0.5930 | No ✗ | 0.433 (small) | [-1.218, 1.731] | 3 |
| Adaptive vs lgss | 25 | 0.1284 | No ✗ | 0.1088 | No ✗ | -1.452 (large) | [-2.352, 0.617] | 3 |
| Adaptive vs original | 25 | 0.1528 | No ✗ | 0.1088 | No ✗ | 1.302 (large) | [-2.391, 7.661] | 3 |
| Adaptive vs tv | 25 | 0.0015 | Yes ✓ | 0.1088 | No ✗ | 15.033 (large) | [6.248, 8.721] | 3 |
| Adaptive vs bilateral | 50 | 0.0023 | Yes ✓ | 0.1088 | No ✗ | -11.902 (large) | [-1.651, -1.081] | 3 |
| Adaptive vs guided | 50 | 0.0039 | Yes ✓ | 0.1088 | No ✗ | -9.262 (large) | [-2.148, -1.239] | 3 |
| Adaptive vs l0 | 50 | 0.0020 | Yes ✓ | 0.1088 | No ✗ | -12.906 (large) | [-2.875, -1.947] | 3 |
| Adaptive vs lgss | 50 | 0.0082 | Yes ✓ | 0.1088 | No ✗ | -6.323 (large) | [-1.627, -0.709] | 3 |
| Adaptive vs original | 50 | 0.0019 | Yes ✓ | 0.1088 | No ✗ | -13.120 (large) | [-2.979, -2.030] | 3 |
| Adaptive vs tv | 50 | 0.0006 | Yes ✓ | 0.1088 | No ✗ | 24.032 (large) | [1.676, 2.062] | 3 |

---

## SSIM Results

### Dataset: BSD68

| Comparison | Sigma | p (t-test) | Significant? | p (Wilcoxon) | Significant? | Cohen's d | 95% CI | N |
|---|---:|---:|---|---:|---:|---:|---:|---:|
| Adaptive vs bilateral | 10 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -2.901 (large) | [-0.2548, -0.2156] | 68 |
| Adaptive vs guided | 10 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -2.786 (large) | [-0.2348, -0.1972] | 68 |
| Adaptive vs l0 | 10 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | 0.842 (large) | [0.0417, 0.0754] | 68 |
| Adaptive vs lgss | 10 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -2.098 (large) | [-0.1010, -0.0801] | 68 |
| Adaptive vs original | 10 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | 1.416 (large) | [0.1043, 0.1473] | 68 |
| Adaptive vs tv | 10 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | 1.966 (large) | [0.2973, 0.3808] | 68 |
| Adaptive vs bilateral | 20 | 0.1321 | No ✗ | 0.2741 | No ✗ | 0.185 (negligible) | [-0.0051, 0.0378] | 68 |
| Adaptive vs guided | 20 | 0.0173 | Yes ✓ | 0.0407 | Yes ✓ | 0.296 (small) | [0.0045, 0.0453] | 68 |
| Adaptive vs l0 | 20 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | 1.277 (large) | [0.0870, 0.1278] | 68 |
| Adaptive vs lgss | 20 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -1.454 (large) | [-0.0552, -0.0395] | 68 |
| Adaptive vs original | 20 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | 1.673 (large) | [0.1483, 0.1985] | 68 |
| Adaptive vs tv | 20 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | 3.352 (large) | [0.3931, 0.4543] | 68 |
| Adaptive vs bilateral | 25 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | 0.730 (medium) | [0.0226, 0.0450] | 68 |
| Adaptive vs guided | 25 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | 0.831 (large) | [0.0242, 0.0441] | 68 |
| Adaptive vs l0 | 25 | 0.5712 | No ✗ | 0.7003 | No ✗ | -0.069 (negligible) | [-0.0450, 0.0250] | 68 |
| Adaptive vs lgss | 25 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -1.279 (large) | [-0.1350, -0.0921] | 68 |
| Adaptive vs original | 25 | 0.0133 | Yes ✓ | 0.0106 | Yes ✓ | 0.308 (small) | [0.0107, 0.0892] | 68 |
| Adaptive vs tv | 25 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | 4.673 (large) | [0.3191, 0.3540] | 68 |
| Adaptive vs bilateral | 50 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -2.892 (large) | [-0.0248, -0.0209] | 68 |
| Adaptive vs guided | 50 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -5.395 (large) | [-0.0321, -0.0294] | 68 |
| Adaptive vs l0 | 50 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -1.936 (large) | [-0.0832, -0.0647] | 68 |
| Adaptive vs lgss | 50 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -1.080 (large) | [-0.0914, -0.0580] | 68 |
| Adaptive vs original | 50 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -1.822 (large) | [-0.1531, -0.1172] | 68 |
| Adaptive vs tv | 50 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | 2.959 (large) | [0.0533, 0.0628] | 68 |

### Dataset: Kodak24

| Comparison | Sigma | p (t-test) | Significant? | p (Wilcoxon) | Significant? | Cohen's d | 95% CI | N |
|---|---:|---:|---|---:|---:|---:|---:|---:|
| Adaptive vs bilateral | 10 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -3.003 (large) | [-0.2339, -0.1762] | 24 |
| Adaptive vs guided | 10 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -2.937 (large) | [-0.2132, -0.1596] | 24 |
| Adaptive vs l0 | 10 | 0.0001 | Yes ✓ | 0.0001 | Yes ✓ | 0.933 (large) | [0.0212, 0.0562] | 24 |
| Adaptive vs lgss | 10 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -2.355 (large) | [-0.1000, -0.0696] | 24 |
| Adaptive vs original | 10 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | 1.495 (large) | [0.0686, 0.1226] | 24 |
| Adaptive vs tv | 10 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | 2.578 (large) | [0.3463, 0.4819] | 24 |
| Adaptive vs bilateral | 20 | 0.0035 | Yes ✓ | 0.0061 | Yes ✓ | 0.663 (medium) | [0.0206, 0.0929] | 24 |
| Adaptive vs guided | 20 | 0.0009 | Yes ✓ | 0.0017 | Yes ✓ | 0.776 (medium) | [0.0285, 0.0965] | 24 |
| Adaptive vs l0 | 20 | 0.0000 | Yes ✓ | 0.0001 | Yes ✓ | 1.075 (large) | [0.0435, 0.0997] | 24 |
| Adaptive vs lgss | 20 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -1.924 (large) | [-0.0708, -0.0453] | 24 |
| Adaptive vs original | 20 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | 1.463 (large) | [0.0919, 0.1665] | 24 |
| Adaptive vs tv | 20 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | 3.993 (large) | [0.4261, 0.5269] | 24 |
| Adaptive vs bilateral | 25 | 0.0000 | Yes ✓ | 0.0001 | Yes ✓ | 1.058 (large) | [0.0245, 0.0570] | 24 |
| Adaptive vs guided | 25 | 0.0000 | Yes ✓ | 0.0001 | Yes ✓ | 1.219 (large) | [0.0254, 0.0524] | 24 |
| Adaptive vs l0 | 25 | 0.0047 | Yes ✓ | 0.0061 | Yes ✓ | -0.638 (medium) | [-0.1483, -0.0302] | 24 |
| Adaptive vs lgss | 25 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -1.787 (large) | [-0.2011, -0.1242] | 24 |
| Adaptive vs original | 25 | 0.2494 | No ✗ | 0.2904 | No ✗ | -0.241 (small) | [-0.1036, 0.0283] | 24 |
| Adaptive vs tv | 25 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | 5.080 (large) | [0.3116, 0.3681] | 24 |
| Adaptive vs bilateral | 50 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -2.550 (large) | [-0.0253, -0.0181] | 24 |
| Adaptive vs guided | 50 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -5.754 (large) | [-0.0311, -0.0268] | 24 |
| Adaptive vs l0 | 50 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -1.780 (large) | [-0.0880, -0.0543] | 24 |
| Adaptive vs lgss | 50 | 0.0007 | Yes ✓ | 0.0000 | Yes ✓ | -0.805 (large) | [-0.0938, -0.0292] | 24 |
| Adaptive vs original | 50 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | -1.589 (large) | [-0.1559, -0.0904] | 24 |
| Adaptive vs tv | 50 | 0.0000 | Yes ✓ | 0.0000 | Yes ✓ | 2.539 (large) | [0.0405, 0.0567] | 24 |

### Dataset: Set12

| Comparison | Sigma | p (t-test) | Significant? | p (Wilcoxon) | Significant? | Cohen's d | 95% CI | N |
|---|---:|---:|---|---:|---:|---:|---:|---:|
| Adaptive vs bilateral | 10 | 0.0000 | Yes ✓ | 0.0022 | Yes ✓ | -3.548 (large) | [-0.2379, -0.1656] | 12 |
| Adaptive vs guided | 10 | 0.0000 | Yes ✓ | 0.0022 | Yes ✓ | -3.283 (large) | [-0.2127, -0.1437] | 12 |
| Adaptive vs l0 | 10 | 0.0221 | Yes ✓ | 0.0229 | Yes ✓ | 0.769 (medium) | [0.0044, 0.0464] | 12 |
| Adaptive vs lgss | 10 | 0.0000 | Yes ✓ | 0.0022 | Yes ✓ | -2.476 (large) | [-0.0932, -0.0552] | 12 |
| Adaptive vs original | 10 | 0.0000 | Yes ✓ | 0.0022 | Yes ✓ | 2.719 (large) | [0.0967, 0.1557] | 12 |
| Adaptive vs tv | 10 | 0.0000 | Yes ✓ | 0.0022 | Yes ✓ | 4.687 (large) | [0.3508, 0.4608] | 12 |
| Adaptive vs bilateral | 20 | 0.0013 | Yes ✓ | 0.0029 | Yes ✓ | 1.234 (large) | [0.0302, 0.0943] | 12 |
| Adaptive vs guided | 20 | 0.0003 | Yes ✓ | 0.0022 | Yes ✓ | 1.529 (large) | [0.0453, 0.1096] | 12 |
| Adaptive vs l0 | 20 | 0.0009 | Yes ✓ | 0.0029 | Yes ✓ | 1.309 (large) | [0.0325, 0.0939] | 12 |
| Adaptive vs lgss | 20 | 0.0000 | Yes ✓ | 0.0029 | Yes ✓ | -2.027 (large) | [-0.0609, -0.0318] | 12 |
| Adaptive vs original | 20 | 0.0000 | Yes ✓ | 0.0022 | Yes ✓ | 2.439 (large) | [0.1140, 0.1944] | 12 |
| Adaptive vs tv | 20 | 0.0000 | Yes ✓ | 0.0022 | Yes ✓ | 8.152 (large) | [0.4337, 0.5070] | 12 |
| Adaptive vs bilateral | 25 | 0.0000 | Yes ✓ | 0.0022 | Yes ✓ | 2.329 (large) | [0.0336, 0.0589] | 12 |
| Adaptive vs guided | 25 | 0.0000 | Yes ✓ | 0.0022 | Yes ✓ | 2.449 (large) | [0.0389, 0.0661] | 12 |
| Adaptive vs l0 | 25 | 0.0031 | Yes ✓ | 0.0060 | Yes ✓ | -1.089 (large) | [-0.1451, -0.0381] | 12 |
| Adaptive vs lgss | 25 | 0.0000 | Yes ✓ | 0.0022 | Yes ✓ | -2.873 (large) | [-0.1988, -0.1268] | 12 |
| Adaptive vs original | 25 | 0.6267 | No ✗ | 0.6949 | No ✗ | -0.144 (negligible) | [-0.0784, 0.0494] | 12 |
| Adaptive vs tv | 25 | 0.0000 | Yes ✓ | 0.0022 | Yes ✓ | 19.565 (large) | [0.3279, 0.3499] | 12 |
| Adaptive vs bilateral | 50 | 0.0000 | Yes ✓ | 0.0022 | Yes ✓ | -8.190 (large) | [-0.0273, -0.0234] | 12 |
| Adaptive vs guided | 50 | 0.0000 | Yes ✓ | 0.0022 | Yes ✓ | -7.594 (large) | [-0.0329, -0.0278] | 12 |
| Adaptive vs l0 | 50 | 0.0000 | Yes ✓ | 0.0022 | Yes ✓ | -5.393 (large) | [-0.0860, -0.0678] | 12 |
| Adaptive vs lgss | 50 | 0.0001 | Yes ✓ | 0.0022 | Yes ✓ | -1.795 (large) | [-0.0877, -0.0418] | 12 |
| Adaptive vs original | 50 | 0.0000 | Yes ✓ | 0.0022 | Yes ✓ | -4.168 (large) | [-0.1518, -0.1117] | 12 |
| Adaptive vs tv | 50 | 0.0000 | Yes ✓ | 0.0022 | Yes ✓ | 5.582 (large) | [0.0446, 0.0561] | 12 |

### Dataset: custom

| Comparison | Sigma | p (t-test) | Significant? | p (Wilcoxon) | Significant? | Cohen's d | 95% CI | N |
|---|---:|---:|---|---:|---:|---:|---:|---:|
| Adaptive vs bilateral | 10 | 0.0342 | Yes ✓ | 0.1088 | No ✗ | -3.043 (large) | [-0.3075, -0.0311] | 3 |
| Adaptive vs guided | 10 | 0.0419 | Yes ✓ | 0.1088 | No ✗ | -2.730 (large) | [-0.2809, -0.0132] | 3 |
| Adaptive vs l0 | 10 | 0.6527 | No ✗ | 0.5930 | No ✗ | 0.302 (small) | [-0.0458, 0.0584] | 3 |
| Adaptive vs original | 10 | 0.0328 | Yes ✓ | 0.1088 | No ✗ | 3.108 (large) | [0.0173, 0.1554] | 3 |
| Adaptive vs bilateral | 20 | 0.0267 | Yes ✓ | 0.1088 | No ✗ | 3.465 (large) | [0.0274, 0.1666] | 3 |
| Adaptive vs guided | 20 | 0.0057 | Yes ✓ | 0.1088 | No ✗ | 7.642 (large) | [0.0781, 0.1533] | 3 |
| Adaptive vs l0 | 20 | 0.1167 | No ✗ | 0.1088 | No ✗ | 1.539 (large) | [-0.0214, 0.0912] | 3 |
| Adaptive vs lgss | 20 | 0.0252 | Yes ✓ | 0.1088 | No ✗ | -3.571 (large) | [-0.0803, -0.0144] | 3 |
| Adaptive vs original | 20 | 0.0569 | No ✗ | 0.1088 | No ✗ | 2.317 (large) | [-0.0075, 0.2143] | 3 |
| Adaptive vs tv | 20 | 0.0035 | Yes ✓ | 0.1088 | No ✗ | 9.723 (large) | [0.3801, 0.6410] | 3 |
| Adaptive vs bilateral | 25 | 0.0492 | Yes ✓ | 0.1088 | No ✗ | 2.506 (large) | [0.0005, 0.1196] | 3 |
| Adaptive vs guided | 25 | 0.0234 | Yes ✓ | 0.1088 | No ✗ | 3.709 (large) | [0.0233, 0.1176] | 3 |
| Adaptive vs l0 | 25 | 0.0345 | Yes ✓ | 0.1088 | No ✗ | -3.026 (large) | [-0.2610, -0.0257] | 3 |
| Adaptive vs lgss | 25 | 0.0133 | Yes ✓ | 0.1088 | No ✗ | -4.964 (large) | [-0.2924, -0.0974] | 3 |
| Adaptive vs original | 25 | 0.1364 | No ✗ | 0.1088 | No ✗ | -1.399 (large) | [-0.2415, 0.0675] | 3 |
| Adaptive vs tv | 25 | 0.0020 | Yes ✓ | 0.1088 | No ✗ | 13.051 (large) | [0.2841, 0.4177] | 3 |
| Adaptive vs bilateral | 50 | 0.0166 | Yes ✓ | 0.1088 | No ✗ | -4.432 (large) | [-0.0369, -0.0104] | 3 |
| Adaptive vs guided | 50 | 0.0109 | Yes ✓ | 0.1088 | No ✗ | -5.491 (large) | [-0.0388, -0.0146] | 3 |
| Adaptive vs l0 | 50 | 0.0020 | Yes ✓ | 0.1088 | No ✗ | -12.845 (large) | [-0.0968, -0.0654] | 3 |
| Adaptive vs lgss | 50 | 0.1029 | No ✗ | 0.1088 | No ✗ | -1.658 (large) | [-0.1659, 0.0331] | 3 |
| Adaptive vs original | 50 | 0.0045 | Yes ✓ | 0.1088 | No ✗ | -8.581 (large) | [-0.1646, -0.0907] | 3 |
| Adaptive vs tv | 50 | 0.0169 | Yes ✓ | 0.1088 | No ✗ | 4.380 (large) | [0.0210, 0.0760] | 3 |

---

## Summary

### PSNR — Significance Decisions

**Adaptive vs bilateral**: Adaptive wins significantly in 0, loses in 15, not significant in 1 (out of 16).
**Adaptive vs guided**: Adaptive wins significantly in 0, loses in 13, not significant in 3 (out of 16).
**Adaptive vs l0**: Adaptive wins significantly in 9, loses in 4, not significant in 3 (out of 16).
**Adaptive vs lgss**: Adaptive wins significantly in 0, loses in 13, not significant in 2 (out of 15).
**Adaptive vs original**: Adaptive wins significantly in 11, loses in 4, not significant in 1 (out of 16).
**Adaptive vs tv**: Adaptive wins significantly in 15, loses in 0, not significant in 0 (out of 15).

### SSIM — Significance Decisions

**Adaptive vs bilateral**: Adaptive wins significantly in 7, loses in 8, not significant in 1 (out of 16).
**Adaptive vs guided**: Adaptive wins significantly in 8, loses in 8, not significant in 0 (out of 16).
**Adaptive vs l0**: Adaptive wins significantly in 6, loses in 7, not significant in 3 (out of 16).
**Adaptive vs lgss**: Adaptive wins significantly in 0, loses in 14, not significant in 1 (out of 15).
**Adaptive vs original**: Adaptive wins significantly in 8, loses in 4, not significant in 4 (out of 16).
**Adaptive vs tv**: Adaptive wins significantly in 15, loses in 0, not significant in 0 (out of 15).

### Key Observations

1. **Effect sizes (Cohen's d)** across all comparisons:
   - PSNR: mean d = -0.438, range [-15.666, 33.472]
   - SSIM: mean d = 0.048, range [-12.845, 19.565]

2. **Datasets where Adaptive is consistently superior** (all comparisons significant with positive gain):

3. **Datasets where differences are mostly not significant**:

4. **Datasets where Adaptive performs worse** (significant negative gains):
   - BSD68 (sigma=10): Adaptive loses by 8.368 dB (p=0.0000)
   - BSD68 (sigma=10): Adaptive loses by 7.167 dB (p=0.0000)
   - BSD68 (sigma=10): Adaptive loses by 2.903 dB (p=0.0000)
   - BSD68 (sigma=20): Adaptive loses by 2.349 dB (p=0.0000)
   - BSD68 (sigma=20): Adaptive loses by 2.027 dB (p=0.0000)
   - BSD68 (sigma=20): Adaptive loses by 1.015 dB (p=0.0000)
   - BSD68 (sigma=25): Adaptive loses by 0.971 dB (p=0.0000)
   - BSD68 (sigma=25): Adaptive loses by 0.958 dB (p=0.0000)
   - BSD68 (sigma=25): Adaptive loses by 0.788 dB (p=0.0000)
   - BSD68 (sigma=50): Adaptive loses by 1.352 dB (p=0.0000)
   - BSD68 (sigma=50): Adaptive loses by 1.754 dB (p=0.0000)
   - BSD68 (sigma=50): Adaptive loses by 2.220 dB (p=0.0000)
   - BSD68 (sigma=50): Adaptive loses by 0.924 dB (p=0.0000)
   - BSD68 (sigma=50): Adaptive loses by 2.432 dB (p=0.0000)
   - Kodak24 (sigma=10): Adaptive loses by 8.648 dB (p=0.0000)
   - Kodak24 (sigma=10): Adaptive loses by 7.426 dB (p=0.0000)
   - Kodak24 (sigma=10): Adaptive loses by 3.313 dB (p=0.0000)
   - Kodak24 (sigma=20): Adaptive loses by 2.042 dB (p=0.0000)
   - Kodak24 (sigma=20): Adaptive loses by 1.787 dB (p=0.0000)
   - Kodak24 (sigma=20): Adaptive loses by 1.295 dB (p=0.0000)
   - Kodak24 (sigma=25): Adaptive loses by 0.877 dB (p=0.0000)
   - Kodak24 (sigma=25): Adaptive loses by 0.927 dB (p=0.0000)
   - Kodak24 (sigma=25): Adaptive loses by 1.220 dB (p=0.0000)
   - Kodak24 (sigma=50): Adaptive loses by 1.427 dB (p=0.0000)
   - Kodak24 (sigma=50): Adaptive loses by 1.829 dB (p=0.0000)
   - Kodak24 (sigma=50): Adaptive loses by 2.382 dB (p=0.0000)
   - Kodak24 (sigma=50): Adaptive loses by 0.946 dB (p=0.0000)
   - Kodak24 (sigma=50): Adaptive loses by 2.494 dB (p=0.0000)
   - Set12 (sigma=10): Adaptive loses by 9.115 dB (p=0.0000)
   - Set12 (sigma=10): Adaptive loses by 7.511 dB (p=0.0000)
   - Set12 (sigma=10): Adaptive loses by 2.688 dB (p=0.0000)
   - Set12 (sigma=20): Adaptive loses by 1.977 dB (p=0.0000)
   - Set12 (sigma=20): Adaptive loses by 1.446 dB (p=0.0001)
   - Set12 (sigma=20): Adaptive loses by 0.645 dB (p=0.0021)
   - Set12 (sigma=25): Adaptive loses by 0.677 dB (p=0.0000)
   - Set12 (sigma=25): Adaptive loses by 0.539 dB (p=0.0001)
   - Set12 (sigma=25): Adaptive loses by 0.944 dB (p=0.0002)
   - Set12 (sigma=50): Adaptive loses by 1.375 dB (p=0.0000)
   - Set12 (sigma=50): Adaptive loses by 1.740 dB (p=0.0000)
   - Set12 (sigma=50): Adaptive loses by 2.347 dB (p=0.0000)
   - Set12 (sigma=50): Adaptive loses by 1.090 dB (p=0.0000)
   - Set12 (sigma=50): Adaptive loses by 2.511 dB (p=0.0000)
   - custom (sigma=10): Adaptive loses by 8.784 dB (p=0.0400)
   - custom (sigma=25): Adaptive loses by 0.620 dB (p=0.0026)
   - custom (sigma=50): Adaptive loses by 1.366 dB (p=0.0023)
   - custom (sigma=50): Adaptive loses by 1.694 dB (p=0.0039)
   - custom (sigma=50): Adaptive loses by 2.411 dB (p=0.0020)
   - custom (sigma=50): Adaptive loses by 1.168 dB (p=0.0082)
   - custom (sigma=50): Adaptive loses by 2.505 dB (p=0.0019)

5. **Effect size interpretation** (Cohen, 1988):
   - |d| < 0.2: negligible
   - 0.2 ≤ |d| < 0.5: small
   - 0.5 ≤ |d| < 0.8: medium
   - |d| ≥ 0.8: large

---
*Report generated by `perform_statistical_tests.m`*
