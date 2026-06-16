# Hybrid Lite-Mono Training Journey

This document explains the experimental path that led to the current Hybrid Lite-Mono result. It is written as a chronological narrative so a new collaborator can understand not only what the final numbers are, but why the project moved through each stage.

## One-Sentence Summary

The project started from original Lite-Mono, found that normal self-supervised Citrus adaptation was unreliable, pivoted to masked LiDAR-supervised hybrid training, and eventually selected Branch G `weights_0` as the current best metric/visual balance while acknowledging that object-boundary sharpness is still unsolved.

## Core Constraint

Hybrid Lite-Mono must remain RGB-only at inference time:

```text
RGB image -> Lite-Mono -> predicted depth
```

LiDAR is used only for dataset construction, training supervision, and evaluation:

```text
RGB image -> Lite-Mono -> predicted depth
                         |
Projected dense LiDAR + valid mask -> supervised training/evaluation signal
```

This distinction matters. The method is not a LiDAR+RGB runtime model.

## Stage 0: Dataset And Label Pipeline

The first task was to make Citrus Farm usable for monocular depth experiments.

What was built:

1. Download scripts for selected Citrus Farm Sequence 01 LiDAR and ZED RGB/depth bags.
2. Extraction scripts for left RGB, ZED depth, and Velodyne LiDAR.
3. Timestamp pairing between RGB frames and LiDAR scans.
4. LiDAR-to-ZED projection and conservative densification.
5. Train/val/test split manifests and valid-mask outputs.

Important dataset decisions:

1. The dense LiDAR labels are project-generated labels, not official Citrus Farm ground truth.
2. The final projection route is `exact_lidar_parent_child_inverted`.
3. The final interpolation route is `local_idw`, chosen because it is more conservative in vegetation gaps than broad linear interpolation.
4. Valid masks must be used. Pixels outside the mask are not trusted LiDAR labels.
5. Time-block splits are used to reduce adjacent-frame leakage.

Why this matters for the paper:

The project contribution is not only a new training recipe. A major part of the work is a reproducible Citrus RGB-to-LiDAR-label pipeline that makes lightweight monocular depth experiments possible in this agricultural domain.

Key files:

- `citrus_project/dataset_workspace/`
- `citrus_project/research/dataset_notes.md`
- `citrus_project/milestones/00_dataset_audit/README.md`

## Stage 1: Original Lite-Mono Baseline

The first model baseline was the original pretrained Lite-Mono evaluated on Citrus validation and test splits.

Result summary:

| Model | Split | Raw abs_rel | Raw a1 | Median abs_rel | Median a1 |
|---|---:|---:|---:|---:|---:|
| Original Lite-Mono | val | 0.7128 | 0.0195 | 0.4176 | 0.4629 |
| Original Lite-Mono | test | 0.7273 | 0.0149 | 0.3836 | 0.4989 |

Interpretation:

1. Raw-scale performance is very poor on Citrus.
2. Median scaling improves the numbers, which means some relative structure remains useful.
3. The baseline has a strong domain and scale gap in agricultural scenes.
4. Original Lite-Mono can still look visually plausible on generic images because it carries broad pretraining priors, but that does not mean it is metrically correct on Citrus.

Key files:

- `citrus_project/milestones/01_original_lite_mono_baseline/README.md`
- `citrus_project/research/baseline_notes.md`

## Stage 2: Standard Self-Supervised Citrus Adaptation

The next question was whether standard Lite-Mono-style self-supervised adaptation could fix the Citrus domain gap.

What was tried:

1. Citrus trainer integration.
2. Temporal triplet loading.
3. Photometric/reprojection self-supervision.
4. Multiple smoke and pilot recipes.
5. Checks for batch size, loading correctness, train-image behavior, and sparse/dense label evaluation.

Main finding:

Photometric loss could improve while Citrus depth metrics and depth structure got worse.

Interpretation:

1. Vegetation texture, repeated leaves, shadows, occlusions, and weak absolute-scale cues make pure photometric supervision unreliable here.
2. The failure was not explained by one simple bug such as wrong weight loading, validation-only failure, batch size, or `local_idw` densification alone.
3. The project needed a stronger depth anchor than RGB reconstruction loss.

Paper-facing lesson:

This stage justifies the pivot away from pure self-supervised adaptation and toward hybrid supervised training.

Key files:

- `citrus_project/milestones/02_citrus_integration/README.md`
- `citrus_project/milestones/03_self_supervised_adaptation/README.md`
- `citrus_project/research/baseline_notes.md`

## Stage 3: Plain Citrus Baseline From ImageNet Pretrain

A fair plain Citrus baseline was planned and run from Lite-Mono's ImageNet encoder pretrain rather than KITTI depth-trained weights.

Why this mattered:

The team wanted to distinguish between:

1. Original Lite-Mono pretrained for KITTI-style depth.
2. Plain Lite-Mono trained on Citrus with the standard recipe.
3. The proposed hybrid-supervised improvements.

Important result:

The plain Citrus run showed some useful signal, especially in median-scaled `a1`, but it was not a clean improvement. Raw-scale metrics remained poor, and median-scaled `abs_rel` did not give the desired improvement.

Interpretation:

Plain Citrus training alone was not enough to make the method paper-strong. The project needed a more direct depth-supervision path.

Key files:

- `citrus_project/milestones/04_lightweight_vegetation_improvement/README.md`
- `docs/ORIGINAL_ACTIVE_PROJECT_AGENTS.md` for the full historical context

## Stage 4: Early Phase 2 Boundary-Loss Direction

Milestone 4 originally included two major method ideas:

1. Occlusion masking.
2. Boundary-aware loss.

The user chose to start with boundary awareness first, before occlusion masking, because vegetation boundaries looked like an obvious weakness.

Early concern:

A direct boundary-loss/self-supervised route was risky because the earlier evidence showed that better-looking or lower photometric loss did not necessarily mean better depth. Boundary awareness also needed reliable boundary targets, and LiDAR-derived dense labels do not always outline plants cleanly.

Interpretation:

The idea of improving boundaries was reasonable, but the implementation needed to be anchored by reliable depth supervision and evaluated carefully.

Key files:

- `citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/PHASE_2_BOUNDARY_LOSS.md`
- `citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/phase2_boundary_loss_draft/`

## Stage 5: Hybrid-Supervised Pivot

The key pivot was to use LiDAR during training while keeping RGB-only inference.

Core method:

```text
RGB frames -> Lite-Mono -> predicted depth
Dense LiDAR labels + valid masks -> masked log-L1 depth loss
```

Important settings for the earlier selected hybrid recipe:

1. Pretrained Lite-Mono initialization.
2. Batch size 12.
3. Masked LiDAR `log_l1` supervision.
4. LiDAR loss weight `0.1`.
5. No LiDAR scale alignment.
6. Scale-0 LiDAR supervision.
7. Checkpoint sweep after training instead of assuming final epoch is best.

Earlier strong result, later treated as Branch A/reference:

| Model | Split | Raw abs_rel | Raw a1 | Median abs_rel | Median a1 |
|---|---:|---:|---:|---:|---:|
| Earlier Hybrid / Branch A `weights_13` | val | 0.1716 | 0.8131 | 0.1746 | 0.8160 |
| Earlier Hybrid / Branch A `weights_13` | test | 0.1620 | 0.8149 | 0.1677 | 0.8159 |

Major lesson:

The best checkpoint was `weights_13`, not final `weights_29`. This became a standing protocol: every serious 30-epoch run needs a validation checkpoint sweep and test confirmation.

Key files:

- `citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/HYBRID_SUPERVISED_PLAN.md`
- `citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/HYBRID_SUPERVISED_30EP_RESULT_REPORT.md`
- `citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/hybrid_supervised_draft/`

## Stage 6: Lab 30-Epoch Hybrid Replication

A lab-machine run reproduced the hybrid-supervised direction with a separate prepared dataset/archive.

Important lab-selected result:

| Model | Split | Raw abs_rel | Raw a1 | Median abs_rel | Median a1 |
|---|---:|---:|---:|---:|---:|
| Lab Hybrid `weights_9` | val | 0.1765 | 0.8083 | 0.1832 | 0.8032 |
| Lab Hybrid `weights_9` | test | 0.1648 | 0.8108 | 0.1755 | 0.8051 |
| Lab Hybrid final `weights_29` | test | 0.1767 | 0.8134 | 0.1809 | 0.7979 |

Interpretation:

