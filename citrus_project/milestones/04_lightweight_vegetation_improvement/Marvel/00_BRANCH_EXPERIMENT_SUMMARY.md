# Marvel Branch Experiment Summary

Date: 2026-06-12

## Executive Verdict

The current best model is **Branch G `weights_0`**.

This is an incremental win, not a breakthrough. Branch G `weights_0` gives the best confirmed Citrus test metrics among the local Marvel branch experiments, and it has the best current balance between metric depth accuracy and general visual sanity. However, the visual improvement is subtle. On external sanity-test images, Branch G often understands the rough location of objects and foreground/background regions, but it still does not draw clean object outlines or crisp boundaries. In other words, it has a better global prior than the pure LiDAR-only variants, but it is not truly object-aware.

The practical conclusion is:

1. Use Branch G `weights_0` as the current proposed/best checkpoint.
2. Keep Branch B `weights_24` as the strongest simple LiDAR-only control.
3. Treat Branch C as an RGB-smoothness ablation that did not clearly improve over Branch B.
4. Treat Branch F as a failed but informative sky-prior attempt.
5. Treat Branch H/H2 as evidence that simply lowering LR/weakening the original prior does not improve over Branch G.
6. Before launching another training branch, do a focused failure-case review.

## Core Metric Comparison

Lower `abs_rel` is better. Higher `a1` is better.

| Model / branch | Main idea | Selected checkpoint | Val raw abs_rel | Val raw a1 | Test raw abs_rel | Test raw a1 | Test median abs_rel | Test median a1 | Verdict |
|---|---|---:|---:|---:|---:|---:|---:|---:|---|
| Original Lite-Mono | Pretrained KITTI-style baseline, no Citrus adaptation | `weights/lite-mono` | 0.7128 | 0.0195 | 0.7273 | 0.0149 | 0.3836 | 0.4989 | Poor Citrus metric depth; useful generic visual prior |
| Earlier Hybrid / Branch A reference | Masked LiDAR-supervised hybrid checkpoint from earlier work | `weights_13` | 0.1716 | 0.8131 | 0.1620 | 0.8149 | 0.1677 | 0.8159 | Strong improvement over original, later superseded |
| Branch B | LiDAR-only continued training control | `weights_24` | 0.1530 | 0.8672 | 0.1382 | 0.8695 | 0.1436 | 0.8661 | Strongest simple control; most gain comes from LiDAR supervision |
| Branch C | Branch B + RGB edge-aware smoothness | `weights_24` | 0.1531 | 0.8673 | 0.1384 | 0.8694 | 0.1437 | 0.8657 | Essentially tied with B; RGB smoothness not proven useful |
| Branch F | Branch B + weak sky/far and sky-edge priors | `weights_1` | 0.2391 | 0.8540 | 0.2492 | 0.8564 | 0.2446 | 0.8460 | Rejected; visual prior was too blunt and hurt metrics badly |
| Branch G | Branch B + frozen original Lite-Mono prior on LiDAR-invalid pixels | `weights_0` | 0.1524 | 0.8658 | **0.1375** | **0.8739** | **0.1406** | **0.8721** | Official current best balance checkpoint |
| Branch G final | Same as G, final 30-epoch checkpoint | `weights_29` | 0.1582 | 0.8678 | 0.1424 | 0.8751 | 0.1456 | 0.8713 | Later training improved raw a1 slightly but worsened abs_rel |
| Branch H | Short low-LR Branch G retweak, prior weight 0.005 | `weights_1` | 0.1553 | 0.8665 | 0.1408 | 0.8733 | 0.1436 | 0.8702 | Did not beat G or B |
| Branch H2 | Short low-LR Branch G retweak, prior weight 0.0025 | `weights_1` | 0.1547 | 0.8668 | 0.1400 | 0.8739 | 0.1428 | 0.8706 | Better than H, still not better than G |

## Branch Experience Table

