import csv
import statistics
import math
from collections import defaultdict, Counter

rows = []
with open(r'D:\Adaptive-and-Learning-Guided-Extensions-of-Semi-Sparsity-for-Image-Smoothing\results\results_table.csv', 'r') as f:
    reader = csv.DictReader(f)
    for r in reader:
        r['psnr'] = float(r['psnr'])
        r['ssim'] = float(r['ssim'])
        r['runtime'] = float(r['runtime'])
        r['sigma'] = int(r['sigma'])
        r['realization'] = int(r['realization'])
        rows.append(r)

print(f'Total rows: {len(rows)}')
datasets = sorted(set(r['dataset'] for r in rows))
methods = sorted(set(r['method'] for r in rows))
sigmas = sorted(set(r['sigma'] for r in rows))
print(f'Datasets: {datasets}')
print(f'Methods: {methods}')
print(f'Sigmas: {sigmas}')

# Group by (dataset, image, sigma, method) and average over realizations
grouped = defaultdict(list)
for r in rows:
    key = (r['dataset'], r['image'], r['sigma'], r['method'])
    grouped[key].append(r)

avg_data = {}
for key, rs in grouped.items():
    avg_data[key] = {
        'psnr': statistics.mean([r['psnr'] for r in rs]),
        'ssim': statistics.mean([r['ssim'] for r in rs]),
        'runtime': statistics.mean([r['runtime'] for r in rs]),
    }

# Build lookup: (dataset, image, sigma) -> method -> metrics
lookup = defaultdict(dict)
for key, vals in avg_data.items():
    ds, img, sig, method = key
    lookup[(ds, img, sig)][method] = vals

# ============================================================
# SIGMA=50 ANALYSIS: adaptive vs original
# ============================================================
print()
print('=' * 80)
print('SIGMA=50 ANALYSIS: adaptive vs original')
print('=' * 80)

sigma50_pairs = []
for (ds, img, sig), methods_dict in lookup.items():
    if sig == 50 and 'adaptive' in methods_dict and 'original' in methods_dict:
        sigma50_pairs.append({
            'dataset': ds,
            'image': img,
            'adaptive_psnr': methods_dict['adaptive']['psnr'],
            'original_psnr': methods_dict['original']['psnr'],
            'adaptive_ssim': methods_dict['adaptive']['ssim'],
            'original_ssim': methods_dict['original']['ssim'],
        })

print(f'Number of image pairs at sigma=50: {len(sigma50_pairs)}')

# Compute differences
psnr_diffs = [p['adaptive_psnr'] - p['original_psnr'] for p in sigma50_pairs]
ssim_diffs = [p['adaptive_ssim'] - p['original_ssim'] for p in sigma50_pairs]

# PSNR stats
n = len(psnr_diffs)
print(f'\n--- PSNR Difference (adaptive - original) ---')
print(f'Mean:   {statistics.mean(psnr_diffs):.6f} dB')
print(f'Median: {statistics.median(psnr_diffs):.6f} dB')
print(f'Std:    {statistics.stdev(psnr_diffs):.6f} dB')
print(f'Min:    {min(psnr_diffs):.6f} dB (worst for adaptive)')
print(f'Max:    {max(psnr_diffs):.6f} dB (best for adaptive)')

wins = sum(1 for d in psnr_diffs if d > 0)
losses = sum(1 for d in psnr_diffs if d < 0)
ties = sum(1 for d in psnr_diffs if d == 0)
print(f'Wins (adaptive > original): {wins}')
print(f'Losses (adaptive < original): {losses}')
print(f'Ties: {ties}')

# Paired t-test approximation
mean_diff = statistics.mean(psnr_diffs)
std_diff = statistics.stdev(psnr_diffs)
se = std_diff / math.sqrt(n)
t_stat = mean_diff / se
print(f't-statistic: {t_stat:.4f} (df={n-1})')
try:
    from scipy import stats as sp_stats
    p_val = sp_stats.ttest_rel(
        [p['adaptive_psnr'] for p in sigma50_pairs],
        [p['original_psnr'] for p in sigma50_pairs]
    ).pvalue
    print(f'Paired t-test p-value: {p_val:.2e}')
