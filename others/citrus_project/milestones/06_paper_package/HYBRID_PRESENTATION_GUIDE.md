# Hybrid Lite-Mono Presentation Guide

## Purpose

This guide updates the current 19-slide presentation so the two research tracks remain independent:

1. Label-free self-distillation track.
2. Hybrid LiDAR-supervised track.

The shared background, dataset, and baseline can remain at the beginning. The hybrid section should replace the outdated material currently on Slides 13-19.

Target speaking time for the hybrid section: about 4-5 minutes.

## Whole-Deck Corrections

### Slide 1: Broaden the presentation title

The current title describes only the label-free experiment. Replace it with:

> **Lightweight Monocular Depth in Citrus Orchards**  
> **Independent Label-Free and Hybrid LiDAR-Supervised Studies**

Keep the group-member names and date.

Do not place experiment-to-experiment comparisons on this slide. The title only establishes that the group studied two independent approaches.

### Slide 4: Replace the single label-free research goal

Title:

> **Research Goal and Independent Study Tracks**

On-slide text:

> **Shared goal:** Improve lightweight monocular depth estimation for CitrusFarm while keeping runtime inference RGB-only.
>
> **Track 1 - Label-free adaptation**  
> Uses RGB-only self-supervised and teacher-guided training. LiDAR is evaluation-only.
>
> **Track 2 - Hybrid supervision**  
> Uses LiDAR depth and valid masks during training and evaluation. LiDAR is removed at inference.

Bottom statement:

> Both tracks deploy the same lightweight single-RGB Lite-Mono inference interface.

Suggested visual:

- Reuse the existing `Single RGB image -> Lite-Mono -> Predicted depth map` diagram.
- Add two small training-only labels above it: `Label-free training` and `LiDAR-supervised training`.

### Slide 9: Remove the blank slide

Delete Slide 9 unless another group member needs it. A completely blank slide interrupts the presentation flow.

## Hybrid Section: Replace Current Slides 13-19

## Slide 13: Section Divider

Title:

> **Independent Track 2: Hybrid LiDAR-Supervised Lite-Mono**

Subtitle:

> Metric LiDAR supervision during training, monocular RGB-only inference at deployment

Small footer:

> Marvel Aiken - Hybrid supervised study

Image:

- No image is required. A clean section divider is preferable.
- Optional: use a small crop of the RGB and predicted-depth panels from:
  `figures/fig1_hybrid_training_rgb_only_inference.png`

Speaker note:

> My experiment is independent from the label-free track. I relaxed the training constraint by using CitrusFarm LiDAR labels, but I kept deployment unchanged: the trained model still receives only one RGB image.

## Slide 14: Why Switch to Hybrid Supervision?

Title:

> **Why Use LiDAR During Training?**

On-slide text:

> - Citrus textures, shadows, motion, and occlusion can make photometric training unreliable.
> - Plain Citrus self-supervised adaptation did not recover usable absolute metric scale.
> - CitrusFarm already provides synchronized LiDAR, so we use it as a direct metric-depth training target.
> - LiDAR remains training/evaluation-only; inference remains RGB-only.

Large callout:

> **Plain Citrus test raw:** AbsRel `0.7787`, delta1 `0.0077`

Small definition:

> Raw metrics evaluate the model's predicted metric scale without per-image median correction.

Image:

- No additional image is needed. Use the large metric callout as the visual focus.
- Do not reuse the old median-scaled table on the current Slide 14; it hides the absolute-scale failure that motivates this experiment.

Speaker note:

> Median scaling can make relative structure look acceptable because it gives every image a free scale correction. Raw evaluation exposed the real problem: the self-supervised model predicted depth at almost completely wrong scale.

## Slide 15: Hybrid Training Method

Title:

> **Hybrid Training, RGB-Only Inference**

On-slide text:

> - Input to the deployed depth model: one RGB image.
> - Training label: projected and conservatively densified LiDAR depth.
> - A valid mask limits supervision to supported LiDAR pixels.
> - Masked log-L1 depth loss teaches absolute metric scale.
> - Photometric/reprojection training and the pose branch are disabled in this hybrid recipe.
> - LiDAR, masks, and training losses are removed at inference.

Image to insert:

`C:/Proj/lite-Mono/citrus_project/milestones/06_paper_package/figures/fig1_hybrid_training_rgb_only_inference.png`

Preferred layout:

- Put the figure across the lower two-thirds of the slide.
- Keep only the first four bullets if space is limited.
- Do not add the old vertical arrow diagram from Slide 16; Figure 1 already explains the complete flow.

Speaker note:

> The architecture does not change. During training, the predicted depth is compared with LiDAR only where the valid mask is active. This directly teaches metric scale. At deployment, the entire orange training-only path disappears.

## Slide 16: Main Absolute-Scale Result

Title:

> **Main Result: Absolute Metric Scale Recovered**

On-slide takeaway:

> Hybrid LiDAR supervision produces the dominant improvement; it changes the model from nearly unusable raw-scale depth to meaningful metric prediction.

Image to insert:

`C:/Proj/lite-Mono/citrus_project/milestones/06_paper_package/presentation_assets/slide_absolute_scale_result.png`

Numbers represented in the chart:

| Model | Test raw AbsRel | Test raw delta1 |
|---|---:|---:|
| Original Lite-Mono | 0.7273 | 0.0149 |
| Plain Citrus self-supervised | 0.7787 | 0.0077 |
| Hybrid 30ep `weights_29` | 0.1741 | 0.8186 |