| Branch | Question tested | What we changed | What happened | What we learned |
|---|---|---|---|---|
| Branch A / earlier Hybrid | Can masked LiDAR supervision rescue Citrus scale and depth compared with original Lite-Mono? | Used dense LiDAR and valid masks during training while keeping RGB-only inference | Strong metric improvement over original Lite-Mono, selected checkpoint was `weights_13` rather than final epoch | Supervised/hybrid LiDAR training is much more reliable than pure self-supervised Citrus adaptation |
| Branch B | Is LiDAR-only continuation enough to explain the gain? | Continued from earlier Hybrid `weights_13`, disabled photometric loss, used masked LiDAR log-L1, no RGB smoothness | Became the strongest simple model. `weights_24` selected by sweep | Most of the improvement came from LiDAR-supervised continuation, not fancy edge terms |
| Branch C | Does RGB edge-aware smoothness add useful boundary awareness? | Same as B but added RGB edge-aware disparity smoothness | Metrics and visuals were almost tied with B; B slightly won raw test abs_rel | Generic RGB smoothness did not prove useful enough under this recipe |
| Branch F | Can hand-coded sky/far priors fix cave-like sky and tree-top bleed? | Added weak RGB sky/far and sky-edge contrast losses from Branch B `weights_24` | Some sky regions looked darker, but metrics collapsed badly | The idea is directionally understandable but the implementation was too blunt; sky priors need better masks or semantic support |
| Branch G | Can original Lite-Mono preserve broader visual structure outside LiDAR-valid pixels? | Added frozen original Lite-Mono normalized-disparity prior on LiDAR-invalid pixels | `weights_0` slightly beat B/C on test metrics and looked closest to the original global prior, but visual improvement was subtle | Original prior is useful as a small stabilizer, but long training drifts. Best checkpoint was early, not final |
| Branch H | Can a short low-LR Branch G retweak make the improvement more stable? | 3 epochs, LR `1e-5`, prior weight `0.005` | Did not beat G or B | Simply lowering LR and training briefly is not enough |
| Branch H2 | Does a weaker original-prior weight help? | Same as H but prior weight `0.0025` | Better than H, but still behind G and B on raw abs_rel | Weaker prior is less harmful, but this route still gives diminishing returns |

## Checkpoint Selection Lessons

| Lesson | Evidence |
|---|---|
| Final epoch is not automatically best | Earlier Hybrid selected `weights_13`; Branch B selected `weights_24`; Branch C selected `weights_24`; Branch G selected `weights_0`; H/H2 selected `weights_1` by validation raw abs_rel |
| Validation-first selection matters | Branch G final `weights_29` had slightly higher test raw a1 than `weights_0`, but worse raw/median abs_rel. The selected model depends on the agreed metric priority |
| Test should confirm, not select blindly | Branch H/H2 had validation-selected `weights_1`, but test raw abs_rel was slightly better at `weights_0` inside each short run. This should be interpreted carefully, not used to rewrite the protocol after seeing test |
| Visual panels are necessary | Branch B/C/G are close numerically; without same-image panels, it is too easy to overclaim tiny metric differences |
| External sanity tests reveal what LiDAR masks miss | A model can perform well on LiDAR-valid Citrus metrics but still produce vague object boundaries or weak full-frame object shape on normal photos |

## Visual Findings

| Observation | Branch evidence | Interpretation |
|---|---|---|
| Branch B and Branch C are visually almost indistinguishable | B24-vs-C24 same-image panels show tiny differences | RGB smoothness did not create a clear visual boundary win |
| Branch F sometimes makes sky/open regions darker | External and Citrus panels show some sky/far behavior improvement | The prior targeted a real failure but damaged metric depth too much |
| Branch G is the best visual-metric compromise | Big external sanity panels show G closer to original Lite-Mono's global prior than B/C, while Citrus metrics remain best | G is useful, but the improvement is subtle |
| Branch G still does not outline objects clearly | External sanity images show G knows roughly where objects/foreground are, but the object shapes are blurry and boundaries are not clean | Current training teaches depth regions, not object segmentation or crisp object boundaries |
| Original Lite-Mono can look more natural on generic photos | Original has broad pretraining priors, but poor Citrus metric scale | Generic visual plausibility and Citrus metric depth are different objectives |