except ImportError:
    # Simple normal approximation for large n
    abs_t = abs(t_stat)
    p_approx = 2 * 0.5 * math.erfc(abs_t / math.sqrt(2))
    print(f'Approx p-value (normal approx): {p_approx:.2e}')

# SSIM stats
print(f'\n--- SSIM Difference (adaptive - original) ---')
print(f'Mean:   {statistics.mean(ssim_diffs):.6f}')
print(f'Median: {statistics.median(ssim_diffs):.6f}')
print(f'Std:    {statistics.stdev(ssim_diffs):.6f}')
print(f'Min:    {min(ssim_diffs):.6f} (worst for adaptive)')
print(f'Max:    {max(ssim_diffs):.6f} (best for adaptive)')

ssim_wins = sum(1 for d in ssim_diffs if d > 0)
ssim_losses = sum(1 for d in ssim_diffs if d < 0)
ssim_ties = sum(1 for d in ssim_diffs if d == 0)
print(f'Wins (adaptive > original): {ssim_wins}')
print(f'Losses (adaptive < original): {ssim_losses}')
print(f'Ties: {ssim_ties}')

ssim_mean_diff = statistics.mean(ssim_diffs)
ssim_std_diff = statistics.stdev(ssim_diffs)
ssim_se = ssim_std_diff / math.sqrt(n)
ssim_t = ssim_mean_diff / ssim_se
print(f't-statistic: {ssim_t:.4f} (df={n-1})')
try:
    ssim_p = sp_stats.ttest_rel(
        [p['adaptive_ssim'] for p in sigma50_pairs],
        [p['original_ssim'] for p in sigma50_pairs]
    ).pvalue
    print(f'Paired t-test p-value: {ssim_p:.2e}')
except:
    abs_t = abs(ssim_t)
    p_approx = 2 * 0.5 * math.erfc(abs_t / math.sqrt(2))
    print(f'Approx p-value (normal approx): {p_approx:.2e}')

# Show worst/best cases for PSNR
print(f'\n--- Worst 5 PSNR cases (adaptive < original) ---')
sorted_by_psnr = sorted(sigma50_pairs, key=lambda p: p['adaptive_psnr'] - p['original_psnr'])
for p in sorted_by_psnr[:5]:
    diff = p['adaptive_psnr'] - p['original_psnr']
    print(f"  {p['dataset']}/{p['image']}: adaptive={p['adaptive_psnr']:.4f}, original={p['original_psnr']:.4f}, diff={diff:.4f}")

print(f'\n--- Best 5 PSNR cases (adaptive > original) ---')
for p in sorted_by_psnr[-5:]:
    diff = p['adaptive_psnr'] - p['original_psnr']
    print(f"  {p['dataset']}/{p['image']}: adaptive={p['adaptive_psnr']:.4f}, original={p['original_psnr']:.4f}, diff={diff:.4f}")

print(f'\n--- Worst 5 SSIM cases (adaptive < original) ---')
sorted_by_ssim = sorted(sigma50_pairs, key=lambda p: p['adaptive_ssim'] - p['original_ssim'])
for p in sorted_by_ssim[:5]:
    diff = p['adaptive_ssim'] - p['original_ssim']
    print(f"  {p['dataset']}/{p['image']}: adaptive={p['adaptive_ssim']:.6f}, original={p['original_ssim']:.6f}, diff={diff:.6f}")

print(f'\n--- Best 5 SSIM cases (adaptive > original) ---')
for p in sorted_by_ssim[-5:]:
    diff = p['adaptive_ssim'] - p['original_ssim']
    print(f"  {p['dataset']}/{p['image']}: adaptive={p['adaptive_ssim']:.6f}, original={p['original_ssim']:.6f}, diff={diff:.6f}")

# ============================================================
# METHOD RANKING - ALL COMBINATIONS
# ============================================================
print()
print('=' * 80)
print('METHOD RANKING - ALL COMBINATIONS (all datasets, images, sigmas)')
print('=' * 80)

