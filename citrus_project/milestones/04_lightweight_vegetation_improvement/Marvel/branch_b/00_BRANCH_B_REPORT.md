# Branch B Report - LiDAR-Only Continued Training Control

## Status Snapshot

Status: completed and evaluated locally on 2026-06-10.

Official selected checkpoint for raw metric-depth reporting:

```text
Branch B weights_24
```

Final/latest checkpoint kept for comparison:

```text
Branch B weights_29
```

Current Branch B/C verdict:

```text
Branch B weights_24 very slightly beats Branch C weights_24 on test raw abs_rel/a1,
but the visual difference is tiny and not enough to claim a decisive qualitative win.
```

Practical conclusion:

```text
Masked LiDAR-supervised continuation is the main proven improvement signal so far.
RGB edge-aware smoothness remains experimental/unproven under the current recipe.
```

Next action:

```text
Use Branch B weights_24 for raw-depth reporting, keep Branch C weights_24 and Branch B weights_29 as comparison checkpoints, and avoid claiming that RGB smoothness is beneficial unless a later branch shows clearer evidence.
`$([Environment]::NewLine)
## Purpose

Branch B is the fair control for Branch C.

Branch C used masked LiDAR supervision plus RGB edge-aware smoothness. Branch B removes the RGB smoothness term while keeping the rest of the recipe matched. This tests whether Branch C improved because of RGB edge-aware smoothness, or mostly because of additional LiDAR-supervised training from the same starting checkpoint.

## Branch Definition

Branch B:

```text
Branch A / Hybrid weights_13
+ masked LiDAR log-L1 depth supervision
+ no photometric loss
+ no RGB edge-aware smoothness
```

Fair comparison target:

```text
Branch C = same setup + RGB edge-aware smoothness
```

Only intended recipe difference:

```text
Branch B: --disparity_smoothness 0
Branch C: --disparity_smoothness 0.001
```

## Fairness Conditions

Branch B must match Branch C on the starting checkpoint, prepared dataset, splits, dense LiDAR labels, valid masks, batch size, epoch count, optimizer, scheduler, seed, image size, evaluator, checkpoint sweep, and test-confirmation process.

The matched starting checkpoint is:

```text
citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/runs/hybrid_supervised_b12_30ep_logl1_abs_w01_fresh_sched/models/weights_13
```

## Current Verdict

Completed locally on 2026-06-10:

1. Two-epoch smoke/evaluation.
2. Full 30-epoch training/evaluation.
3. Validation checkpoint sweep.
4. Test confirmation of top validation candidates plus final/latest checkpoint.
5. Best-vs-latest visual comparison.
6. Branch B selected-checkpoint versus Branch C selected-checkpoint visual comparison.

Branch B is no longer just a weak control. The checkpoint sweep selected Branch B `weights_24` for raw metric-depth reporting, and it very slightly beats Branch C `weights_24` on test raw abs_rel/a1.

The margin is tiny, and the visual panels are nearly indistinguishable. The honest conclusion is that masked LiDAR-supervised continuation explains most of the Branch C-level gain. RGB edge-aware smoothness is not yet proven to add meaningful value under the current recipe.

## Key Metrics

| Model | Split | Raw abs_rel | Raw a1 | Median abs_rel | Median a1 |
|---|---:|---:|---:|---:|---:|
| Branch B 2ep | val | 0.1682 | 0.8465 | 0.1717 | 0.8380 |
| Branch C 2ep | val | 0.1682 | 0.8465 | 0.1717 | 0.8380 |
| Branch B weights_24 | val | 0.1530 | 0.8672 | 0.1562 | 0.8640 |
| Branch C weights_24 | val | 0.1531 | 0.8673 | 0.1562 | 0.8641 |
| Branch B weights_29 | val | 0.1561 | 0.8667 | 0.1580 | 0.8640 |
| Branch B 2ep | test | 0.1525 | 0.8498 | 0.1572 | 0.8420 |
| Branch C 2ep | test | 0.1525 | 0.8498 | 0.1571 | 0.8420 |
| Branch B weights_24 | test | 0.1382 | 0.8695 | 0.1436 | 0.8661 |
| Branch C weights_24 | test | 0.1384 | 0.8694 | 0.1437 | 0.8657 |
| Branch B weights_29 | test | 0.1398 | 0.8735 | 0.1435 | 0.8678 |

Interpretation of the table:

1. Branch B and Branch C are effectively tied at two epochs.
2. Branch B `weights_24` is the selected raw-depth checkpoint after sweep.
3. Branch B `weights_29` remains strongest for median-scaled test metrics, but it is not the validation-selected raw-depth checkpoint.
4. Branch B `weights_24` versus Branch C `weights_24` is too close to claim a decisive visual or scientific win for either recipe.

## Checkpoint Sweep

Sweep folder:

```text
citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/branch_b/branch_b_lidar_only_continued/results/branch_b_lidar_only_from_w13_b12_30ep_s001_laptop/checkpoint_sweep/
```

Sweep files:

```text
val_sweep_summary.csv
val_sweep_summary.json
test_confirm_summary.csv
test_confirm_summary.json
```

