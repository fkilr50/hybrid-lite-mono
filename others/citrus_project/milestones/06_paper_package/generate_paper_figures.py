import argparse
import csv
import importlib.util
import sys
from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch
import numpy as np
from PIL import Image


def load_module(path):
    spec = importlib.util.spec_from_file_location("paper_compare_helpers", path)
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def read_rows(path):
    with path.open(newline="", encoding="utf-8") as fp:
        return list(csv.DictReader(fp))


def select_rows(rows, metric):
    scored = []
    for row in rows:
        try:
            value = float(row[metric])
        except (KeyError, TypeError, ValueError):
            continue
        if np.isfinite(value):
            scored.append((value, row))
    scored.sort(key=lambda item: item[0])
    if not scored:
        raise RuntimeError(f"No finite values for {metric}")
    return {
        "bad": scored[0][1],
        "typical": scored[len(scored) // 2][1],
        "good": scored[-1][1],
    }


def metrics(helper, pred, dense, mask):
    return helper.compute_metrics(pred, dense, mask, 1e-3, 80.0)


def add_box(ax, xy, width, height, title, subtitle, facecolor, edgecolor):
    box = FancyBboxPatch(
        xy,
        width,
        height,
        boxstyle="round,pad=0.012,rounding_size=0.018",
        linewidth=1.8,
        facecolor=facecolor,
        edgecolor=edgecolor,
        transform=ax.transAxes,
        zorder=2,
    )
    ax.add_patch(box)
    ax.text(
        xy[0] + width / 2,
        xy[1] + height * 0.62,
        title,
        ha="center",
        va="center",
        fontsize=12,
        fontweight="bold",
        transform=ax.transAxes,
        zorder=3,
    )
    ax.text(
        xy[0] + width / 2,
        xy[1] + height * 0.30,
        subtitle,
        ha="center",
        va="center",
        fontsize=9,
        color="#333333",
        transform=ax.transAxes,
        zorder=3,
    )
    return box


def add_arrow(ax, start, end, color="#2457A7", dashed=False, label=None, label_offset=(0, 0)):
    arrow = FancyArrowPatch(
        start,
        end,
        arrowstyle="-|>",
        mutation_scale=14,
        linewidth=2.0,
        color=color,
        linestyle="--" if dashed else "-",
        transform=ax.transAxes,
        zorder=4,
    )
    ax.add_patch(arrow)
    if label:
        x = (start[0] + end[0]) / 2 + label_offset[0]
        y = (start[1] + end[1]) / 2 + label_offset[1]
        ax.text(x, y, label, ha="center", va="center", fontsize=8.5, color=color, transform=ax.transAxes)


def make_method_figure(output_dir, rgb, label, mask, pred):
    fig = plt.figure(figsize=(14, 6), facecolor="white")
    ax = fig.add_axes([0, 0, 1, 1])
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis("off")

    blue = "#2457A7"
    orange = "#C45A1A"
    light_blue = "#EAF2FF"
    light_orange = "#FFF0E6"

    ax.text(0.5, 0.955, "Hybrid LiDAR-supervised training with unchanged RGB-only inference", ha="center", va="center", fontsize=16, fontweight="bold")

    rgb_ax = fig.add_axes([0.035, 0.55, 0.19, 0.285])
    rgb_ax.imshow(rgb)
    rgb_ax.axis("off")
    rgb_ax.set_title("RGB input", fontsize=12, fontweight="bold", pad=7)

    add_box(ax, (0.33, 0.59), 0.22, 0.20, "Lite-Mono", "encoder + depth decoder\n3.07M inference parameters", light_blue, blue)

    pred_ax = fig.add_axes([0.66, 0.55, 0.22, 0.285])
    pred_ax.imshow(pred, cmap="magma_r", vmin=0.5, vmax=np.nanpercentile(label[np.isfinite(label)], 98))
    pred_ax.axis("off")
    pred_ax.set_title("Predicted metric depth", fontsize=12, fontweight="bold", pad=7)

    add_arrow(ax, (0.225, 0.69), (0.33, 0.69), color=blue, label="single RGB image", label_offset=(0, 0.035))
    add_arrow(ax, (0.55, 0.69), (0.66, 0.69), color=blue, label="depth", label_offset=(0, 0.035))
    ax.text(0.46, 0.835, "INFERENCE PATH", ha="center", va="center", fontsize=10, color=blue, fontweight="bold")

    train_zone = FancyBboxPatch(
        (0.025, 0.06),
        0.95,
        0.39,
        boxstyle="round,pad=0.012,rounding_size=0.018",
        linewidth=1.5,
        facecolor="#FFFDFC",
        edgecolor=orange,
        linestyle="--",
        transform=ax.transAxes,
        zorder=1,
    )
    ax.add_patch(train_zone)
    ax.text(0.05, 0.415, "TRAINING ONLY", ha="left", va="center", fontsize=10, color=orange, fontweight="bold", transform=ax.transAxes)

    label_ax = fig.add_axes([0.06, 0.115, 0.18, 0.22])
    masked_label = np.where(mask, label, np.nan)
    cmap = plt.get_cmap("magma_r").copy()
    cmap.set_bad("white")
    label_ax.imshow(masked_label, cmap=cmap, vmin=0.5, vmax=np.nanpercentile(masked_label, 98))
    label_ax.axis("off")
    label_ax.set_title("Projected + local-IDW LiDAR depth", fontsize=10, pad=5)

    mask_ax = fig.add_axes([0.255, 0.115, 0.12, 0.22])
    mask_ax.imshow(mask, cmap="gray")
    mask_ax.axis("off")
    mask_ax.set_title("Valid mask", fontsize=10, pad=5)

    add_box(ax, (0.45, 0.15), 0.22, 0.16, "Masked log-L1 loss", "valid LiDAR pixels only\nweight = 0.1; no scale alignment", light_orange, orange)
    add_box(ax, (0.76, 0.15), 0.18, 0.16, "Metric supervision", "correct absolute scale\nduring training", light_orange, orange)

    add_arrow(ax, (0.375, 0.23), (0.45, 0.23), color=orange)
    add_arrow(ax, (0.67, 0.23), (0.76, 0.23), color=orange)
    add_arrow(ax, (0.47, 0.59), (0.56, 0.31), color=orange, dashed=True, label="predicted depth", label_offset=(0.055, 0.055))
    add_arrow(ax, (0.80, 0.31), (0.52, 0.59), color=orange, dashed=True, label="loss gradient", label_offset=(0.025, 0.085))

    ax.text(0.5, 0.018, "At inference, LiDAR, masks, and training losses are removed; the architecture and RGB-only interface remain unchanged.", ha="center", va="bottom", fontsize=10, color="#333333")

    png = output_dir / "fig1_hybrid_training_rgb_only_inference.png"
    pdf = output_dir / "fig1_hybrid_training_rgb_only_inference.pdf"
    fig.savefig(png, dpi=300, bbox_inches="tight", facecolor="white")
    fig.savefig(pdf, bbox_inches="tight", facecolor="white")
    plt.close(fig)
    return png, pdf


def make_qualitative_figure(output_dir, helper, workspace, selected, models):
    ordered_roles = ["good", "typical", "bad"]
    records = []
    depth_values = []

    for role in ordered_roles:
        row = selected[role]
        dense = helper.load_npz_array(workspace / row["dense_rel"]).astype(np.float32)
        valid = helper.load_npz_array(workspace / row["valid_mask_rel"]) > 0
        rgb = Image.open(workspace / row["rgb_rel"]).convert("RGB")
        preds = {name: helper.run_lite_mono_inference_direct(workspace / row["rgb_rel"], dense.shape, model) for name, model in models.items()}
        common = valid & np.isfinite(dense) & (dense > 1e-3) & (dense < 80.0)
        for pred in preds.values():
            common &= np.isfinite(pred) & (pred > 0)
        metric_values = {name: metrics(helper, pred, dense, common) for name, pred in preds.items()}
        label_display = np.where(common, dense, np.nan)
        depth_values.append(dense[common])
        depth_values.append(preds["Branch B w24"][common])
        depth_values.append(preds["Branch G w0"][common])
        records.append((role, row, rgb, label_display, preds, metric_values))

    combined = np.concatenate(depth_values)
    vmin = max(0.1, float(np.percentile(combined, 1)))
    vmax = float(np.percentile(combined, 99))
    cmap = plt.get_cmap("magma_r").copy()
    cmap.set_bad("white")

    fig, axes = plt.subplots(3, 5, figsize=(14.2, 8.5), constrained_layout=True)
    columns = ["RGB", "LiDAR label", "Original Lite-Mono", "Branch B w24", "Branch G w0"]
    for c, title in enumerate(columns):
        axes[0, c].set_title(title, fontsize=11, fontweight="bold", pad=7)

    last_im = None
    for r, (role, row, rgb, label_display, preds, metric_values) in enumerate(records):
        index = int(row["index"])
        axes[r, 0].imshow(rgb)
        axes[r, 0].text(0.02, 0.95, f"{role.title()}  #{index}", transform=axes[r, 0].transAxes, ha="left", va="top", color="white", fontsize=9, fontweight="bold", bbox=dict(boxstyle="round,pad=0.25", facecolor="#183B68", edgecolor="none", alpha=0.92))
        last_im = axes[r, 1].imshow(label_display, cmap=cmap, vmin=vmin, vmax=vmax)
        for c, name in enumerate(["Original", "Branch B w24", "Branch G w0"], start=2):
            axes[r, c].imshow(preds[name], cmap=cmap, vmin=vmin, vmax=vmax)
            m = metric_values[name]
            axes[r, c].text(0.5, -0.055, f"raw abs_rel {m['abs_rel']:.3f} | δ1 {m['a1']:.3f}", transform=axes[r, c].transAxes, ha="center", va="top", fontsize=7.5)
        for ax in axes[r]:
            ax.axis("off")

    cbar = fig.colorbar(last_im, ax=axes[:, 1:], fraction=0.018, pad=0.012)
    cbar.set_label("Depth (m): bright = near, dark = far", fontsize=9)
    fig.suptitle("Same-frame Citrus depth comparison (raw metric scale)", fontsize=14, fontweight="bold")

    png = output_dir / "fig2_original_branchB_branchG_same_frame.png"
    pdf = output_dir / "fig2_original_branchB_branchG_same_frame.pdf"
    fig.savefig(png, dpi=300, bbox_inches="tight", facecolor="white")
    fig.savefig(pdf, bbox_inches="tight", facecolor="white")
    plt.close(fig)
    return png, pdf


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--no_cuda", action="store_true")
    args = parser.parse_args()

    repo = Path(__file__).resolve().parents[3]
    marvel = repo / "citrus_project" / "milestones" / "04_lightweight_vegetation_improvement" / "Marvel"
    helper = load_module(marvel / "compare_two_checkpoints_raw_and_scaled.py")
    workspace = repo / "citrus_project" / "dataset_workspace"
    branch_g_run = marvel / "branch_g" / "branch_g_original_prior" / "results" / "branch_g_original_prior_from_b24_b12_30ep_w005_laptop" / "checkpoint_sweep" / "test_confirm" / "weights_0"
    rows = read_rows(branch_g_run / "test_lite-mono_full_per_sample.csv")
    selected = select_rows(rows, "median_scaled_a1")

    weights = {
        "Original": repo / "weights" / "lite-mono",
        "Branch B w24": marvel / "runs" / "branch_b_lidar_only_from_w13_b12_30ep_s001_laptop" / "models" / "weights_24",
        "Branch G w0": marvel / "runs" / "branch_g_original_prior_from_b24_b12_30ep_w005_laptop" / "models" / "weights_0",
    }
    models = {name: helper.load_lite_mono_model_direct(path, "lite-mono", args.no_cuda, 0.1, 100.0) for name, path in weights.items()}

    typical = selected["typical"]
    dense = helper.load_npz_array(workspace / typical["dense_rel"]).astype(np.float32)
    valid = helper.load_npz_array(workspace / typical["valid_mask_rel"]) > 0
    label = np.where(valid, dense, np.nan)
    rgb = Image.open(workspace / typical["rgb_rel"]).convert("RGB")

    output_dir = Path(__file__).resolve().parent / "figures"
    output_dir.mkdir(parents=True, exist_ok=True)
    outputs = []
    method_pred = helper.run_lite_mono_inference_direct(workspace / typical["rgb_rel"], dense.shape, models["Branch G w0"])
    outputs.extend(make_method_figure(output_dir, rgb, label, valid, method_pred))
    outputs.extend(make_qualitative_figure(output_dir, helper, workspace, selected, models))
    for output in outputs:
        print(output)


if __name__ == "__main__":
    main()



