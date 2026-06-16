# Lite-Mono Citrus

This repository is a compact Lite-Mono research fork for the Citrus Farm monocular depth project. It contains the code, reports, plans, and research context needed to understand the current hybrid-supervised Citrus experiments and start writing the paper.

It is intentionally lightweight: datasets, model checkpoints, generated image panels, and large training outputs are not committed here.

## Read Order For Agents

1. `AGENTS.md`
2. `citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/00_BRANCH_EXPERIMENT_SUMMARY.md`
3. Branch reports:
   - `citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/branch_b/00_BRANCH_B_REPORT.md`
   - `citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/branch_c/00_BRANCH_C_REPORT.md`
   - `citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/branch_f/00_BRANCH_F_REPORT.md`
   - `citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/branch_g/00_BRANCH_G_REPORT.md`
   - `citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/branch_h/00_BRANCH_H_REPORT.md`
4. Supporting research notes in `citrus_project/research/`
5. Dataset pipeline scripts in `citrus_project/dataset_workspace/`

## Current Research Direction

The strongest current direction is hybrid supervised Lite-Mono adaptation for vegetation-dense agricultural scenes:

- RGB image is the only input at inference time.
- Dense projected LiDAR labels and valid masks are used during training/evaluation.
- Current best internal checkpoint: Branch G `weights_0`.
- Current caveat: Branch G improves the metric balance, but external sanity images still show broad depth regions rather than crisp object outlines.

## Excluded Artifacts

The following are intentionally not part of this repo:

- downloaded Citrus Farm ROS bags
- extracted RGB/depth/LiDAR files
- dense label NPZ files and valid-mask NPZ files
- trained checkpoints and model weights
- TensorBoard logs
- generated comparison PNG folders
- large `runs/`, `results/`, `outputs/`, `images/`, `weights/`, and cache folders

If paper figures are needed, use a small curated `figures/` folder later instead of committing full generated output trees.

## Preserved Context

The upstream Lite-Mono README is preserved at `docs/UPSTREAM_LITEMONO_README.md`.

The original active-project AGENTS file at repo-creation time is preserved at `docs/ORIGINAL_ACTIVE_PROJECT_AGENTS.md`.