## Current Failure Case: Weak Object Outlines

The main failure we should record from visual inspection is not simply `bad sky` anymore. The sharper failure is:

```text
Branch G roughly detects where objects are, but it does not outline them clearly.
```

On external sanity-test images, Branch G often places approximate foreground/background regions in the right area, but the shapes are soft. Tree canopies, trunks, flowers, rocks, and other objects are represented as broad depth blobs rather than crisp object boundaries. This means Branch G is learning a better global depth prior, but not an explicit object-boundary prior.

This failure matters because the robot motivation likely needs reliable obstacle/plant structure, not just low average LiDAR-valid depth error. A model can have strong `abs_rel` on sparse/densified LiDAR labels while still being visually poor at full-frame object separation.

## What Not To Claim

| Claim | Status |
|---|---|
| Branch G is a dramatic visual breakthrough | Do not claim this |
| Branch C proves RGB edge smoothness improves Citrus boundaries | Do not claim this |
| Branch F solved sky/far sanity | False; it regressed metrics badly |
| Branch H/H2 improved on Branch G | False |
| Branch G is currently the best metric/visual balance among our branches | Reasonable to claim, with caveat that the visual gain is subtle |
| LiDAR-supervised training is the main source of improvement | Strongly supported by Branch B/C results |

## Recommended Next Step

Do **not** launch another blind recipe tweak immediately.

Recommended order:

1. Package Branch G `weights_0` as the current best result.
2. Build a clean presentation/table comparing Original, Branch B, Branch C, Branch G, and failed/rejected branches.
3. Run a failure-case review focused on object-boundary weakness:
   - where objects are roughly detected but not outlined
   - tree/sky transitions
   - trunks and plant boundaries
   - external images where object shape is obvious to humans
4. Use those failures to design the next experiment.

Potential future directions after failure analysis:

| Direction | Why it may help | Risk |
|---|---|---|
| Semantic/segmentation-assisted object or sky masks during training | Could explicitly tell the model where object regions are, instead of relying on RGB gradients | Adds dependency on labels/model; may weaken lightweight/simple story |
| Edge-aware loss gated by trustworthy object/semantic edges | More targeted than generic RGB smoothness | Bad edges/noisy masks can cause artifacts |
| Better LiDAR label confidence / mask handling | May reduce training on unsupported interpolated regions | More pipeline work; may reduce training coverage |
| More diverse agricultural data or augmentation | May improve external/general visual sanity | Requires data access and time |
| Post-training calibration / early-stop protocol around Branch G | Cheap and controlled | Likely small gains only |

## Key Artifact Paths

| Artifact | Path |
|---|---|
| Branch B report | `branch_b/00_BRANCH_B_REPORT.md` |
| Branch C report | `branch_c/00_BRANCH_C_REPORT.md` |
| Branch F report | `branch_f/00_BRANCH_F_REPORT.md` |
| Branch G report | `branch_g/00_BRANCH_G_REPORT.md` |
| Branch H report | `branch_h/00_BRANCH_H_REPORT.md` |
| Branch G best-vs-latest panels | `branch_g/branch_g_original_prior/results/branch_g_original_prior_from_b24_b12_30ep_w005_laptop/checkpoint_sweep/visuals/branch_g_w0_vs_w29_test/` |
| Branch G vs Branch B panels | `branch_g/branch_g_original_prior/results/branch_g_original_prior_from_b24_b12_30ep_w005_laptop/checkpoint_sweep/visuals/branch_g_w0_vs_branch_b_w24_test/` |
| Big external sanity comparison | `external_image_sanity_test/outputs_big_original_b_c_f_g_median_scaled/` |
