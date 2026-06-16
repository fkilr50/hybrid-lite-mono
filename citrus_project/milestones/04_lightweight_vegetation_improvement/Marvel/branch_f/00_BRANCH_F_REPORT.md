# Branch F Report - Full-Frame Sky/Tree Sanity Fine-Tune

## Status Snapshot

Status: 2-epoch smoke completed locally on 2026-06-10 and rejected as-is.

Current run:

```text
branch_f_full_frame_sanity_from_b24_b12_2ep_sky001_edge0005_laptop
```

Background launcher PID:

```text
26868
```

Starting checkpoint:

```text
Branch B weights_24
```

Branch F is not a fair-from-weights_13 ablation yet. It is a targeted repair fine-tune from the current metric-best Branch B checkpoint, designed to test whether the visible sky/tree failure can be improved without destroying LiDAR-depth metrics.

## Motivation

Branch B `weights_24` is currently the best raw metric-depth checkpoint, but visual inspection shows two full-frame problems that LiDAR-masked metrics do not punish strongly:

1. Tree regions can visually extend upward, making trees look taller than they should.
2. Sky can look bright/near like the ground, creating a cave-like full-frame depth map.

The forward path often looks correctly darker/farther, so the model is not broken. The issue is mainly unsupported full-frame scene sanity outside dense LiDAR supervision.

## Method

Branch F keeps the Branch B recipe as the depth anchor:

```text
Branch B weights_24
+ masked LiDAR log-L1 supervision
+ no photometric loss
+ no generic RGB smoothness
+ conservative sky/far prior
+ conservative sky-to-non-sky edge contrast prior
```

New losses:

1. Sky/far prior: detect conservative sky-like pixels in the upper image using RGB color, then penalize predictions that are closer than a target far depth.
2. Sky/tree anti-bleed prior: at vertical sky-to-non-sky transitions, require the non-sky pixel below to have larger disparity than the sky pixel above.

Both losses are active-pixel normalized and intentionally weak. They are not treated as ground truth. They are visual sanity priors aimed at the known cave/sky-bleed failure.

## Smoke Recipe

The launched 2-epoch smoke uses:

```text
--load_weights_folder Branch B weights_24
--lr 0.00005 0.0000025 31 0.00005 0.000005 31
--lidar_loss_weight 0.1
--lidar_scale_align none
--disparity_smoothness 0
--sky_far_prior_weight 0.01
--sky_far_prior_min_depth 40
--sky_prior_require_lidar_invalid
--sky_edge_contrast_weight 0.005
--sky_edge_contrast_margin 0.015
```

Estimated runtime is about 70-90 minutes plus evaluation/visual generation, based on Branch B laptop speed.

## Files

Branch code:

```text
citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/branch_f/branch_f_full_frame_sanity/
```

Smoke launcher:

```text
citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/branch_f/branch_f_full_frame_sanity/run_branch_f_2ep_smoke_eval_laptop.ps1
```

Expected run folder:

```text
citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/runs/branch_f_full_frame_sanity_from_b24_b12_2ep_sky001_edge0005_laptop/
```

Expected result folder:

```text
citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/branch_f/branch_f_full_frame_sanity/results/branch_f_full_frame_sanity_from_b24_b12_2ep_sky001_edge0005_laptop/
```


## Smoke Result

The 2-epoch Branch F smoke completed and produced `weights_1`, val/test metrics, loss plots, and Branch B-vs-Branch F visual panels.

Metrics versus the selected Branch B checkpoint:

| Model | Split | Raw abs_rel | Raw a1 | Median abs_rel | Median a1 |
|---|---:|---:|---:|---:|---:|
| Branch B weights_24 | val | 0.1530 | 0.8672 | 0.1562 | 0.8640 |
| Branch F weights_1 | val | 0.2391 | 0.8540 | 0.2358 | 0.8456 |
| Branch B weights_24 | test | 0.1382 | 0.8695 | 0.1436 | 0.8661 |
| Branch F weights_1 | test | 0.2492 | 0.8564 | 0.2446 | 0.8460 |

Verdict: do not continue this Branch F recipe to 30 epochs. The targeted sky/far prior can make some sky/open regions visually darker, but the metric regression is too large and external-image panels show it can become too aggressive on non-Citrus/portrait vegetation images.

The idea is still conceptually useful, but the current implementation is too blunt. A future revision should use a stronger sky mask or semantic segmentation, lower weights, freeze more of the model, or apply the prior as post-training calibration/regularization rather than broad fine-tuning.
## Validation Protocol

After the smoke finishes:

1. Check train/val loss curves.
2. Evaluate val and test metrics.
3. Generate Branch B `weights_24` vs Branch F visual panels.
4. Inspect sky brightness, tree-top bleed, forward path sanity, and raw/median-scaled metrics.
5. Only continue to a longer run if visual sanity improves without a major metric collapse.

## Decision Criteria

Promising if:

1. Sky becomes darker/farther in raw full-frame depth maps.
2. Tree tops bleed less into sky.
3. Forward path stays sane.
4. Test raw abs_rel/a1 remain close to Branch B `weights_24`.

Reject or revise if:

1. Sky mask causes obvious artifacts.
2. Tree canopies get flattened or unnaturally cut.
3. LiDAR-masked metrics degrade strongly.
4. The cave effect remains unchanged.
