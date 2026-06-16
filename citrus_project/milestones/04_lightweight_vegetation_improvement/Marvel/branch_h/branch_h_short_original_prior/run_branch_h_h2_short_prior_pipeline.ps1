$ErrorActionPreference = "Stop"

$RepoRoot = "C:\Proj\lite-Mono"
$Python = "C:\Proj\miniforge3\envs\lite-mono\python.exe"
$LogDir = "citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/runs"
$BranchDir = "citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/branch_h/branch_h_short_original_prior"
$ResultsBase = "$BranchDir/results"
$TrainScript = "$BranchDir/train_hybrid_supervised.py"
$Summarizer = "$BranchDir/summarize_checkpoint_sweep.py"
$BaseWeights = "citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/runs/branch_b_lidar_only_from_w13_b12_30ep_s001_laptop/models/weights_24"
$TeacherWeights = "weights/lite-mono"
$BranchBWeights = $BaseWeights
$BranchGBestWeights = "citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/runs/branch_g_original_prior_from_b24_b12_30ep_w005_laptop/models/weights_0"
$OverallLog = Join-Path $RepoRoot "$ResultsBase/branch_h_h2_pipeline.log"

Set-Location $RepoRoot
New-Item -ItemType Directory -Force -Path (Join-Path $RepoRoot $ResultsBase) | Out-Null
"Branch H/H2 pipeline started $(Get-Date -Format s)" | Tee-Object -FilePath $OverallLog

if (-not (Test-Path $Python)) { throw "Python env not found: $Python" }
if (-not (Test-Path (Join-Path $RepoRoot $TrainScript))) { throw "Train script not found: $TrainScript" }
if (-not (Test-Path (Join-Path $RepoRoot $BaseWeights))) { throw "Base weights not found: $BaseWeights" }
if (-not (Test-Path (Join-Path $RepoRoot $TeacherWeights))) { throw "Original teacher weights not found: $TeacherWeights" }
if (-not (Test-Path (Join-Path $RepoRoot "citrus_project/dataset_workspace/prepared_training_dataset/splits/train_pairs.txt"))) { throw "Prepared dataset split missing" }

$Configs = @(
  @{ Label = "H"; RunName = "branch_h_short_prior_from_b24_b12_3ep_lr1e5_w005_laptop"; PriorWeight = "0.005" },
  @{ Label = "H2"; RunName = "branch_h2_short_prior_from_b24_b12_3ep_lr1e5_w0025_laptop"; PriorWeight = "0.0025" }
)

