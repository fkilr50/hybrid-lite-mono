# Branch B Lab Reproducibility Package

Created from: C:\Proj\lite-Mono

This package is not the full dataset. It contains code, split/metric metadata, and hashes for verifying a fair lab transfer.

## Exact Full Dataset Folder Needed For Fair Training

Copy or reproduce this full folder on the lab computer:

---
citrus_project/dataset_workspace/prepared_training_dataset/
---

Required subfolders:

---
splits/
metrics/
dense_lidar_npz/
dense_lidar_valid_mask_npz/
---

Local counts:

---
dense_lidar_npz count: 5282
dense_lidar_valid_mask_npz count: 5282
train pairs: 4311
val pairs: 564
test pairs: 407
prepared dataset bytes: 6186169139
---

## Required Starting Checkpoint

---
citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/runs/hybrid_supervised_b12_30ep_logl1_abs_w01_fresh_sched/models/weights_13/
---

Must contain encoder.pth and depth.pth.

## Verification

On the lab computer, compare dataset_metadata/fairness_hashes.csv against the corresponding files before training.

## Branch B Fairness Rule

Branch B should match Branch C exactly except:

---
Branch B: --disparity_smoothness 0
Branch C: --disparity_smoothness 0.001
---
