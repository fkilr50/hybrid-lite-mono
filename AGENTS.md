# AGENTS.md

## Purpose

This repository is the compact Lite-Mono Citrus research repo for the Lite-Mono + Citrus Farm monocular depth project. It exists so teammates and their AI assistants can scan the essential context, methods, branch experiments, and paper-facing conclusions without cloning the full local dataset/checkpoint workspace.

This repo is evidence/context/code focused. It is not the complete dataset or checkpoint workspace.

## Mandatory Read Order

1. Read this file first.
2. Read `docs/TRAINING_JOURNEY.md` for the chronological story of the work.
3. Read `citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/00_BRANCH_EXPERIMENT_SUMMARY.md`.
4. Read the visible branch reports under `citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/branch_*/00_BRANCH_*_REPORT.md`.
5. Use `citrus_project/research/` notes for dataset, baseline, paper shortlist, and advisor context.
6. Use `docs/ORIGINAL_ACTIVE_PROJECT_AGENTS.md` for the longer source-of-truth context from the original active repo at the time this repo was created.

## Project Goal

Publish an improved Lite-Mono-style monocular depth estimation method for vegetation-dense agricultural environments, using Citrus Farm as the current benchmark/domain and a lightweight RGB-only pest-killing robot perception stack as deployment motivation.

The intended runtime model remains monocular RGB-only. LiDAR is used during dataset preparation, training supervision, and evaluation labels, not as an inference input.

## Repo Snapshot

Created from local source project: `C:/Proj/lite-Mono`

Current repo location: `C:/Proj/lite-mono-citrus`

GitHub remote: `https://github.com/fkilr50/hybrid-lite-mono`

This repo intentionally excludes datasets, full run folders, generated image dumps, optimizer states, and bulk checkpoints. It now includes selected inference checkpoints under `model_weights/` for original Lite-Mono, Branch A, Branch B, Branch C, and Branch G so teammates can run comparisons without obtaining every training artifact.

## Current Best Result

Current best internal model selection:

- Branch G `weights_0`
- Method: Branch B LiDAR-only continued training plus a weak original Lite-Mono prior on LiDAR-invalid regions
- Validation raw abs_rel/a1: `0.1524 / 0.8658`
- Test raw abs_rel/a1: `0.1375 / 0.8739`
- Test median abs_rel/a1: `0.1406 / 0.8721`

Important caveat:

Branch G is only a small metric improvement over Branch B/C. External visual sanity tests suggest it roughly detects foreground/object regions but does not produce crisp object outlines. Treat it as the best current balance, not a solved boundary method.

## Branch Labels

- Branch A: earlier selected hybrid supervised model, especially `weights_13`
- Branch B: LiDAR-only continued training control from Branch A
- Branch C: LiDAR plus RGB edge-aware smoothness
- Branch F: full-frame sky/tree sanity prior, rejected as too damaging
- Branch G: weak original Lite-Mono prior on LiDAR-invalid pixels, current best balance
- Branch H/H2: shorter/lower-weight original-prior variants, did not beat G

## Core Story

1. Original Lite-Mono is lightweight and works as the baseline, but it has a strong Citrus domain gap.
2. Standard self-supervised Citrus adaptation was not enough. Photometric/reprojection loss could improve while Citrus depth metrics and structure got worse.
3. The project pivoted to hybrid supervised training: use RGB as model input, but use projected/densified LiDAR depth and valid masks as training/evaluation supervision.
4. The LiDAR-supervised approach significantly improved Citrus raw-scale and median-scaled metrics compared with the original baseline and plain Citrus self-supervised style runs.
5. Several branch experiments tested whether extra boundary/full-frame priors helped.
6. Branch G is the current best internal balance, but it is not a dramatic visual breakthrough.

## Current Metric Comparison Snapshot

Approximate key results from the branch reports:

| Model | Split | Raw abs_rel | Raw a1 | Median abs_rel | Median a1 | Verdict |
|---|---:|---:|---:|---:|---:|---|
| Original Lite-Mono | test | 0.7273 | 0.0149 | 0.3836 | 0.4989 | baseline domain gap |
| Branch A / Hybrid `weights_13` | test | 0.1620 | 0.8149 | 0.1677 | 0.8159 | strong first hybrid result |
| Branch B `weights_24` | test | 0.1382 | 0.8695 | 0.1436 | 0.8661 | strong LiDAR-only control |
| Branch C `weights_24` | test | 0.1384 | 0.8694 | 0.1437 | 0.8657 | RGB smoothness did not clearly beat B |
| Branch F `weights_1` | test | 0.2492 | 0.8564 | 0.2446 | 0.8460 | rejected |
| Branch G `weights_0` | test | 0.1375 | 0.8739 | 0.1406 | 0.8721 | current best balance |
| Branch H2 `weights_1` | test | 0.1400 | 0.8739 | 0.1428 | 0.8706 | close but below G |

## Important Interpretation

Branch B and C were almost tied. This suggests most of the gain came from masked LiDAR-supervised continuation, not from the RGB edge-aware smoothness term as implemented.

Branch G slightly improved the best metric balance by adding a weak prior from original Lite-Mono on LiDAR-invalid pixels. This is conceptually useful because LiDAR-valid metrics ignore many full-frame areas such as sky and unsupported background. Still, the visual improvement is limited.

## Main Failure Case

External sanity images show that Branch G can identify rough foreground/object regions, but the maps are broad and blob-like. It does not outline object boundaries clearly. This matters for a robot setting because a depth method that only gets rough regions may still be weak near leaves, tree tops, sky boundaries, and object edges.

## Paper-Writing Guidance

Be conservative.

Do claim:

- Citrus vegetation scenes expose a strong domain gap for original Lite-Mono.
- Pure self-supervised adaptation was unreliable in this project because photometric improvement did not reliably mean depth improvement.
- Masked LiDAR-supervised hybrid training greatly improved metric depth on LiDAR-valid regions while preserving RGB-only inference.
- Checkpoint selection matters: final epoch is often not the best checkpoint.
- Branch G is the current best internal balance by the chosen metrics, but its visual improvement is modest.

Do not claim:

- The model solves object-boundary sharpness.
- Dense LiDAR labels are official Citrus Farm ground truth.
- External image sanity tests are quantitative benchmarks.
- Branch G generalizes broadly beyond Citrus without more datasets.

## Suggested Paper Sections

1. Introduction: lightweight agricultural robotics and vegetation depth challenge
2. Related Work: monocular depth, self-supervised depth, agricultural perception, LiDAR-supervised monocular training
3. Dataset and Label Pipeline: Citrus Farm, RGB-LiDAR pairing, projection, densification, valid masks
4. Baselines: original Lite-Mono, plain Citrus adaptation, earlier self-supervised failure
5. Proposed Hybrid Training: masked LiDAR log-L1 supervision, RGB-only inference, checkpoint selection
6. Branch Experiments: B/C/F/G/H ablations
7. Results: metrics table, selected visual comparisons, external sanity caveat
8. Discussion: metric/visual mismatch, LiDAR-valid mask limitations, boundary failure
9. Conclusion and Future Work: stronger boundary labels, semantic/sky masks, more domains

## What To Ask For If More Evidence Is Needed

Ask the original workspace owner for:

- selected visual PNG panels for Branch G versus Branch B/C
- checkpoint sweep CSVs
- TensorBoard scalar plots
- additional checkpoints beyond the selected `model_weights/` folders, if a new comparison requires them
- external sanity image panels

Do not request the full dataset unless retraining is needed.

## Artifact Policy

Large artifacts are mostly not in this repo. Selected inference `.pth` files under `model_weights/` are intentionally included. Do not add the following unless explicitly requested and reviewed:

- additional `.pth`, `.pt`, `.ckpt`, `.npz`, `.npy`, `.bag` files outside `model_weights/`
- extracted dataset folders
- checkpoint folders
- generated result/image-output folders
- TensorBoard event files
- cache folders

If a paper needs images, add a small curated `figures/` folder later, not the full visual-output tree.




