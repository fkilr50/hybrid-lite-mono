# Additional preserved research artifacts

Prepared 2026-10-15 before local storage cleanup. This folder supplements the
compact research repo; original relative paths are retained beneath `others/`.

- `citrus_project/milestones/06_paper_package/`: final figures, captions, scripts,
  presentation guide and slide graphics missing from the original repository.
- Milestone 4 branches, results and external sanity checks: detailed CSV/JSON
  evidence and rendered visual comparisons, including negative experiments.
- `citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/runs/`:
  scalar CSVs, logs/configs and additional documented final/selected inference
  weights. These are archival paths, not a self-contained executable checkout.
- `citrus_project/dataset_workspace/`: lab evidence and calibration metadata.
- Root PDFs and context snapshots preserve the later paper/presentation state.

Files already identical to GitHub contents were not duplicated. Original,
A13, B24, C24 and G0 inference weights remain under the repository's existing
`model_weights/` folder. Selected additional weights are retained here; full
optimizer states and training-only PoseNet weights are intentionally excluded.

`manifest.json` records source paths, byte sizes and verified SHA-256 hashes.
`already_on_github.json` maps unchanged files to existing repository paths.
`omitted_inventory.json` records intentionally omitted raw bags, redundant
archives/checkpoints, transient files, generated depth arrays and bulky
TensorBoard events. Scalar CSV exports and rendered panels are retained.

Full dataset reconstruction is required for retraining. Exact optimizer-state
resume and complete all-epoch checkpoint histories are not preserved.

Eight early smoke TensorBoard event files are also preserved because those runs
had no complete scalar CSV export; large later event histories are omitted.
