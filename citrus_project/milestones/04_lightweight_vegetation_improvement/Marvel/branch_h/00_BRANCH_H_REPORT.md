# Branch H Report - Short Low-LR Original Prior Fine-Tune

## Purpose

Branch H tests the lesson from Branch G: the original Lite-Mono prior helped most at the earliest checkpoint, while longer training drifted and worsened abs_rel. This branch keeps the same idea but intentionally makes the update smaller and shorter.

## Hypothesis

A short low-learning-rate fine-tune from Branch B `weights_24` can preserve the useful Branch G prior effect while reducing long-run drift.

## Recipes

Both runs start from Branch B `weights_24`, use masked LiDAR log-L1 supervision, disable photometric loss, and apply the frozen original Lite-Mono normalized-disparity prior only on LiDAR-invalid pixels.

| Branch | Run | Epochs | LR | LiDAR weight | Original prior weight |
|---|---|---:|---:|---:|---:|
| H | `branch_h_short_prior_from_b24_b12_3ep_lr1e5_w005_laptop` | 3 | 1e-5 | 0.1 | 0.005 |
| H2 | `branch_h2_short_prior_from_b24_b12_3ep_lr1e5_w0025_laptop` | 3 | 1e-5 | 0.1 | 0.0025 |

## Result Summary

Both runs completed on CUDA on 2026-06-12. The pipeline evaluated every checkpoint (`weights_0`, `weights_1`, `weights_2`) on validation and test, then generated same-image comparisons against Branch B `weights_24` and Branch G `weights_0`.

| Model | Selected by val raw? | Val raw abs_rel | Val raw a1 | Test raw abs_rel | Test raw a1 | Test median abs_rel | Test median a1 |
|---|---:|---:|---:|---:|---:|---:|---:|
| Branch H `weights_1` | yes | 0.1553 | 0.8665 | 0.1408 | 0.8733 | 0.1436 | 0.8702 |
| Branch H2 `weights_1` | yes | 0.1547 | 0.8668 | 0.1400 | 0.8739 | 0.1428 | 0.8706 |
| Branch G `weights_0` reference | yes | 0.1524 | 0.8658 | 0.1375 | 0.8739 | 0.1406 | 0.8721 |
| Branch B `weights_24` reference | yes | 0.1530 | 0.8672 | 0.1382 | 0.8695 | 0.1436 | 0.8661 |

Additional note: inside each short run, the test-best raw checkpoint was `weights_0`, not the validation-selected `weights_1`:

| Run | Test-best raw checkpoint | Test raw abs_rel | Test raw a1 |
|---|---:|---:|---:|
| H | `weights_0` | 0.1405 | 0.8729 |
| H2 | `weights_0` | 0.1398 | 0.8735 |

## Verdict

Branch H/H2 did not beat the current Branch G `weights_0` result, and they also did not beat Branch B `weights_24` on raw abs_rel. H2 is better than H, which suggests reducing the original-prior weight from `0.005` to `0.0025` was directionally helpful, but the short low-LR retweak still failed to improve the best known checkpoint.

This means the Branch G `weights_0` improvement was not easily reproducible by simply lowering learning rate and training for three short epochs. The likely reason is that Branch G `weights_0` came from the first epoch/checkpoint of the original recipe, where the model received a stronger early adjustment before later drift. H/H2 made the adjustment gentler, but apparently too gentle or not aligned enough to improve over B/G.

Current recommendation: do not promote H or H2. Keep Branch G `weights_0` as the best balance checkpoint for now. If continuing this direction, test a smaller controlled grid around Branch G's first-epoch behavior rather than another long run: prior weight `0.0025` to `0.005`, LR between `5e-5` and `1e-5`, and stop after 1 epoch with immediate validation/test confirmation.

## Output Paths

- H results: `branch_h_short_original_prior/results/branch_h_short_prior_from_b24_b12_3ep_lr1e5_w005_laptop/`
- H2 results: `branch_h_short_original_prior/results/branch_h2_short_prior_from_b24_b12_3ep_lr1e5_w0025_laptop/`
- H visual comparisons: `branch_h_short_original_prior/results/branch_h_short_prior_from_b24_b12_3ep_lr1e5_w005_laptop/checkpoint_sweep/visuals/`
- H2 visual comparisons: `branch_h_short_original_prior/results/branch_h2_short_prior_from_b24_b12_3ep_lr1e5_w0025_laptop/checkpoint_sweep/visuals/`