Speaker note:

> Lower AbsRel and higher delta1 are better. The hybrid model dramatically improves both raw metrics. This is the strongest result of my study and is much larger than the later differences between experimental branches.

## Slide 17: Controlled Branch Study

Title:

> **What Actually Helped After Hybrid Training?**

Short on-slide labels:

> **B:** LiDAR-only continuation  
> **C:** B plus RGB smoothness  
> **F:** hand-coded sky/far prior  
> **G:** weak frozen original-model prior outside the LiDAR mask  
> **H/H2:** low-learning-rate G retweaks

Image to insert:

`C:/Proj/lite-Mono/citrus_project/milestones/06_paper_package/presentation_assets/slide_branch_study_result.png`

Bottom takeaway:

> B and C are effectively tied. F fails. G `weights_0` gives the best overall balance, but its advantage over B is marginal.

Speaker note:

> The branch study prevents us from attributing the gain to the wrong component. Generic RGB smoothness did not add measurable value over LiDAR continuation. The sky heuristic damaged accuracy. G was selected as the best balance, but it improved B by only a few thousandths, so I do not present it as a breakthrough.

## Slide 18: Qualitative Result and Honest Limitation

Title:

> **Better Metric Depth, Boundaries Still Unsolved**

On-slide text:

> - Original Lite-Mono has severe absolute-scale failure.
> - Branch B and Branch G recover stronger scene-level metric depth.
> - Branch G is not universally better than B in every image.
> - Tree canopies, trunks, and other objects can remain soft, coarse, or blob-like.

Image to insert:

`C:/Proj/lite-Mono/citrus_project/milestones/06_paper_package/figures/fig2_original_branchB_branchG_same_frame.png`

Image explanation:

> Warm colors are nearer and dark colors are farther. Predictions are shown at raw metric scale, not median-scaled.

Preferred layout:

- Let the image occupy at least 70% of the slide.
- Put no more than three short bullets beside or above it.
- Do not shrink it into the same crowded layout used on the old Slides 17-18.

Speaker note:

> Quantitatively, the LiDAR-supervised models are much stronger. Visually, they also recover more meaningful scene depth. However, the supervision does not provide enough trustworthy information at thin foliage and object boundaries, so the model often predicts broad depth regions instead of crisp outlines.

## Slide 19: Conclusion and Future Work

Title:

> **Hybrid Study: Conclusions**

On-slide text:

> **What worked**
>
> - Masked LiDAR supervision fixed the largest failure: absolute metric scale.
> - Runtime remained lightweight and monocular RGB-only.
> - Branch G `weights_0` was selected as the best overall balance.
>
> **What did not work**
>
> - RGB smoothness did not clearly improve the LiDAR-only control.
> - The hand-coded sky prior regressed accuracy.
> - Longer G training and H/H2 retweaks did not beat G `weights_0`.
>
> **Next research step**
>
> - Add trustworthy semantic/object boundary supervision where LiDAR labels are weak or absent.
> - Validate across additional CitrusFarm sequences and other orchards.

Final metric callout:

> **Branch G `weights_0` test raw:** AbsRel `0.1375`, delta1 `0.8739`

Speaker note:

> The defensible conclusion is not that every added prior worked. The reliable contribution is that LiDAR-supervised training fixed absolute scale while preserving RGB-only inference. Boundary quality remains the main unsolved problem and motivates semantic or object-aware supervision.

## Asset Inventory

### Existing paper assets

Method diagram:

`C:/Proj/lite-Mono/citrus_project/milestones/06_paper_package/figures/fig1_hybrid_training_rgb_only_inference.png`

Same-frame qualitative comparison:

`C:/Proj/lite-Mono/citrus_project/milestones/06_paper_package/figures/fig2_original_branchB_branchG_same_frame.png`

PDF/vector versions are in the same folder and can be used if the presentation software imports PDF cleanly.

### Newly generated presentation assets

Absolute-scale result:

`C:/Proj/lite-Mono/citrus_project/milestones/06_paper_package/presentation_assets/slide_absolute_scale_result.png`

Simplified branch study:

`C:/Proj/lite-Mono/citrus_project/milestones/06_paper_package/presentation_assets/slide_branch_study_result.png`

Vector PDF versions are available beside both PNG files.

Regeneration command:

```powershell
python C:\Proj\lite-Mono\citrus_project\milestones\06_paper_package\generate_presentation_assets.py
```

## Material to Remove From the Existing Hybrid Slides

Remove or replace the following outdated claims:

1. `Hybrid weights_13` as the final result.
2. The claim that the hybrid recipe combines photometric, smoothness, and LiDAR losses.
3. `RGB temporal frames` as the hybrid training input.
4. The old LiDAR-aware edge-loss slide as the immediate next experiment.
5. Repeated explanations of why self-supervision fails across several slides.
6. Tiny multi-chart layouts that cannot be read from the audience.

## Language Rules

Use:

- `LiDAR-supervised training with RGB-only inference`
- `projected and conservatively densified LiDAR labels`
- `best overall balance`
- `marginal improvement over the LiDAR-only control`
- `boundaries remain an open problem`

Avoid:

- `ground truth` without qualification
- `statistically significant`
- `solved boundaries`
- `G is universally best`
- `every branch improved the model`
- direct comparison with the separate label-free experiment beyond the shared baseline context
