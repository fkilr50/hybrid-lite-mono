# Branch B Prep

Branch B is the LiDAR-only continued-training control for Branch C.

## Core Difference From Branch C

```text
Branch B: --disparity_smoothness 0
Branch C: --disparity_smoothness 0.001
```

Everything else should match Branch C as closely as possible.

## Local Runtime Estimate

Based on Branch C laptop timing:

```text
2-epoch smoke + eval: about 40-50 minutes
30-epoch full run + eval: about 9-10 hours
checkpoint sweep: extra time after training
```

## Lab Reminder

When the user says they are back at the lab, remind them:

1. Do not train Branch B on a different dataset if it will be used as the official Branch C control.
2. Copy/reproduce the exact same `prepared_training_dataset/` used by Branch C.
3. Verify split counts and `metrics/summary.json` before training.
4. Use the same Hybrid `weights_13` starting checkpoint.
5. Use the same code commit and evaluator.