foreach ($Config in $Configs) {
  $Label = $Config.Label
  $RunName = $Config.RunName
  $PriorWeight = $Config.PriorWeight
  $RunDir = Join-Path $RepoRoot (Join-Path $LogDir $RunName)
  $ResultsDir = "$ResultsBase/$RunName"
  $TrainLog = Join-Path $RunDir "console.log"
  $PostprocessLog = Join-Path $RunDir "postprocess.log"
  $ModelsDir = "$LogDir/$RunName/models"
  $FinalWeights = "$ModelsDir/weights_2"
  $SweepRoot = "$ResultsDir/checkpoint_sweep"
  $ValRoot = "$SweepRoot/val"
  $TestRoot = "$SweepRoot/test"

  "[$Label] Starting run $RunName $(Get-Date -Format s)" | Tee-Object -FilePath $OverallLog -Append
  New-Item -ItemType Directory -Force -Path $RunDir | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $RepoRoot $ResultsDir) | Out-Null

  if (-not (Test-Path (Join-Path $RepoRoot $FinalWeights))) {
    & $Python -u $TrainScript `
      --dataset citrus `
      --split citrus_prepared `
      --data_path citrus_project/dataset_workspace `
      --model lite-mono `
      --model_name $RunName `
      --log_dir $LogDir `
      --load_weights_folder $BaseWeights `
      --models_to_load encoder depth `
      --skip_optimizer_load `
      --batch_size 12 `
      --num_epochs 3 `
      --lr 0.00001 0.0000005 4 0.00001 0.000001 4 `
      --weight_decay 0.01 `
      --drop_path 0.2 `
      --height 192 `
      --width 640 `
      --num_workers 0 `
      --log_frequency 50 `
      --save_frequency 1 `
      --save_step_frequency 0 `
      --seed 0 `
      --disable_photometric_loss `
      --disparity_smoothness 0 `
      --boundary_loss_weight 0 `
      --lidar_loss_weight 0.1 `
      --lidar_loss_type log_l1 `
      --lidar_scale_align none `
      --lidar_loss_scales 0 `
      --lidar_loss_min_valid_pixels 500 `
      --original_prior_weight $PriorWeight `
      --original_prior_weights_folder $TeacherWeights `
      --original_prior_scales 0 `
      --original_prior_min_valid_pixels 500 `
      --original_prior_require_lidar_invalid 2>&1 | Tee-Object -FilePath $TrainLog
  } else {
    "[$Label] Training skipped because final checkpoint already exists: $FinalWeights" | Tee-Object -FilePath $OverallLog -Append
  }

  if (-not (Test-Path (Join-Path $RepoRoot $FinalWeights))) {
    throw "[$Label] Expected final checkpoint was not found: $FinalWeights"
  }

  & $Python citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/plot_training_losses.py `
    --run_dir "$LogDir/$RunName" `
    --output_dir "$ResultsDir/loss_plots" 2>&1 | Tee-Object -FilePath $PostprocessLog

  New-Item -ItemType Directory -Force -Path (Join-Path $RepoRoot $ValRoot) | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $RepoRoot $TestRoot) | Out-Null

  foreach ($i in 0..2) {
    $Checkpoint = "weights_$i"
    $WeightsFolder = "$ModelsDir/$Checkpoint"
    foreach ($Split in @("val", "test")) {
      $OutRoot = if ($Split -eq "val") { $ValRoot } else { $TestRoot }
      $OutputDir = "$OutRoot/$Checkpoint"
      $SummaryName = if ($Split -eq "val") { "val_lite-mono_full_summary.json" } else { "test_lite-mono_full_summary.json" }
      if (-not (Test-Path (Join-Path $RepoRoot "$OutputDir/$SummaryName"))) {
        "[$Label] Evaluating $Split $Checkpoint $(Get-Date -Format s)" | Tee-Object -FilePath $PostprocessLog -Append
        & $Python citrus_project/milestones/01_original_lite_mono_baseline/evaluate_lite_mono_citrus.py `
          --split $Split `
          --max_samples 0 `
          --run_model `
          --summary_only `
          --progress_interval 100 `
          --weights_folder $WeightsFolder `
          --output_dir $OutputDir 2>&1 | Tee-Object -FilePath $PostprocessLog -Append
      }
    }
  }

  & $Python $Summarizer `
    --input_root $ValRoot `
    --split val `
    --output_csv "$SweepRoot/val_sweep_summary.csv" `
    --output_json "$SweepRoot/val_sweep_summary.json" 2>&1 | Tee-Object -FilePath $PostprocessLog -Append
  & $Python $Summarizer `
    --input_root $TestRoot `
    --split test `
    --output_csv "$SweepRoot/test_sweep_summary.csv" `
    --output_json "$SweepRoot/test_sweep_summary.json" 2>&1 | Tee-Object -FilePath $PostprocessLog -Append

  $ValRows = Import-Csv (Join-Path $RepoRoot "$SweepRoot/val_sweep_summary.csv")
  $BestRaw = $ValRows | Sort-Object { [double]$_.raw_abs_rel }, { -[double]$_.raw_a1 } | Select-Object -First 1
  $BestCheckpoint = $BestRaw.checkpoint
  $BestWeights = "$ModelsDir/$BestCheckpoint"
  "[$Label] Best val raw checkpoint: $BestCheckpoint raw_abs_rel=$($BestRaw.raw_abs_rel) raw_a1=$($BestRaw.raw_a1)" | Tee-Object -FilePath $OverallLog -Append

  foreach ($Split in @("val", "test")) {
    $SelectionDir = if ($Split -eq "val") { "$ValRoot/$BestCheckpoint" } else { "$TestRoot/$BestCheckpoint" }
    & $Python citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/compare_two_checkpoints_raw_and_scaled.py `
      --split $Split `
      --selection_results_dir $SelectionDir `
      --weights_a $BestWeights `
      --weights_b $BranchBWeights `
      --name_a "$Label $BestCheckpoint" `
      --name_b "Branch B weights_24" `
      --output_dir "$SweepRoot/visuals/${Label}_${BestCheckpoint}_vs_branch_b_w24_$Split" `
      --metric median_scaled_a1 2>&1 | Tee-Object -FilePath $PostprocessLog -Append

    & $Python citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/compare_two_checkpoints_raw_and_scaled.py `
      --split $Split `
      --selection_results_dir $SelectionDir `
      --weights_a $BestWeights `
      --weights_b $BranchGBestWeights `
      --name_a "$Label $BestCheckpoint" `
      --name_b "Branch G weights_0" `
      --output_dir "$SweepRoot/visuals/${Label}_${BestCheckpoint}_vs_branch_g_w0_$Split" `
      --metric median_scaled_a1 2>&1 | Tee-Object -FilePath $PostprocessLog -Append
  }

  "[$Label] Completed run $RunName $(Get-Date -Format s)" | Tee-Object -FilePath $OverallLog -Append
}

"Branch H/H2 pipeline finished $(Get-Date -Format s)" | Tee-Object -FilePath $OverallLog -Append
