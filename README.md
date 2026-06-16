# Hybrid Lite-Mono

Hybrid Lite-Mono is a research fork of Lite-Mono for monocular depth estimation in vegetation-dense agricultural scenes. The project adapts Lite-Mono to Citrus Farm using RGB images as the runtime input, while using projected LiDAR depth labels and valid masks during training and evaluation.

The goal is to keep inference lightweight and monocular while improving depth behavior in orchard environments where vegetation, shadows, occlusions, and weak texture cues make standard self-supervised monocular training unreliable.

## Method Overview

Hybrid Lite-Mono keeps the original Lite-Mono deployment style:

```text
RGB image -> Lite-Mono -> predicted depth
```

During training, the model also receives supervision from dense LiDAR-derived depth labels:

```text
RGB image -> Lite-Mono -> predicted depth
                         |
Dense LiDAR depth + valid mask -> supervised depth loss
```

LiDAR is not used as an inference input. It is used to guide training and to evaluate Citrus Farm depth predictions.

## Current Result Summary

The current best internal model is Branch G `weights_0`, selected by validation-first checkpoint scanning and test confirmation.

| Model | Test raw abs_rel | Test raw a1 | Test median abs_rel | Test median a1 |
|---|---:|---:|---:|---:|
| Original Lite-Mono | 0.7273 | 0.0149 | 0.3836 | 0.4989 |
| Hybrid supervised Branch A `weights_13` | 0.1620 | 0.8149 | 0.1677 | 0.8159 |
| Branch B `weights_24` | 0.1382 | 0.8695 | 0.1436 | 0.8661 |
| Branch C `weights_24` | 0.1384 | 0.8694 | 0.1437 | 0.8657 |
| Branch G `weights_0` | 0.1375 | 0.8739 | 0.1406 | 0.8721 |

Branch G is the current best balance by metric results, but the visual improvement is modest. External sanity checks show that it roughly identifies foreground/object regions, but object boundaries are still broad rather than crisp.

## Repository Layout

```text
.
├── networks/                         # Lite-Mono model components
├── datasets/                         # Dataset loaders from the original project
├── citrus_project/
│   ├── dataset_workspace/             # Citrus Farm download/extract/build scripts
│   ├── research/                      # Dataset notes, baseline notes, paper notes
│   └── milestones/
│       ├── 00_dataset_audit/
│       ├── 01_original_lite_mono_baseline/
│       ├── 02_citrus_integration/
│       ├── 03_self_supervised_adaptation/
│       └── 04_lightweight_vegetation_improvement/
│           └── Marvel/                # Hybrid Lite-Mono experiment branches
├── docs/
│   ├── ORIGINAL_ACTIVE_PROJECT_AGENTS.md
│   └── UPSTREAM_LITEMONO_README.md
├── train.py
├── trainer.py
├── test_simple.py
└── AGENTS.md                          # Detailed project context and collaboration notes
```

## Key Experiment Reports

Start with these files for the current research status:

- `citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/00_BRANCH_EXPERIMENT_SUMMARY.md`
- `citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/branch_b/00_BRANCH_B_REPORT.md`
- `citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/branch_c/00_BRANCH_C_REPORT.md`
- `citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/branch_g/00_BRANCH_G_REPORT.md`
- `citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/branch_h/00_BRANCH_H_REPORT.md`

## Dataset Pipeline

The Citrus Farm preparation pipeline is documented and implemented under `citrus_project/dataset_workspace/`.

Canonical script order:

1. `download_citrusfarm_seq_01_lidar.py`
2. `download_citrusfarm_seq_01_rgb_depth.py`
3. `extract_left_rgbd_from_raw.py`
4. `extract_lidar_from_raw.py`
5. `audit_projection_alignment.py`
6. `densify_lidar.py`
7. `build_training_dataset.py`

The dense LiDAR labels are project-generated labels, not official Citrus Farm ground truth. Valid masks must be used when training or evaluating against these labels.

## Artifacts Not Included

This repository intentionally excludes large generated artifacts:

- Citrus Farm ROS bags
- extracted RGB/depth/LiDAR files
- dense label `.npz` files and valid-mask `.npz` files
- trained model checkpoints and weights
- TensorBoard logs
- generated comparison images
- large `runs/`, `results/`, `outputs/`, `images/`, and `weights/` folders

Small curated figures can be added later for paper writing, but full generated output folders should stay outside git.

## Notes

This repository is research work in progress. The current strongest result is promising by Citrus LiDAR-valid metrics, but the main open problem is still qualitative boundary sharpness and broader generalization beyond Citrus Farm.

For detailed project context and collaboration notes, see `AGENTS.md`.

