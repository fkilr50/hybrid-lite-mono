# Dataset Workspace

This folder contains the Citrus-specific dataset pipeline and the local Citrus dataset workspace.

## What Lives Here

- download scripts
- extraction scripts
- audit/projection scripts
- densification/build scripts
- local dataset folders such as extracted RGB, extracted LiDAR, calibration, ground truth, and audit outputs

## Path Behavior

The main pipeline scripts in this folder are meant to work relative to this workspace.

- `build_training_dataset.py` and `audit_projection_alignment.py` already resolve defaults from this folder
- the download/extract helper scripts were adjusted so relative paths resolve from this folder too

## Main Pipeline Order

1. `download_citrusfarm_seq_01_lidar.py`
2. `download_citrusfarm_seq_01_rgb_depth.py`
3. `extract_left_rgbd_from_raw.py`
4. `extract_lidar_from_raw.py`
5. `audit_projection_alignment.py`
6. `densify_lidar.py`
7. `build_training_dataset.py`

## Storage cleanup (2026-10-15)

`labresults/`, `Calibration/data/` raw bags/archives, the raw ground-truth bag and
caches were removed after preserving essential extracted evidence in the root
`others/` folder and uploading it to GitHub. Calibration metadata/reports/scripts
and the small ground-truth CSV remain. Earlier extracted/prepared training data
was already removed in June 2026. Training requires rebuilding/restoring data.
