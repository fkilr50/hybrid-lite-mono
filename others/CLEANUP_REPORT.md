# Preservation and cleanup completed - 2026-10-15

Essential missing artifacts were committed to `others/` in
https://github.com/fkilr50/hybrid-lite-mono before local cleanup.
Initial archive commit: `19afac97eb22e63a842ca5780c423f7fd5d64b6f`.
All 1,490 uploaded files were verified against GitHub blob hashes. Local preserved
copies were also checked with SHA-256 before deleting source artifacts.

| Storage | GiB |
|---|---:|
| Original citrus_project | 33.196 |
| Remaining citrus_project | 0.490 |
| Removed original artifacts | 32.706 |
| Retained local others bundle | 0.793 |
| Net reclaimed, after retaining others | 31.913 |

No Git-tracked files were deleted. Source/docs, paper outputs, calibration metadata
and remaining branch results/visuals stay in the original workspace. The compact
repo's existing files and selected `model_weights/` were left intact.

Deleted bulk: Marvel training runs, lab-result raw archives and redundant epoch
checkpoints, Calibration/data raw bags, ground-truth raw bag, caches, temporary
files, generated external depth arrays and redundant packed outputs. Every file
removed was either preserved here, already identical to GitHub, or classified as
intentionally omitted in the inventory. No files outside citrus_project were
removed except temporary tooling created for this operation.

Preserved scalar CSV/config/log evidence and additional documented selected/final
inference weights. Eight early TensorBoard event files lacking complete scalar CSV
exports were retained. Full optimizer states, training-only PoseNet weights and
complete all-epoch histories were intentionally discarded; exact resume is no
longer available. Full datasets need rebuilding/restoring for retraining.

Historical original paths are preserved inside `others/citrus_project/`, but scripts
are not automatically rewired to those archived paths. Existing Original/A13/B24/
C24/G0 inference weights are at GitHub `model_weights/` instead of duplicated here.

- `manifest.json`: per-file source/destination/size/SHA-256 of preserved source files.
- `already_on_github.json`: unchanged content mapped to existing remote paths.
- `omitted_inventory.json`: intentionally discarded bulk artifact inventory.
- `remote_verification.json`: initial upload verification commit and file count.
- `cleanup_plan.json`: bounded deletion paths; no tracked file deletions.
- `cleanup_result.json`: before/after storage and recovery accounting.
- `current_context/`: source-of-truth and folder-doorway updates after cleanup.

The local preservation copy and remaining original figures intentionally coexist;
GitHub now provides the off-device preservation copy. Git publishing temporary
objects were removed after the final verification and are excluded from totals.
