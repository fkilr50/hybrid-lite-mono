# Branch B Report - LiDAR-Only Continued Training Control

## Purpose

Branch B is the required fair control for Branch C.

Branch C looked promising because it used masked LiDAR supervision plus RGB edge-aware smoothness. Branch B removes the RGB smoothness term while keeping the rest of the recipe matched. This lets us test whether Branch C improved because of RGB edge-aware smoothness, or merely because of more LiDAR-supervised training from the same starting checkpoint.

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

## Current Status

Prepared locally on 2026-06-10. Training has not been run yet.

## Required Fairness Conditions

Branch B must match Branch C on:

1. Starting checkpoint: earlier Hybrid `weights_13`.
2. Dataset workspace: `citrus_project/dataset_workspace/prepared_training_dataset/`.
3. Splits: same `train_pairs.txt`, `val_pairs.txt`, and `test_pairs.txt`.
4. Dense LiDAR labels and valid masks.
5. Batch size, epoch count, optimizer, scheduler, seed, image size, and evaluator.
6. Checkpoint sweep and test confirmation procedure.

Only intended difference:

```text
Branch B: --disparity_smoothness 0
Branch C: --disparity_smoothness 0.001
```

## Planned Runs

1. Two-epoch smoke/evaluation:
   - `run_branch_b_2ep_smoke_eval_laptop.ps1`
2. Full 30-epoch run/evaluation if smoke is stable:
   - `run_branch_b_30ep_eval_laptop.ps1`
3. Checkpoint sweep after the 30-epoch run:
   - `run_branch_b_checkpoint_sweep_laptop.ps1`

## Expected Interpretation

If Branch C clearly beats Branch B under the same dataset and training budget, RGB edge-aware smoothness earns its place.

If Branch B matches or beats Branch C, then Branch C's improvement probably came from extra LiDAR-supervised training, checkpoint selection, or noise rather than the RGB smoothness term.

## Reminder For Lab Work

When the user says they are back at the lab, remind them to make Branch B fair by copying or reproducing the exact same local prepared dataset artifacts and starting checkpoint before training there.