1. The lab run supported the hybrid-supervised approach.
2. It also reinforced that final epoch is not always best.
3. Earlier local Hybrid `weights_13` remained slightly stronger overall than lab `weights_9`.
4. Same-image comparisons showed that metrics and full-frame visual plausibility can disagree: later checkpoints sometimes looked more plausible in sky/background while validation metrics preferred earlier checkpoints.

Key file:

- `citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/compare_two_checkpoints_raw_and_scaled.py`

## Stage 7: Branch Plan For Better Full-Frame And Boundary Behavior

After the first hybrid success, the next question was whether extra structure terms could improve boundaries and full-frame visual sanity.

The branch plan became:

| Branch | Role |
|---|---|
| A | Earlier selected Hybrid `weights_13` reference |
| B | LiDAR-only continued-training control |
| C | LiDAR + RGB edge-aware smoothness |
| D | LiDAR + teacher/prior only, deferred/risky |
| E | Combined LiDAR + RGB + teacher prior, deferred |
| F | Sky/far and sky-edge prior attempt |
| G | Original Lite-Mono prior on LiDAR-invalid pixels |
| H/H2 | Short low-LR retweaks of G |

Important decision:

Branch D/E teacher ideas were treated cautiously because a weak teacher should not be treated as ground truth. Any teacher/prior loss needed to be weak, normalized, and tested as an ablation.

Key file:

- `citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/rgb_edge_prior_distillation_experiment/PLAN.md`

## Stage 8: Branch B - LiDAR-Only Continued Training

Branch B tested whether the Branch C-style gains could be explained by continued masked LiDAR supervision alone.

Method:

```text
Branch A / Hybrid weights_13
+ masked LiDAR log-L1 depth supervision
+ no photometric loss
+ no RGB edge-aware smoothness
```

Selected result:

| Model | Split | Raw abs_rel | Raw a1 | Median abs_rel | Median a1 |
|---|---:|---:|---:|---:|---:|
| Branch B `weights_24` | val | 0.1530 | 0.8672 | 0.1562 | 0.8640 |
| Branch B `weights_24` | test | 0.1382 | 0.8695 | 0.1436 | 0.8661 |

Lesson:

Masked LiDAR-supervised continuation explains most of the improvement. Branch B became the strongest simple control.

Key file:

- `citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/branch_b/00_BRANCH_B_REPORT.md`

## Stage 9: Branch C - LiDAR Plus RGB Edge-Aware Smoothness

Branch C tested whether generic RGB edge-aware smoothness would improve vegetation boundaries beyond LiDAR-only continuation.

Method:

```text
Branch A / Hybrid weights_13
+ masked LiDAR log-L1 depth supervision
+ RGB edge-aware disparity smoothness
+ no photometric loss
```

Selected result:

| Model | Split | Raw abs_rel | Raw a1 | Median abs_rel | Median a1 |
|---|---:|---:|---:|---:|---:|
| Branch C `weights_24` | val | 0.1531 | 0.8673 | 0.1562 | 0.8641 |
| Branch C `weights_24` | test | 0.1384 | 0.8694 | 0.1437 | 0.8657 |

Lesson:

Branch C was essentially tied with Branch B. The RGB smoothness term was not proven to add meaningful value under this recipe. This was useful negative evidence, not wasted work.

Key file:

- `citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/branch_c/00_BRANCH_C_REPORT.md`

## Stage 10: Branch F - Hand-Coded Sky/Far Prior

Branch F responded to visual complaints that the sky and upper tree regions could look too close or cave-like.

Method:

```text
Branch B weights_24
+ masked LiDAR log-L1 supervision
+ weak RGB-derived sky/far prior
+ weak sky/tree transition prior
```

Result:

| Model | Split | Raw abs_rel | Raw a1 | Median abs_rel | Median a1 |
|---|---:|---:|---:|---:|---:|
| Branch F `weights_1` | val | 0.2391 | 0.8540 | 0.2384 | 0.8443 |
| Branch F `weights_1` | test | 0.2492 | 0.8564 | 0.2446 | 0.8460 |

Lesson:

The idea targeted a real failure, but the implementation was too blunt and damaged metric depth badly. Branch F was rejected.

Key file:

- `citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/branch_f/00_BRANCH_F_REPORT.md`

## Stage 11: Branch G - Original Lite-Mono Prior Outside LiDAR Mask

