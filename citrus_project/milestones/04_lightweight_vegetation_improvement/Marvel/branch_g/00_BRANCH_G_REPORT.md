# Branch G Report - Original Lite-Mono Prior Preservation

## Purpose

Branch G tests a safer version of the full-frame visual sanity idea. Branch B already gives the best current Citrus LiDAR-supervised metric depth, but it can still look weak outside LiDAR-supported regions. Branch F tried a direct sky/far rule and regressed hard. Branch G is more conservative: keep Branch B as the student, keep LiDAR supervision as the main metric anchor, and use frozen original Lite-Mono only as a weak relative-disparity prior where LiDAR has no valid label.

## Method

Starting checkpoint: Branch B `weights_24`.

Teacher checkpoint: original Lite-Mono `weights/lite-mono`, frozen during training.

Training signal:

1. Valid LiDAR pixels use the same Branch B masked LiDAR `log_l1` depth supervision.
2. LiDAR-invalid pixels get a weak normalized-disparity L1 loss against frozen original Lite-Mono.
3. The original-prior target is normalized per image, so it teaches broad relative structure rather than raw metric scale.
4. No photometric loss, no generic RGB smoothness, no Branch F hand-coded sky distance rule.

## Smoke Recipe

Run name: `branch_g_original_prior_from_b24_b12_2ep_w005_laptop`

Main settings:

- base weights: Branch B `weights_24`
- original prior weight: `0.005`
- LiDAR loss weight: `0.1`
- LiDAR scale alignment: `none`
- prior mask: LiDAR-invalid pixels only
- epochs: `2`
- batch size: `12`

## Status

2-step CUDA runtime sanity check passed: Branch B student weights loaded, frozen original Lite-Mono teacher loaded, LiDAR loss and original-prior loss both logged, and backprop completed.

2-epoch smoke/eval completed for `branch_g_original_prior_from_b24_b12_2ep_w005_laptop`.

| Model | Split | Raw abs_rel | Raw a1 | Median abs_rel | Median a1 |
|---|---:|---:|---:|---:|---:|
| Branch G 2ep `weights_1` | val | 0.1576 | 0.8654 | 0.1609 | 0.8627 |
| Branch G 2ep `weights_1` | test | 0.1425 | 0.8739 | 0.1459 | 0.8685 |
| Branch B `weights_24` reference | val | 0.1530 | 0.8672 | 0.1562 | 0.8640 |
| Branch B `weights_24` reference | test | 0.1382 | 0.8695 | 0.1436 | 0.8661 |

Smoke verdict: successful enough to continue. Branch G is slightly worse than Branch B on raw abs_rel, but it does not collapse like Branch F and test raw/median a1 is slightly higher than Branch B. The longer run is justified as an overnight candidate, not as a proven improvement yet.

Generated smoke outputs:

- loss plots: `branch_g_original_prior/results/branch_g_original_prior_from_b24_b12_2ep_w005_laptop/loss_plots/`
- B-vs-G val panels: `branch_g_original_prior/results/branch_g_original_prior_from_b24_b12_2ep_w005_laptop/visuals/branch_b_w24_vs_branch_g_val/`
- B-vs-G test panels: `branch_g_original_prior/results/branch_g_original_prior_from_b24_b12_2ep_w005_laptop/visuals/branch_b_w24_vs_branch_g_test/`

30-epoch overnight run `branch_g_original_prior_from_b24_b12_30ep_w005_laptop` launched in the background as PID `10984`. It entered CUDA training and logged epoch 0 batch 0. The run script will produce final `weights_29` val/test eval, loss plots, and Branch B `weights_24` versus Branch G `weights_29` comparison panels. Overnight watcher PID `24904` is also running; it waits for the 30ep wrapper to finish, runs `run_branch_g_checkpoint_sweep_laptop.ps1`, and writes `00_BRANCH_G_OVERNIGHT_AUTO_REPORT.md`. Rough estimate from the 2ep smoke speed: about 11.5-12.5 hours of training, plus evaluation/sweep/report time.

## Success Criteria

Branch G is worth considering only if it keeps Branch B-level validation/test metrics while improving visual sanity in unsupported regions. If metrics regress like Branch F, reject the recipe or reduce the prior weight.
## Final 30ep Evaluation Status

Final `weights_29` training completed and final evaluation/picture generation completed before transport pause.

