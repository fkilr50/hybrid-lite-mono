$ErrorActionPreference = "Stop"

$RepoRoot = "C:\Proj\lite-Mono"
$Python = "C:\Proj\miniforge3\envs\lite-mono\python.exe"
$RunName = "branch_f_full_frame_sanity_from_b24_b12_30ep_sky001_edge0005_laptop"
$LogDir = "citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/runs"
$BranchDir = "citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/branch_f/branch_f_full_frame_sanity"
$RunDir = Join-Path $RepoRoot (Join-Path $LogDir $RunName)
$ResultsDir = "$BranchDir/results/$RunName"
$VisualDir = "$ResultsDir/visuals"
$TrainLog = Join-Path $RunDir "console.log"
$PostprocessLog = Join-Path $RunDir "postprocess.log"
$TrainScript = "$BranchDir/train_hybrid_supervised.py"
$BaseWeights = "citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/runs/branch_b_lidar_only_from_w13_b12_30ep_s001_laptop/models/weights_24"
$WeightsFolder = "$LogDir/$RunName/models/weights_29"

Set-Location $RepoRoot

if (-not (Test-Path $Python)) { throw "Python env not found: $Python" }
if (-not (Test-Path (Join-Path $RepoRoot $TrainScript))) { throw "Train script not found: $TrainScript" }
if (-not (Test-Path (Join-Path $RepoRoot $BaseWeights))) { throw "Base weights not found: $BaseWeights" }
if (-not (Test-Path (Join-Path $RepoRoot "citrus_project/dataset_workspace/prepared_training_dataset/splits/train_pairs.txt"))) { throw "Prepared dataset split missing" }

New-Item -ItemType Directory -Force -Path $RunDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $RepoRoot $ResultsDir) | Out-Null

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
  --num_epochs 30 `
  --lr 0.00005 0.0000025 31 0.00005 0.000005 31 `
  --weight_decay 0.01 `
  --drop_path 0.2 `
  --height 192 `
  --width 640 `
  --num_workers 0 `
  --log_frequency 100 `
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
  --sky_far_prior_weight 0.01 `
  --sky_far_prior_min_depth 40 `
  --sky_prior_require_lidar_invalid `
  --sky_edge_contrast_weight 0.005 `
  --sky_edge_contrast_margin 0.015 `
  --sky_prior_min_pixels 200 `
  --sky_edge_min_pixels 50 2>&1 | Tee-Object -FilePath $TrainLog

if (-not (Test-Path (Join-Path $RepoRoot $WeightsFolder))) {
  throw "Expected 30-epoch checkpoint was not found: $WeightsFolder"
}

& $Python citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/plot_training_losses.py `
  --run_dir "$LogDir/$RunName" `
  --output_dir "$ResultsDir/loss_plots" 2>&1 | Tee-Object -FilePath $PostprocessLog

& $Python citrus_project/milestones/01_original_lite_mono_baseline/evaluate_lite_mono_citrus.py `
  --split val `
  --max_samples 0 `
  --run_model `
  --summary_only `
  --progress_interval 50 `
  --weights_folder $WeightsFolder `
  --output_dir $ResultsDir 2>&1 | Tee-Object -FilePath $PostprocessLog -Append

& $Python citrus_project/milestones/01_original_lite_mono_baseline/evaluate_lite_mono_citrus.py `
  --split test `
  --max_samples 0 `
  --run_model `
  --summary_only `
  --progress_interval 50 `
  --weights_folder $WeightsFolder `
  --output_dir $ResultsDir 2>&1 | Tee-Object -FilePath $PostprocessLog -Append

& $Python citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/compare_phase2_visuals.py `
  --split val `
  --phase2_results_dir $ResultsDir `
  --baseline_weights $BaseWeights `
  --phase2_weights $WeightsFolder `
  --output_dir "$VisualDir/branch_b_w24_vs_branch_f_val" `
  --baseline_name "Branch B w24" `
  --phase2_name "Branch F 30ep" 2>&1 | Tee-Object -FilePath $PostprocessLog -Append

& $Python citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/compare_phase2_visuals.py `
  --split test `
  --phase2_results_dir $ResultsDir `
  --baseline_weights $BaseWeights `
  --phase2_weights $WeightsFolder `
  --output_dir "$VisualDir/branch_b_w24_vs_branch_f_test" `
  --baseline_name "Branch B w24" `
  --phase2_name "Branch F 30ep" 2>&1 | Tee-Object -FilePath $PostprocessLog -Append