Branch G tried a safer prior than Branch F. Instead of hand-coding sky/far rules, it used frozen original Lite-Mono as a weak relative-disparity prior only where LiDAR had no valid label.

Method:

```text
Branch B weights_24 student
+ masked LiDAR log-L1 on valid LiDAR pixels
+ weak frozen original Lite-Mono normalized-disparity prior on LiDAR-invalid pixels
```

Selected result:

| Model | Split | Raw abs_rel | Raw a1 | Median abs_rel | Median a1 |
|---|---:|---:|---:|---:|---:|
| Branch G `weights_0` | val | 0.1524 | 0.8658 | 0.1564 | 0.8616 |
| Branch G `weights_0` | test | 0.1375 | 0.8739 | 0.1406 | 0.8721 |
| Branch G final `weights_29` | test | 0.1424 | 0.8751 | 0.1456 | 0.8713 |

Lesson:

Branch G `weights_0` became the current best metric/visual balance. However, the best checkpoint was the earliest one, and longer training drifted. This reinforces the checkpoint-sweep protocol and warns against assuming that more training is always better.

Important caveat:

Branch G is an incremental improvement, not a visual breakthrough. External sanity images show rough object/foreground awareness but not crisp object outlines.

Key file:

- `citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/branch_g/00_BRANCH_G_REPORT.md`

## Stage 12: Branch H/H2 - Short Low-LR Retweaks

Branch H/H2 tested whether Branch G's early improvement could be reproduced more safely with a shorter, lower-learning-rate run.

Methods:

| Branch | Epochs | LR | Original prior weight |
|---|---:|---:|---:|
| H | 3 | 1e-5 | 0.005 |
| H2 | 3 | 1e-5 | 0.0025 |

Selected results:

| Model | Split | Raw abs_rel | Raw a1 | Median abs_rel | Median a1 |
|---|---:|---:|---:|---:|---:|
| Branch H `weights_1` | test | 0.1408 | 0.8733 | 0.1436 | 0.8702 |
| Branch H2 `weights_1` | test | 0.1400 | 0.8739 | 0.1428 | 0.8706 |

Lesson:

H2 improved over H, but neither beat Branch G `weights_0` or Branch B `weights_24`. The original-prior direction is not solved by simply lowering the learning rate and shortening the run.

Key file:

- `citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/branch_h/00_BRANCH_H_REPORT.md`

## Final Current Position

Current best model:

```text
Branch G weights_0
```

Best simple control:

```text
Branch B weights_24
```

Most important negative result:

```text
Branch C did not clearly beat Branch B, so generic RGB smoothness is not proven useful.
```

Main unresolved failure:

```text
Branch G roughly detects object/foreground regions, but it does not outline objects clearly.
```

## What The Paper Can Claim Carefully

Reasonable claims:

1. Citrus Farm exposes a strong domain gap for original Lite-Mono.
2. Pure self-supervised adaptation was unreliable under the tested recipes.
3. Masked LiDAR-supervised hybrid training greatly improves Citrus metric depth while preserving RGB-only inference.
4. Branch B proves that LiDAR-supervised continuation is the main reliable improvement signal.
5. Branch G adds a small improvement by preserving an original-Lite-Mono prior outside LiDAR-valid regions.
6. Checkpoint selection is essential; final epoch is often not best.

Claims to avoid:

1. Do not claim Branch G solves object boundaries.
2. Do not claim RGB edge-aware smoothness was proven beneficial.
3. Do not claim dense LiDAR labels are official Citrus ground truth.
4. Do not claim external-image sanity tests are quantitative evaluation.
5. Do not claim broad agricultural generalization without additional datasets.

## Recommended Next Work

Before another training run, do failure-case analysis:

1. Compare Original, Branch B, Branch C, and Branch G on fixed Citrus and external images.
2. Mark examples where Branch G has good metrics but weak object outlines.
3. Separate failures into sky/far-region, tree-top bleed, trunk/object-boundary, and unsupported LiDAR-mask regions.
4. Only design the next loss or branch after identifying which failure dominates.

Potential future directions:

1. Semantic or segmentation-assisted object/sky masks during training.
2. More targeted edge losses gated by trustworthy object or semantic edges.
3. Better LiDAR confidence masks and interpolation uncertainty handling.
4. More agricultural domains beyond Citrus Farm.
5. A stricter early-stop/checkpoint-selection protocol around Branch G-like recipes.
