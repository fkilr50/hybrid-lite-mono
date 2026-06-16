$ErrorActionPreference = "Stop"

$RepoRoot = "C:\Proj\lite-Mono"
$PackageRoot = "citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/branch_b/lab_transfer_package"
$PackageAbs = Join-Path $RepoRoot $PackageRoot
$Dataset = Join-Path $RepoRoot "citrus_project/dataset_workspace/prepared_training_dataset"
$BranchB = Join-Path $RepoRoot "citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/branch_b"
$BranchBWorkspace = Join-Path $BranchB "branch_b_lidar_only_continued"
$BaseWeights = Join-Path $RepoRoot "citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/runs/hybrid_supervised_b12_30ep_logl1_abs_w01_fresh_sched/models/weights_13"
$ZipPath = Join-Path $RepoRoot "citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/branch_b/branch_b_lab_repro_package.zip"

if (!(Test-Path $Dataset)) { throw "Prepared dataset missing: $Dataset" }
if (!(Test-Path $BranchB)) { throw "Branch B folder missing: $BranchB" }
if (!(Test-Path $BaseWeights)) { throw "Base weights missing: $BaseWeights" }

if (Test-Path $PackageAbs) { Remove-Item -LiteralPath $PackageAbs -Recurse -Force }
New-Item -ItemType Directory -Force -Path $PackageAbs | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $PackageAbs "dataset_metadata") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $PackageAbs "branch_b") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $PackageAbs "base_weights_manifest") | Out-Null

Copy-Item -LiteralPath (Join-Path $Dataset "splits") -Destination (Join-Path $PackageAbs "dataset_metadata\splits") -Recurse
Copy-Item -LiteralPath (Join-Path $Dataset "metrics") -Destination (Join-Path $PackageAbs "dataset_metadata\metrics") -Recurse
Copy-Item -LiteralPath (Join-Path $BranchB "README.md") -Destination (Join-Path $PackageAbs "branch_b\README.md") -Force
Copy-Item -LiteralPath (Join-Path $BranchB "00_BRANCH_B_REPORT.md") -Destination (Join-Path $PackageAbs "branch_b\00_BRANCH_B_REPORT.md") -Force
New-Item -ItemType Directory -Force -Path (Join-Path $PackageAbs "branch_b\branch_b_lidar_only_continued") | Out-Null
$workspacePatterns = @("*.py", "*.ps1", "*.md")
foreach ($pattern in $workspacePatterns) {
  Get-ChildItem -LiteralPath $BranchBWorkspace -File -Filter $pattern |
    Where-Object { $_.Name -notlike "*.pyc" } |
    Copy-Item -Destination (Join-Path $PackageAbs "branch_b\branch_b_lidar_only_continued") -Force
}

$hashRows = @()
$hashTargets = @(
  "citrus_project/dataset_workspace/prepared_training_dataset/splits/train_pairs.txt",
  "citrus_project/dataset_workspace/prepared_training_dataset/splits/val_pairs.txt",
  "citrus_project/dataset_workspace/prepared_training_dataset/splits/test_pairs.txt",
  "citrus_project/dataset_workspace/prepared_training_dataset/metrics/summary.json",
  "citrus_project/dataset_workspace/prepared_training_dataset/metrics/all_samples.csv",
  "citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/runs/hybrid_supervised_b12_30ep_logl1_abs_w01_fresh_sched/models/weights_13/encoder.pth",
  "citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/runs/hybrid_supervised_b12_30ep_logl1_abs_w01_fresh_sched/models/weights_13/depth.pth"
)
foreach ($rel in $hashTargets) {
  $abs = Join-Path $RepoRoot $rel
  if (Test-Path $abs) {
    $h = Get-FileHash -LiteralPath $abs -Algorithm SHA256
    $item = Get-Item -LiteralPath $abs
    $hashRows += [PSCustomObject]@{ relative_path = $rel; bytes = $item.Length; sha256 = $h.Hash }
  }
}
$hashRows | Export-Csv -Path (Join-Path $PackageAbs "dataset_metadata\fairness_hashes.csv") -NoTypeInformation

$denseCount = (Get-ChildItem -Path (Join-Path $Dataset "dense_lidar_npz") -Filter *.npz -File -Recurse | Measure-Object).Count
$maskCount = (Get-ChildItem -Path (Join-Path $Dataset "dense_lidar_valid_mask_npz") -Filter *.npz -File -Recurse | Measure-Object).Count
$trainCount = (Get-Content -Path (Join-Path $Dataset "splits\train_pairs.txt") | Measure-Object).Count
$valCount = (Get-Content -Path (Join-Path $Dataset "splits\val_pairs.txt") | Measure-Object).Count
$testCount = (Get-Content -Path (Join-Path $Dataset "splits\test_pairs.txt") | Measure-Object).Count
$datasetBytes = (Get-ChildItem -Path $Dataset -File -Recurse | Measure-Object -Property Length -Sum).Sum

$manifest = @"
# Branch B Lab Reproducibility Package

Created from: $RepoRoot

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
dense_lidar_npz count: $denseCount
dense_lidar_valid_mask_npz count: $maskCount
train pairs: $trainCount
val pairs: $valCount
test pairs: $testCount
prepared dataset bytes: $datasetBytes
---

## Required Starting Checkpoint

---
citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/runs/hybrid_supervised_b12_30ep_logl1_abs_w01_fresh_sched/models/weights_13/
---

Must contain `encoder.pth` and `depth.pth`.

## Verification

On the lab computer, compare `dataset_metadata/fairness_hashes.csv` against the corresponding files before training.

## Branch B Fairness Rule

Branch B should match Branch C exactly except:

---
Branch B: --disparity_smoothness 0
Branch C: --disparity_smoothness 0.001
---
"@
Set-Content -LiteralPath (Join-Path $PackageAbs "README.md") -Value $manifest

if (Test-Path $ZipPath) { Remove-Item -LiteralPath $ZipPath -Force }
Compress-Archive -Path (Join-Path $PackageAbs "*") -DestinationPath $ZipPath
Write-Output "Wrote $ZipPath"
Write-Output "Note: full prepared_training_dataset is not included; copy it separately for a fair lab run."
