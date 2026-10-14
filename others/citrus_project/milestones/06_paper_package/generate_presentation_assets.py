from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np


ROOT = Path(__file__).resolve().parent
OUT = ROOT / "presentation_assets"
OUT.mkdir(parents=True, exist_ok=True)

NAVY = "#173B67"
TEAL = "#148C84"
GREEN = "#2E7D32"
RED = "#B54545"
GOLD = "#C28A22"
GRAY = "#777777"
LIGHT_GRID = "#D9DEE7"


def finish(fig, stem):
    fig.savefig(OUT / f"{stem}.png", dpi=220, bbox_inches="tight", facecolor="white")
    fig.savefig(OUT / f"{stem}.pdf", bbox_inches="tight", facecolor="white")
    plt.close(fig)


def label_bars(ax, bars, fmt="{:.4f}"):
    for bar in bars:
        height = bar.get_height()
        ax.annotate(
            fmt.format(height),
            (bar.get_x() + bar.get_width() / 2, height),
            xytext=(0, 7),
            textcoords="offset points",
            ha="center",
            va="bottom",
            fontsize=12,
            fontweight="bold",
        )


def absolute_scale_chart():
    models = ["Original\nLite-Mono", "Plain Citrus\nself-supervised", "Hybrid 30ep\nLiDAR-supervised"]
    abs_rel = [0.7273, 0.7787, 0.1741]
    delta1 = [0.0149, 0.0077, 0.8186]
    colors = [NAVY, GRAY, TEAL]

    fig, axes = plt.subplots(1, 2, figsize=(13.4, 6.8))
    fig.suptitle(
        "Hybrid LiDAR supervision fixes the absolute-scale failure",
        fontsize=22,
        fontweight="bold",
        color=NAVY,
        y=0.98,
    )

    bars = axes[0].bar(models, abs_rel, color=colors, width=0.65)
    axes[0].set_title("Test raw AbsRel (lower is better)", fontsize=16, fontweight="bold")
    axes[0].set_ylim(0, 0.9)
    axes[0].set_ylabel("Raw AbsRel", fontsize=13)
    label_bars(axes[0], bars)

    bars = axes[1].bar(models, delta1, color=colors, width=0.65)
    axes[1].set_title(r"Test raw $\delta_1$ (higher is better)", fontsize=16, fontweight="bold")
    axes[1].set_ylim(0, 0.95)
    axes[1].set_ylabel(r"Raw $\delta_1$", fontsize=13)
    label_bars(axes[1], bars)

    for ax in axes:
        ax.grid(axis="y", color=LIGHT_GRID, linewidth=0.9)
        ax.set_axisbelow(True)
        ax.spines[["top", "right"]].set_visible(False)
        ax.tick_params(axis="x", labelsize=12)
        ax.tick_params(axis="y", labelsize=11)

    fig.text(
        0.5,
        0.015,
        "Raw metrics use the model's predicted metric scale; no per-image median correction.",
        ha="center",
        fontsize=12,
        color="#333333",
    )
    fig.tight_layout(rect=(0, 0.05, 1, 0.92), w_pad=3.0)
    finish(fig, "slide_absolute_scale_result")


def branch_study_chart():
    models = [
        "B: LiDAR-only",
        "C: +RGB smoothness",
        "F: sky prior",
        "G w0: original prior",
        "G w29: final",
        "H: low-LR retweak",
        "H2: weaker retweak",
    ]
    abs_rel = np.array([0.1382, 0.1384, 0.2492, 0.1375, 0.1424, 0.1408, 0.1400])
    delta1 = np.array([0.8695, 0.8694, 0.8564, 0.8739, 0.8751, 0.8733, 0.8739])
    colors = [NAVY, GOLD, RED, GREEN, TEAL, GRAY, "#6B7280"]

    fig, axes = plt.subplots(1, 2, figsize=(14.2, 7.6))
    fig.suptitle(
        "Branch study: LiDAR continuation matters more than the added priors",
        fontsize=21,
        fontweight="bold",
        color=NAVY,
        y=0.98,
    )
    y = np.arange(len(models))

    bars = axes[0].barh(y, abs_rel, color=colors, height=0.62)
    axes[0].set_yticks(y, models)
    axes[0].invert_yaxis()
    axes[0].set_xlim(0.125, 0.265)
    axes[0].set_title("Test raw AbsRel (lower is better)", fontsize=15, fontweight="bold")
    axes[0].axvline(abs_rel[0], color=NAVY, linestyle="--", linewidth=1.5, alpha=0.65)
    for bar, value in zip(bars, abs_rel):
        axes[0].text(
            value + 0.002,
            bar.get_y() + bar.get_height() / 2,
            f"{value:.4f}",
            va="center",
            fontsize=11,
            fontweight="bold",
        )

    bars = axes[1].barh(y, delta1, color=colors, height=0.62)
    axes[1].set_yticks(y, [""] * len(models))
    axes[1].invert_yaxis()
    axes[1].set_xlim(0.84, 0.88)
    axes[1].set_title(r"Test raw $\delta_1$ (higher is better)", fontsize=15, fontweight="bold")
    axes[1].axvline(delta1[0], color=NAVY, linestyle="--", linewidth=1.5, alpha=0.65)
    for bar, value in zip(bars, delta1):
        axes[1].text(
            value + 0.0007,
            bar.get_y() + bar.get_height() / 2,
            f"{value:.4f}",
            va="center",
            fontsize=11,
            fontweight="bold",
        )

    for ax in axes:
        ax.grid(axis="x", color=LIGHT_GRID, linewidth=0.9)
        ax.set_axisbelow(True)
        ax.spines[["top", "right"]].set_visible(False)
        ax.tick_params(labelsize=11)

    fig.text(
        0.5,
        0.02,
        "G weights_0 is the selected best balance, but its advantage over B is marginal; F is the clear regression.",
        ha="center",
        fontsize=12,
        color="#333333",
    )
    fig.tight_layout(rect=(0, 0.06, 1, 0.92), w_pad=2.2)
    finish(fig, "slide_branch_study_result")


if __name__ == "__main__":
    absolute_scale_chart()
    branch_study_chart()
    print(f"Presentation assets written to: {OUT}")