method_metrics = defaultdict(lambda: {'psnr': [], 'ssim': [], 'runtime': []})
for key, vals in avg_data.items():
    method = key[3]
    method_metrics[method]['psnr'].append(vals['psnr'])
    method_metrics[method]['ssim'].append(vals['ssim'])
    method_metrics[method]['runtime'].append(vals['runtime'])

print(f'\nMethod summary (across {len(avg_data)} dataset/image/sigma combos):')
print(f'{"Method":>12s} | {"Mean PSNR":>10s} | {"Mean SSIM":>10s} | {"Mean Runtime":>12s} | {"N":>4s}')
print('-' * 65)
for m in methods:
    n_combos = len(method_metrics[m]['psnr'])
    mean_psnr = statistics.mean(method_metrics[m]['psnr'])
    mean_ssim = statistics.mean(method_metrics[m]['ssim'])
    mean_rt = statistics.mean(method_metrics[m]['runtime'])
    print(f'{m:>12s} | {mean_psnr:>10.4f} | {mean_ssim:>10.6f} | {mean_rt:>12.4f} | {n_combos:>4d}')

# Rankings
psnr_means = {m: statistics.mean(method_metrics[m]['psnr']) for m in methods}
ssim_means = {m: statistics.mean(method_metrics[m]['ssim']) for m in methods}
rt_means = {m: statistics.mean(method_metrics[m]['runtime']) for m in methods}

psnr_ranked = sorted(psnr_means.keys(), key=lambda m: psnr_means[m], reverse=True)
ssim_ranked = sorted(ssim_means.keys(), key=lambda m: ssim_means[m], reverse=True)
rt_ranked = sorted(rt_means.keys(), key=lambda m: rt_means[m])

print(f'\n--- Rank by Mean PSNR (1=best/highest) ---')
for i, m in enumerate(psnr_ranked):
    print(f'  {i+1}. {m:>12s}: {psnr_means[m]:.4f} dB')

print(f'\n--- Rank by Mean SSIM (1=best/highest) ---')
for i, m in enumerate(ssim_ranked):
    print(f'  {i+1}. {m:>12s}: {ssim_means[m]:.6f}')

print(f'\n--- Rank by Mean Runtime (1=fastest/lowest) ---')
for i, m in enumerate(rt_ranked):
    print(f'  {i+1}. {m:>12s}: {rt_means[m]:.4f} s')

# Composite ranking
psnr_ranks = {m: psnr_ranked.index(m) + 1 for m in methods}
ssim_ranks = {m: ssim_ranked.index(m) + 1 for m in methods}
rt_ranks = {m: rt_ranked.index(m) + 1 for m in methods}
composite = {m: psnr_ranks[m] + ssim_ranks[m] + rt_ranks[m] for m in methods}
comp_ranked = sorted(composite.keys(), key=lambda m: composite[m])

print(f'\n--- Composite Ranking (sum of ranks; lower=better) ---')
for i, m in enumerate(comp_ranked):
    print(f'  {i+1}. {m:>12s}: composite={composite[m]} (PSNR_r={psnr_ranks[m]}, SSIM_r={ssim_ranks[m]}, RT_r={rt_ranks[m]})')

# ============================================================
# PER-DATASET RANKINGS
# ============================================================
print()
print('=' * 80)
print('PER-DATASET RANKINGS')
print('=' * 80)

