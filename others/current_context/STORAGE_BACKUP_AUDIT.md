# Storage and GitHub backup audit ? 2026-10-15

Initial read-only audit; superseded by the completed preservation and cleanup below.

## Verified remote

- Compact research repo: https://github.com/fkilr50/hybrid-lite-mono
- Live main/HEAD: `2c0d1a5a71442c881fed460a8b89c129f6a58c6c`.
- Recursive GitHub tree compared to local files using Git blob SHA-1, allowing CRLF/LF normalization for text.
- 174 local Citrus files match remote; 2 same-path files differ; 2697 files are absent at their current paths (33.19 GiB). Some selected weights are backed up at renamed `model_weights/` paths, so absent-at-path does not mean every byte is unique.
- GitHub contains encoder/depth pairs for Original, A13, B24, C24, G0. Local A13/B24/C24/G0 encoders match the remote blob hashes exactly.
- This workspace instead has origin https://github.com/Lelevinson/lite-Mono.git. Live Milestone-4 tip is `7650e33c910bb4298af5ea948c6ae23fa5add911`; local HEAD is `9683560` and has three commits beyond its cached origin/Milestone-4. It also has uncommitted/untracked work. Neither repo should be treated as a full workspace archive.

## Storage

- Entire citrus_project: approximately 33.20 GiB.
- Marvel/runs: 27.55 GiB, excluded from Git; contains all-epoch checkpoints, optimizer states and training logs.
- dataset_workspace: 5.035 GiB, largely calibration bags and lab-result archives.
- Two largest runs: phase2_boundary_loss_b12_30ep_w005 (6.48 GiB), hybrid_supervised_b12_30ep_logl1_abs_w01_fresh_sched (6.47 GiB).

## Deletion assessment

Do not delete the entire folder expecting full recovery from GitHub. Missing materials include later paper figures, presentation assets, generated comparisons, detailed results, optimizer states and nonselected checkpoints. Keep/archive the paper package and any desired detailed experiment evidence first. Removing selected run artifacts could recover most space while retaining small source/docs/results; no deletion has been authorized or performed.

## Same-path differences

- `citrus_project/milestones/06_paper_package/README.md`
- `citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/branch_b/00_BRANCH_B_REPORT.md`

## Documents/code absent at current remote paths

- `citrus_project/milestones/06_paper_package/generate_paper_figures.py`
- `citrus_project/milestones/06_paper_package/generate_presentation_assets.py`
- `citrus_project/milestones/06_paper_package/HYBRID_PRESENTATION_GUIDE.md`
- `citrus_project/milestones/06_paper_package/figures/fig1_hybrid_training_rgb_only_inference.pdf`
- `citrus_project/milestones/06_paper_package/figures/fig2_original_branchB_branchG_same_frame.pdf`
- `citrus_project/milestones/06_paper_package/figures/README.md`
- `citrus_project/milestones/06_paper_package/presentation_assets/slide_absolute_scale_result.pdf`
- `citrus_project/milestones/06_paper_package/presentation_assets/slide_branch_study_result.pdf`
- `citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/presentation_2026_05_26_hybrid_progress/PRESENTATION_6_MIN_SCRIPT_GOOGLE_DOCS.docx`
- `citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/external_image_sanity_test/images/README.md`
- `citrus_project/dataset_workspace/Calibration/README.pdf`
- `citrus_project/dataset_workspace/Calibration/config/april_grid_24-inch.pdf`
- `citrus_project/dataset_workspace/Calibration/config/checker_board_24-inch.pdf`
- `citrus_project/dataset_workspace/Calibration/results/01-multi-cam-report.pdf`
- `citrus_project/dataset_workspace/Calibration/results/02-imu-cam-report.pdf`
- `citrus_project/dataset_workspace/Calibration/scripts/interactive_recording.py`
- `citrus_project/dataset_workspace/Calibration/scripts/invert_thermal.py`
- `citrus_project/dataset_workspace/Calibration/scripts/kalibr_create_target_pdf.py`
- `citrus_project/dataset_workspace/Calibration/scripts/publish_camera_info.py`

## Completed preservation and cleanup (2026-10-15)

The user authorized committing essential missing files to `others/` in the
compact GitHub repo, followed by local cleanup. Commit `19afac9` uploaded 1,490
files; every archive blob was verified against the live remote before deletion.
`others/CLEANUP_REPORT.md` and JSON inventories record the final state. Removed
32.71 GiB of bulky local artifacts, retaining about 812 MiB of local preservation
files for net recovery of about 31.91 GiB. No tracked files were deleted.
The deletion assessment above describes the earlier pre-preservation state.
