# Model Weights

This folder contains selected inference checkpoint weights for Hybrid Lite-Mono. Each model folder contains:

```text
encoder.pth
depth.pth
```

These are intentionally selected checkpoints only, not full training runs or every epoch.

## Included Checkpoints

| Folder | Meaning | Test raw abs_rel | Test raw a1 | Test median abs_rel | Test median a1 |
|---|---|---:|---:|---:|---:|
| `original_lite_mono` | Original pretrained Lite-Mono baseline | 0.7273 | 0.0149 | 0.3836 | 0.4989 |
| `branch_a_hybrid_w13` | Earlier Hybrid / Branch A selected checkpoint | 0.1620 | 0.8149 | 0.1677 | 0.8159 |
| `branch_b_lidar_only_w24` | Branch B LiDAR-only continued-training control | 0.1382 | 0.8695 | 0.1436 | 0.8661 |
| `branch_c_rgb_edge_w24` | Branch C LiDAR + RGB edge-aware smoothness | 0.1384 | 0.8694 | 0.1437 | 0.8657 |
| `branch_g_original_prior_w0` | Branch G original-prior selected checkpoint; current best balance | 0.1375 | 0.8739 | 0.1406 | 0.8721 |

## Notes

- The selected current best model is `branch_g_original_prior_w0`.
- Branch B `branch_b_lidar_only_w24` should remain the main simple control.
- Branch C is included because it is the RGB smoothness ablation that did not clearly beat Branch B.
- The original baseline is included so external readers can compare inference behavior without downloading separate weights.
- These weights are for inference/evaluation convenience. They do not include optimizer states, TensorBoard logs, full epoch histories, or datasets.

Large datasets, dense LiDAR labels, generated figures, and full run folders are still intentionally excluded from this repository.