for ds in datasets:
    ds_methods = defaultdict(lambda: {'psnr': [], 'ssim': [], 'runtime': []})
    for key, vals in avg_data.items():
        if key[0] == ds:
            method = key[3]
            ds_methods[method]['psnr'].append(vals['psnr'])
            ds_methods[method]['ssim'].append(vals['ssim'])
            ds_methods[method]['runtime'].append(vals['runtime'])

    print(f'\n--- Dataset: {ds} ---')
    print(f'  {"Method":>12s} | {"Mean PSNR":>10s} | {"Mean SSIM":>10s} | {"Mean Runtime":>12s}')
    print(f'  ' + '-' * 60)
    for m in sorted(ds_methods.keys()):
        mp = statistics.mean(ds_methods[m]['psnr'])
        ms = statistics.mean(ds_methods[m]['ssim'])
        mr = statistics.mean(ds_methods[m]['runtime'])
        print(f'  {m:>12s} | {mp:>10.4f} | {ms:>10.6f} | {mr:>12.4f}')

    ds_psnr_means = {m: statistics.mean(ds_methods[m]['psnr']) for m in ds_methods}
    ds_ssim_means = {m: statistics.mean(ds_methods[m]['ssim']) for m in ds_methods}
    ds_rt_means = {m: statistics.mean(ds_methods[m]['runtime']) for m in ds_methods}

    ds_psnr_ranked = sorted(ds_psnr_means.keys(), key=lambda m: ds_psnr_means[m], reverse=True)
    ds_ssim_ranked = sorted(ds_ssim_means.keys(), key=lambda m: ds_ssim_means[m], reverse=True)
    ds_rt_ranked = sorted(ds_rt_means.keys(), key=lambda m: ds_rt_means[m])

    ds_psnr_ranks = {m: ds_psnr_ranked.index(m) + 1 for m in ds_methods}
    ds_ssim_ranks = {m: ds_ssim_ranked.index(m) + 1 for m in ds_methods}
    ds_rt_ranks = {m: ds_rt_ranked.index(m) + 1 for m in ds_methods}
    ds_composite = {m: ds_psnr_ranks[m] + ds_ssim_ranks[m] + ds_rt_ranks[m] for m in ds_methods}
    ds_comp_ranked = sorted(ds_composite.keys(), key=lambda m: ds_composite[m])

    print(f'  PSNR rank:    ', end='')
    for i, m in enumerate(ds_psnr_ranked):
        print(f'{i + 1}:{m} ', end='')
    print()
    print(f'  SSIM rank:    ', end='')
    for i, m in enumerate(ds_ssim_ranked):
        print(f'{i + 1}:{m} ', end='')
    print()
    print(f'  Runtime rank: ', end='')
    for i, m in enumerate(ds_rt_ranked):
        print(f'{i + 1}:{m} ', end='')
    print()
    print(f'  Composite:    ', end='')
    for i, m in enumerate(ds_comp_ranked):
        print(f'{i + 1}:{m}({ds_composite[m]}) ', end='')
    print()

# ============================================================
# CONSISTENCY CHECK: Is overall ranking consistent across datasets?
# ============================================================
print()
print('=' * 80)
print('RANKING CONSISTENCY ANALYSIS')
print('=' * 80)

for m in methods:
    ds_composites = []
    ds_psnr_ranks_for_m = []
    for ds in datasets:
        ds_methods = defaultdict(lambda: {'psnr': [], 'ssim': [], 'runtime': []})
        for key, vals in avg_data.items():
            if key[0] == ds:
                method = key[3]
                ds_methods[method]['psnr'].append(vals['psnr'])
                ds_methods[method]['ssim'].append(vals['ssim'])
                ds_methods[method]['runtime'].append(vals['runtime'])

        ds_psnr_means = {mm: statistics.mean(ds_methods[mm]['psnr']) for mm in ds_methods}
        ds_ssim_means = {mm: statistics.mean(ds_methods[mm]['ssim']) for mm in ds_methods}
        ds_rt_means = {mm: statistics.mean(ds_methods[mm]['runtime']) for mm in ds_methods}

        ds_psnr_ranked_local = sorted(ds_psnr_means.keys(), key=lambda mm: ds_psnr_means[mm], reverse=True)
        ds_ssim_ranked_local = sorted(ds_ssim_means.keys(), key=lambda mm: ds_ssim_means[mm], reverse=True)
        ds_rt_ranked_local = sorted(ds_rt_means.keys(), key=lambda mm: ds_rt_means[mm])

        if m in ds_psnr_means:
            ds_composites.append(
                ds_psnr_ranked_local.index(m) + 1 +
                ds_ssim_ranked_local.index(m) + 1 +
                ds_rt_ranked_local.index(m) + 1
            )
            ds_psnr_ranks_for_m.append(ds_psnr_ranked_local.index(m) + 1)

    if ds_composites:
        print(f'{m:>12s}: composite range [{min(ds_composites)}-{max(ds_composites)}], mean={statistics.mean(ds_composites):.1f} | PSNR rank range [{min(ds_psnr_ranks_for_m)}-{max(ds_psnr_ranks_for_m)}]')
