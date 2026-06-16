$ErrorActionPreference = "Continue"

$RepoRoot = "C:\Proj\lite-Mono"
$BranchRoot = "C:\Proj\lite-Mono\citrus_project\milestones\04_lightweight_vegetation_improvement\Marvel\branch_g"
$BranchDir = Join-Path $BranchRoot "branch_g_original_prior"
$RunName = "branch_g_original_prior_from_b24_b12_30ep_w005_laptop"
$RunDir = Join-Path $RepoRoot "citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/runs/$RunName"
$ResultsDir = Join-Path $BranchDir "results/$RunName"
$WatcherLog = Join-Path $ResultsDir "overnight_watcher.log"
$SweepScript = Join-Path $BranchDir "run_branch_g_checkpoint_sweep_laptop.ps1"
$Report = Join-Path $BranchRoot "00_BRANCH_G_OVERNIGHT_AUTO_REPORT.md"
$MainReport = Join-Path $BranchRoot "00_BRANCH_G_REPORT.md"

New-Item -ItemType Directory -Force -Path $ResultsDir | Out-Null
"Branch G overnight watcher started $(Get-Date -Format s)" | Tee-Object -FilePath $WatcherLog

$PidPath = Join-Path $RunDir "process.pid"
if (-not (Test-Path $PidPath)) {
  "Missing process pid: $PidPath" | Tee-Object -FilePath $WatcherLog -Append
  exit 1
}

$TrainPid = [int](Get-Content $PidPath)
"Waiting for 30ep process PID $TrainPid" | Tee-Object -FilePath $WatcherLog -Append
try {
  Wait-Process -Id $TrainPid -ErrorAction Stop
} catch {
  "Wait-Process warning: $($_.Exception.Message)" | Tee-Object -FilePath $WatcherLog -Append
}
"30ep wrapper finished or disappeared $(Get-Date -Format s)" | Tee-Object -FilePath $WatcherLog -Append

$Weights29 = Join-Path $RunDir "models/weights_29/encoder.pth"
if (Test-Path $Weights29) {
  "weights_29 exists; starting checkpoint sweep" | Tee-Object -FilePath $WatcherLog -Append
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $SweepScript 2>&1 | Tee-Object -FilePath $WatcherLog -Append
} else {
  "weights_29 missing; skipping checkpoint sweep" | Tee-Object -FilePath $WatcherLog -Append
}

function Read-Metrics($Path) {
  if (-not (Test-Path $Path)) { return $null }
  $j = Get-Content $Path -Raw | ConvertFrom-Json
  [pscustomobject]@{
    Samples = $j.samples_with_metrics
    RawAbsRel = [double]$j.mean_raw_metrics.abs_rel
    RawA1 = [double]$j.mean_raw_metrics.a1
    MedianAbsRel = [double]$j.mean_median_scaled_metrics.abs_rel
    MedianA1 = [double]$j.mean_median_scaled_metrics.a1
  }
}

$Val = Read-Metrics (Join-Path $ResultsDir "val_lite-mono_full_summary.json")
$Test = Read-Metrics (Join-Path $ResultsDir "test_lite-mono_full_summary.json")
$SweepCsv = Join-Path $ResultsDir "checkpoint_sweep/val_sweep_summary.csv"
$ConfirmCsv = Join-Path $ResultsDir "checkpoint_sweep/test_confirm_summary.csv"
$BestValRaw = $null
$BestTestRaw = $null
if (Test-Path $SweepCsv) {
  $BestValRaw = Import-Csv $SweepCsv | Sort-Object { [double]$_.raw_abs_rel }, { -[double]$_.raw_a1 } | Select-Object -First 1
}
if (Test-Path $ConfirmCsv) {
  $BestTestRaw = Import-Csv $ConfirmCsv | Sort-Object { [double]$_.raw_abs_rel }, { -[double]$_.raw_a1 } | Select-Object -First 1
}

$lines = @()
$lines += "# Branch G Overnight Auto Report"
$lines += ""
$lines += "Generated: $(Get-Date -Format s)"
$lines += ""
$lines += "## Run"
$lines += ""
$lines += "- Run name: $RunName"
$lines += "- Base: Branch B 'weights_24'"
$lines += "- Teacher prior: frozen original Lite-Mono 'weights/lite-mono'"
$lines += "- Prior weight: '0.005', LiDAR-invalid pixels only"
$lines += ""
$lines += "## Final Weights_29 Metrics"
$lines += ""
$lines += "| Split | Samples | Raw abs_rel | Raw a1 | Median abs_rel | Median a1 |"
$lines += "|---|---:|---:|---:|---:|---:|"
if ($Val) { $lines += ("| val | {0} | {1:N4} | {2:N4} | {3:N4} | {4:N4} |" -f $Val.Samples,$Val.RawAbsRel,$Val.RawA1,$Val.MedianAbsRel,$Val.MedianA1) } else { $lines += "| val | missing | missing | missing | missing | missing |" }
if ($Test) { $lines += ("| test | {0} | {1:N4} | {2:N4} | {3:N4} | {4:N4} |" -f $Test.Samples,$Test.RawAbsRel,$Test.RawA1,$Test.MedianAbsRel,$Test.MedianA1) } else { $lines += "| test | missing | missing | missing | missing | missing |" }
$lines += ""
$lines += "## Checkpoint Sweep"
$lines += ""
if ($BestValRaw) { $lines += ("- Best validation raw checkpoint: '{0}' with raw abs_rel/a1 '{1}'/'{2}'." -f $BestValRaw.checkpoint,$BestValRaw.raw_abs_rel,$BestValRaw.raw_a1) } else { $lines += "- Best validation raw checkpoint: not available." }
if ($BestTestRaw) { $lines += ("- Best test-confirmed raw checkpoint: '{0}' with raw abs_rel/a1 '{1}'/'{2}'." -f $BestTestRaw.checkpoint,$BestTestRaw.raw_abs_rel,$BestTestRaw.raw_a1) } else { $lines += "- Best test-confirmed raw checkpoint: not available." }
$lines += ""
$lines += "## Generated Outputs"
$lines += ""
$lines += "- Final loss plots: 'branch_g_original_prior/results//loss_plots/'"
$lines += "- Final B-vs-G panels: 'branch_g_original_prior/results//visuals/'"
$lines += "- Sweep summaries and best-vs-latest panels: 'branch_g_original_prior/results//checkpoint_sweep/'"
$lines += ""
$lines += "## Note"
$lines += ""
$lines += "This auto report is mechanical. A human/Codex visual verdict still needs to inspect the generated panels before promoting Branch G over Branch B 'weights_24'."

Set-Content -Path $Report -Value ($lines -join "`r`n") -Encoding UTF8

$main = Get-Content -Path $MainReport -Raw
$marker = "`r`n## Success Criteria"
$section = "`r`n## Overnight Auto Pipeline`r`n`r`nThe overnight watcher completed or attempted the 30ep post-training pipeline. See '00_BRANCH_G_OVERNIGHT_AUTO_REPORT.md' for generated final metrics, sweep pointers, and output paths.`r`n"
if ($main -notlike "*## Overnight Auto Pipeline*") {
  $main = $main.Replace($marker, $section + $marker)
  Set-Content -Path $MainReport -Value $main -Encoding UTF8
}

"Branch G overnight watcher finished $(Get-Date -Format s)" | Tee-Object -FilePath $WatcherLog -Append
