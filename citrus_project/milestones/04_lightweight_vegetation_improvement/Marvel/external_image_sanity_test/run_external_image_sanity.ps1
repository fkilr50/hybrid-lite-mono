$ErrorActionPreference = "Stop"
$RepoRoot = "C:\Proj\lite-Mono"
$Python = "C:\Proj\miniforge3\envs\lite-mono\python.exe"
$Script = "citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/external_image_sanity_test/run_external_image_sanity.py"
Set-Location $RepoRoot
& $Python $Script
