# External Image Sanity Test

## Purpose

This folder is for qualitative testing on external RGB images, such as orchard/path/tree-row photos from Google or your own camera.

This is not a metric benchmark because these images do not have ground-truth depth. Use it to inspect visual behavior:

1. Does sky look far/dark?
2. Do tree tops bleed upward into sky?
3. Does the road/path get farther into the image?
4. Are near trunks/objects visually closer than the background?
5. Does a branch look more sane than Branch B/C on full-frame depth?

## Drop-Zone

Put selected images here:

```text
images/
```

Supported extensions:

```text
.jpg .jpeg .png .bmp .webp .avif
```

## Run

From the repo root:

```powershell
C:\Proj\miniforge3\envs\lite-mono\python.exe citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/external_image_sanity_test/run_external_image_sanity.py
```

Or run the helper:

```powershell
powershell -ExecutionPolicy Bypass -File citrus_project/milestones/04_lightweight_vegetation_improvement/Marvel/external_image_sanity_test/run_external_image_sanity.ps1
```

## Outputs

Outputs go here:

```text
outputs/
```

For each image, the script saves:

1. A side-by-side comparison panel.
2. Per-model near-bright heatmap PNG files.
3. Per-model approximate depth `.npy` arrays.

The heatmap is based on nearness/disparity, so:

```text
bright = near
dark = far
```

That is deliberate because the main visual failure we are checking is the cave effect, where sky incorrectly looks bright/near.

## Default Models

The script will use any of these model folders if they exist:

1. Original Lite-Mono: `weights/lite-mono`
2. Branch B selected checkpoint: `Branch B weights_24`
3. Branch C selected checkpoint: `Branch C weights_24`
4. Branch F smoke checkpoint: `Branch F weights_1`, only after the Branch F smoke run creates it

## Important Caveat

External images can expose bad full-frame priors, but they cannot prove metric accuracy. A model can look visually plausible and still be numerically wrong without ground truth.