| Model | Split | Raw abs_rel | Raw a1 | Median abs_rel | Median a1 |
|---|---:|---:|---:|---:|---:|
| Branch G 30ep `weights_29` | val | 0.1582 | 0.8678 | 0.1603 | 0.8635 |
| Branch G 30ep `weights_29` | test | 0.1424 | 0.8751 | 0.1456 | 0.8713 |
| Branch B `weights_24` reference | val | 0.1530 | 0.8672 | 0.1562 | 0.8640 |
| Branch B `weights_24` reference | test | 0.1382 | 0.8695 | 0.1436 | 0.8661 |

Generated final outputs:

- final summaries: `branch_g_original_prior/results/branch_g_original_prior_from_b24_b12_30ep_w005_laptop/val_lite-mono_full_summary.json` and `test_lite-mono_full_summary.json`
- final B-vs-G val panels: `branch_g_original_prior/results/branch_g_original_prior_from_b24_b12_30ep_w005_laptop/visuals/branch_b_w24_vs_branch_g_final_val/`
- final B-vs-G test panels: `branch_g_original_prior/results/branch_g_original_prior_from_b24_b12_30ep_w005_laptop/visuals/branch_b_w24_vs_branch_g_final_test/`

Checkpoint sweep status: completed, including the clean CUDA resweep for `weights_0` through `weights_6`.

Selected checkpoint: Branch G `weights_0` by validation-first raw abs_rel.

| Model | Split | Raw abs_rel | Raw a1 | Median abs_rel | Median a1 |
|---|---:|---:|---:|---:|---:|
| Branch G `weights_0` | val | 0.1524 | 0.8658 | 0.1564 | 0.8616 |
| Branch G `weights_0` | test | 0.1375 | 0.8739 | 0.1406 | 0.8721 |
| Branch G `weights_29` | test | 0.1424 | 0.8751 | 0.1456 | 0.8713 |
| Branch B `weights_24` reference | test | 0.1382 | 0.8695 | 0.1436 | 0.8661 |

Interpretation: Branch G `weights_0` is a small metric improvement over Branch B `weights_24` by test raw abs_rel and median abs_rel, while Branch G `weights_29` keeps slightly higher raw a1 than `weights_0`. The improvement is real in the metric table but visually subtle; treat it as a promising incremental result, not a dramatic qualitative leap.

Generated post-sweep outputs:

- clean CUDA early-checkpoint resweep: `branch_g_original_prior/results/branch_g_original_prior_from_b24_b12_30ep_w005_laptop/checkpoint_sweep_cuda_resweep_0_6/`
- Branch G best vs latest panels: `checkpoint_sweep/visuals/branch_g_w0_vs_w29_val/` and `checkpoint_sweep/visuals/branch_g_w0_vs_w29_test/`
- Branch G best vs Branch B panels: `checkpoint_sweep/visuals/branch_g_w0_vs_branch_b_w24_val/` and `checkpoint_sweep/visuals/branch_g_w0_vs_branch_b_w24_test/`
- external-image sanity panels for Branch G `weights_0` and `weights_29`: `external_image_sanity_test/outputs_branch_g_w0_vs_w29/`
Additional external sanity artifact: generated big comparison panels with Original Lite-Mono, Branch B `weights_24`, Branch C `weights_24`, Branch F `weights_1`, Branch G best `weights_0`, and Branch G latest `weights_29` under `external_image_sanity_test/outputs_big_original_b_c_f_g_median_scaled/`. These panels include raw disparity plus median-normalized depth views. Because external images have no LiDAR ground truth, this is relative per-image median normalization for qualitative shape comparison, not GT median scaling.
## Official Current Best Model

Decision on 2026-06-12: Branch G `weights_0` is the official current best model for the Milestone 4 Marvel branch workstream.

Reason:

1. It is the best confirmed checkpoint by the current validation-first selection protocol.
2. It slightly improves over Branch B `weights_24` and Branch C `weights_24` on the key test depth metrics.
3. It has the best current balance between Citrus metric depth and general visual sanity, although the visual gain is subtle rather than dramatic.

Important caveat: Branch G `weights_0` should be described as an incremental improvement, not a breakthrough. Manual visual inspection still shows cases where it is not clearly better-looking than the simpler Branch B/C checkpoints. The next useful step is failure-case analysis and presentation/report packaging, not another blind training run.
