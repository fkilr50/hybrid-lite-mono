$ErrorActionPreference = "Stop"
$RepoRoot = "C:\Proj\lite-Mono"
$Python = "C:\Proj\miniforge3\envs\lite-mono\python.exe"
$RunName = "branch_g_original_prior_from_b24_b12_30ep_w005_laptop"
$ModelsDir = "citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/runs/$RunName/models"
$BranchDir = "citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/branch_g/branch_g_original_prior"
$ResultsDir = "$BranchDir/results/$RunName"
$ResweepRoot = "$ResultsDir/checkpoint_sweep_cuda_resweep_0_6"
$ValRoot = "$ResweepRoot/val"
$LogPath = Join-Path $RepoRoot "$ResweepRoot/cuda_resweep_0_6.log"
$Summarizer = "$BranchDir/summarize_checkpoint_sweep.py"

Set-Location $RepoRoot
New-Item -ItemType Directory -Force -Path (Join-Path $RepoRoot $ValRoot) | Out-Null
"Branch G CUDA resweep weights_0..weights_6 started $(Get-Date -Format s)" | Tee-Object -FilePath $LogPath

foreach ($i in 0..6) {
  $Checkpoint = "weights_$i"
  $WeightsFolder = "$ModelsDir/$Checkpoint"
  $OutputDir = "$ValRoot/$Checkpoint"
  "Evaluating val $Checkpoint $(Get-Date -Format s)" | Tee-Object -FilePath $LogPath -Append
  & $Python citrus_project/milestones/01_original_lite_mono_baseline/evaluate_lite_mono_citrus.py `
    --split val `
    --max_samples 0 `
    --run_model `
    --summary_only `
    --progress_interval 100 `
    --weights_folder $WeightsFolder `
    --output_dir $OutputDir 2>&1 | Tee-Object -FilePath $LogPath -Append
}

& $Python $Summarizer `
  --input_root $ValRoot `
  --split val `
  --output_csv "$ResweepRoot/val_cuda_resweep_0_6_summary.csv" `
  --output_json "$ResweepRoot/val_cuda_resweep_0_6_summary.json" 2>&1 | Tee-Object -FilePath $LogPath -Append

"Branch G CUDA resweep weights_0..weights_6 finished $(Get-Date -Format s)" | Tee-Object -FilePath $LogPath -Append