Selected Branch B checkpoint:

```text
weights_24
```

Validation sweep result:

| Checkpoint | Val raw abs_rel | Val raw a1 | Val median abs_rel | Val median a1 |
|---|---:|---:|---:|---:|
| Branch B weights_24 | 0.1530 | 0.8672 | 0.1562 | 0.8640 |
| Branch B weights_29 | 0.1561 | 0.8667 | 0.1580 | 0.8640 |

Test confirmation:

| Checkpoint | Test raw abs_rel | Test raw a1 | Test median abs_rel | Test median a1 |
|---|---:|---:|---:|---:|
| Branch B weights_24 | 0.1382 | 0.8695 | 0.1436 | 0.8661 |
| Branch B weights_29 | 0.1398 | 0.8735 | 0.1435 | 0.8678 |
| Branch C weights_24 | 0.1384 | 0.8694 | 0.1437 | 0.8657 |

## Visual Evidence

Best-vs-latest Branch B panels:

```text
citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/branch_b/branch_b_lidar_only_continued/results/branch_b_lidar_only_from_w13_b12_30ep_s001_laptop/checkpoint_sweep/visuals/branch_b_w24_vs_w29_val/
citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/branch_b/branch_b_lidar_only_continued/results/branch_b_lidar_only_from_w13_b12_30ep_s001_laptop/checkpoint_sweep/visuals/branch_b_w24_vs_w29_test/
```

Branch B selected checkpoint versus Branch C selected checkpoint:

```text
citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/branch_b/branch_b_lidar_only_continued/results/branch_b_lidar_only_from_w13_b12_30ep_s001_laptop/checkpoint_sweep/visuals/branch_b_w24_vs_branch_c_w24_val/
citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/branch_b/branch_b_lidar_only_continued/results/branch_b_lidar_only_from_w13_b12_30ep_s001_laptop/checkpoint_sweep/visuals/branch_b_w24_vs_branch_c_w24_test/
```

Earlier final-vs-C comparison, kept for reference:

```text
citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/branch_b/branch_b_lidar_only_continued/results/branch_b_lidar_only_from_w13_b12_30ep_s001_laptop/visuals/branch_b_w29_vs_branch_c_w24/
```

Visual reading:

1. Branch B `weights_24` and Branch B `weights_29` are visually very close.
2. `weights_29` sometimes gives slightly stronger tree/body contrast, but the validation-first sweep still favors `weights_24` for raw depth metrics.
3. Branch B `weights_24` and Branch C `weights_24` are almost indistinguishable on selected good/typical/bad test panels.
4. Difference maps between B24 and C24 are tiny; some local regions favor B and some favor C.
5. There is no visual evidence that RGB edge-aware smoothness clearly dominates LiDAR-only continuation.

## Output Folders

Two-epoch smoke/evaluation result:

```text
citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/branch_b/branch_b_lidar_only_continued/results/branch_b_lidar_only_from_w13_b12_2ep_s001_laptop/
```

Full 30-epoch run folder:

```text
citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/runs/branch_b_lidar_only_from_w13_b12_30ep_s001_laptop/
```

Full 30-epoch result folder:

```text
citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/branch_b/branch_b_lidar_only_continued/results/branch_b_lidar_only_from_w13_b12_30ep_s001_laptop/
```

Final checkpoint:

```text
citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/runs/branch_b_lidar_only_from_w13_b12_30ep_s001_laptop/models/weights_29/
```

Selected raw-depth checkpoint:

```text
citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/runs/branch_b_lidar_only_from_w13_b12_30ep_s001_laptop/models/weights_24/
```

## Script Fixes From Smoke

1. Branch B and Branch C launchers now locate the Lite-Mono repo root by walking upward until `utils.py` is found, instead of relying on brittle fixed parent counts.
2. Branch B and Branch C trainers use the same robust repo-root lookup before importing `citrus_prepared_dataset`.
3. `citrus_project/milestones/02_citrus_integration/citrus_prepared_dataset.py` was restored from git history because the local transfer folder was missing it.
4. `citrus_project/milestones/01_original_lite_mono_baseline/evaluate_lite_mono_citrus.py` was restored from git history because Branch B evaluation depends on it.
5. Branch B scripts now pass `--baseline_weights $BaseWeights` to visual generation so panels compare explicitly against Branch A `weights_13`.
6. Branch B 30ep script typo fixed: `weights_293` -> `weights_13`.

## Recommendation

Use Branch B `weights_24` as the selected Branch B checkpoint for raw metric-depth reporting. Keep Branch B `weights_29` as the latest/final checkpoint and strongest median-scaled test comparison.

For the paper direction, frame the current gain primarily around masked LiDAR-supervised Citrus adaptation. Branch C remains useful evidence, but under the current recipe RGB edge-aware smoothness should be described as optional/experimental rather than proven.

## Reminder For Lab Work

When the user says they are back at the lab, remind them to make Branch B fair by copying or reproducing the exact same local prepared dataset artifacts and starting checkpoint before training there.
