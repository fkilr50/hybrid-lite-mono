# Milestone 6: Paper Package

Use this folder for milestone-specific helpers, notes, or experiment files related to:

- final tables and figures
- paper-ready summaries
- writing support and reproducibility packaging

## Generated Paper Figures (2026-06-22)

Reproducible generator:

- `generate_paper_figures.py`

Paper-ready outputs:

- `figures/fig1_hybrid_training_rgb_only_inference.pdf`
- `figures/fig1_hybrid_training_rgb_only_inference.png`
- `figures/fig2_original_branchB_branchG_same_frame.pdf`
- `figures/fig2_original_branchB_branchG_same_frame.png`
- `figures/README.md` contains finalized captions and LaTeX insertion snippets.

Figure 1 documents the core hybrid method: RGB-only Lite-Mono inference with projected/densified LiDAR and valid masks used only for masked log-L1 training supervision.

Figure 2 uses real Citrus test frames and real model inference to compare Original Lite-Mono, Branch B `weights_24`, and Branch G `weights_0` at a shared raw metric-depth scale. It includes good, typical, and bad Branch G-selected test examples to show both the scale improvement and remaining soft-boundary failure.

## Hybrid Presentation Package (2026-06-24)

Slide-by-slide assembly guide:

- `HYBRID_PRESENTATION_GUIDE.md`

Reproducible presentation-chart generator:

- `generate_presentation_assets.py`

Generated presentation assets:

- `presentation_assets/slide_absolute_scale_result.png`
- `presentation_assets/slide_absolute_scale_result.pdf`
- `presentation_assets/slide_branch_study_result.png`
- `presentation_assets/slide_branch_study_result.pdf`

The guide updates the current group deck so the label-free and hybrid studies remain independent. It replaces the outdated Hybrid `weights_13` Slides 13-19 with the final masked-LiDAR method, the absolute-scale result, the B/C/F/G/H/H2 branch study, the same-frame qualitative comparison, and the remaining boundary limitation.
