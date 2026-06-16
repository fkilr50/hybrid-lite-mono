# Branch B - LiDAR-Only Continued Training Control

Start here:

- `00_BRANCH_B_REPORT.md` - main Branch B purpose, fairness conditions, and run plan.
- `branch_b_lidar_only_continued/` - copied training code and scripts for the LiDAR-only control.

Branch B is the fair control for Branch C. It keeps the same starting checkpoint and LiDAR supervision recipe, but disables RGB edge-aware smoothness.
