from __future__ import absolute_import, division, print_function

import argparse
import os
import sys
from pathlib import Path

os.environ["KMP_DUPLICATE_LIB_OK"] = "TRUE"

import matplotlib
matplotlib.use("Agg")
import matplotlib.cm as cm
import matplotlib.pyplot as plt
import numpy as np
import PIL.Image as pil
import torch
from torchvision import transforms


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR
while not (REPO_ROOT / "utils.py").exists():
    if REPO_ROOT.parent == REPO_ROOT:
        raise RuntimeError("Could not locate Lite-Mono repo root from {}".format(__file__))
    REPO_ROOT = REPO_ROOT.parent
sys.path.insert(0, str(REPO_ROOT))

import networks
from layers import disp_to_depth


DEFAULT_MODELS = [
    (
        "original_litemono",
        REPO_ROOT / "weights" / "lite-mono",
    ),
    (
        "branch_b_w24",
        REPO_ROOT / "citrus_project" / "milestones" / "04_lightweight_vegetation_improvement" / "Marvel" / "runs" / "branch_b_lidar_only_from_w13_b12_30ep_s001_laptop" / "models" / "weights_24",
    ),
    (
        "branch_c_w24",
        REPO_ROOT / "citrus_project" / "milestones" / "04_lightweight_vegetation_improvement" / "Marvel" / "runs" / "branch_c_rgb_edge_from_w13_b12_30ep_s001_laptop" / "models" / "weights_24",
    ),
    (
        "branch_f_w1",
        REPO_ROOT / "citrus_project" / "milestones" / "04_lightweight_vegetation_improvement" / "Marvel" / "runs" / "branch_f_full_frame_sanity_from_b24_b12_2ep_sky001_edge0005_laptop" / "models" / "weights_1",
    ),
]

IMAGE_EXTS = {".jpg", ".jpeg", ".png", ".bmp", ".webp", ".avif"}


def parse_args():
    parser = argparse.ArgumentParser(
        description="Run Lite-Mono checkpoints on external RGB images for qualitative sanity checks."
    )
    parser.add_argument(
        "--image_dir",
        type=Path,
        default=SCRIPT_DIR / "images",
        help="folder containing external images",
    )
    parser.add_argument(
        "--output_dir",
        type=Path,
        default=SCRIPT_DIR / "outputs",
        help="folder where panels and arrays are written",
    )
    parser.add_argument(
        "--model",
        action="append",
        default=[],
        help="extra/override model in name=weights_folder format; can be used multiple times",
    )
    parser.add_argument(
        "--only_custom_models",
        action="store_true",
        help="use only --model entries instead of the default model list",
    )
    parser.add_argument(
        "--network",
        type=str,
        default="lite-mono",
        choices=["lite-mono", "lite-mono-small", "lite-mono-tiny", "lite-mono-8m"],
        help="Lite-Mono encoder variant",
    )
    parser.add_argument("--no_cuda", action="store_true", help="force CPU inference")
    return parser.parse_args()


def parse_model_specs(args):
    models = [] if args.only_custom_models else list(DEFAULT_MODELS)
    for item in args.model:
        if "=" not in item:
            raise ValueError("--model must use name=weights_folder format, got {}".format(item))
        name, path = item.split("=", 1)
        models.append((name.strip(), Path(path).expanduser()))
    existing = []
    for name, path in models:
        path = path if path.is_absolute() else REPO_ROOT / path
        encoder_path = path / "encoder.pth"
        depth_path = path / "depth.pth"
        if encoder_path.exists() and depth_path.exists():
            existing.append((safe_name(name), path))
        else:
            print("Skipping missing model {}: {}".format(name, path))
    if not existing:
        raise RuntimeError("No usable model folders found.")
    return existing


def safe_name(name):
    return "".join(ch if ch.isalnum() or ch in "-_" else "_" for ch in name)


def find_images(image_dir):
    if not image_dir.exists():
        image_dir.mkdir(parents=True, exist_ok=True)
    paths = [p for p in sorted(image_dir.iterdir()) if p.suffix.lower() in IMAGE_EXTS]
    return paths


def load_model(weights_folder, model_name, device):
    encoder_path = weights_folder / "encoder.pth"
    decoder_path = weights_folder / "depth.pth"
    encoder_dict = torch.load(str(encoder_path), map_location=device)
    decoder_dict = torch.load(str(decoder_path), map_location=device)
    feed_height = int(encoder_dict["height"])
    feed_width = int(encoder_dict["width"])

    encoder = networks.LiteMono(model=model_name, height=feed_height, width=feed_width)
    encoder.load_state_dict({k: v for k, v in encoder_dict.items() if k in encoder.state_dict()})
    encoder.to(device).eval()

    decoder = networks.DepthDecoder(encoder.num_ch_enc, scales=range(3))
    decoder.load_state_dict({k: v for k, v in decoder_dict.items() if k in decoder.state_dict()})
    decoder.to(device).eval()
    return encoder, decoder, feed_height, feed_width


def predict_image(image_path, model_bundle, device):
    encoder, decoder, feed_height, feed_width = model_bundle
    image = pil.open(image_path).convert("RGB")
    original_width, original_height = image.size
    network_input = image.resize((feed_width, feed_height), pil.LANCZOS)
    tensor = transforms.ToTensor()(network_input).unsqueeze(0).to(device)

    with torch.no_grad():
        features = encoder(tensor)
        outputs = decoder(features)
        disp = outputs[("disp", 0)]
        _, depth = disp_to_depth(disp, 0.1, 100.0)
        disp_resized = torch.nn.functional.interpolate(
            disp, (original_height, original_width), mode="bilinear", align_corners=False
        )
        depth_resized = torch.nn.functional.interpolate(
            depth, (original_height, original_width), mode="bilinear", align_corners=False
        )
    return image, disp_resized.squeeze().cpu().numpy(), depth_resized.squeeze().cpu().numpy()


def colorize_nearness(disp):
    finite = np.isfinite(disp)
    if not np.any(finite):
        return np.zeros((*disp.shape, 3), dtype=np.uint8)
    values = disp[finite]
    vmin = float(np.percentile(values, 2))
    vmax = float(np.percentile(values, 98))
    if vmax <= vmin:
        vmax = float(values.max())
        vmin = float(values.min())
    if vmax <= vmin:
        vmax = vmin + 1e-6
    norm = np.clip((disp - vmin) / (vmax - vmin), 0, 1)
    return (cm.magma(norm)[:, :, :3] * 255).astype(np.uint8)


def save_panel(image_path, rgb, predictions, output_dir):
    count = len(predictions) + 1
    fig, axes = plt.subplots(1, count, figsize=(5 * count, 4), constrained_layout=True)
    if count == 1:
        axes = [axes]
    axes[0].imshow(rgb)
    axes[0].set_title("RGB")
    axes[0].axis("off")

    for ax, (name, heatmap, _depth) in zip(axes[1:], predictions):
        ax.imshow(heatmap)
        ax.set_title("{}\nnear bright / far dark".format(name))
        ax.axis("off")

    panel_path = output_dir / "{}_comparison_panel.png".format(image_path.stem)
    fig.savefig(panel_path, dpi=150)
    plt.close(fig)
    return panel_path


def main():
    args = parse_args()
    device = torch.device("cuda" if torch.cuda.is_available() and not args.no_cuda else "cpu")
    print("Using device:", device)

    models = parse_model_specs(args)
    images = find_images(args.image_dir)
    args.output_dir.mkdir(parents=True, exist_ok=True)

    if not images:
        print("No images found in {}".format(args.image_dir))
        print("Put .jpg/.jpeg/.png/.bmp/.webp files there, then rerun.")
        return

    print("Images:", len(images))
    print("Models:", ", ".join(name for name, _ in models))

    loaded = []
    for name, path in models:
        print("Loading {} from {}".format(name, path))
        loaded.append((name, load_model(path, args.network, device), path))

    summary_rows = ["image,model,weights_folder,depth_npy,heatmap_png"]
    for image_path in images:
        print("Processing", image_path.name)
        image_output_dir = args.output_dir / safe_name(image_path.stem)
        image_output_dir.mkdir(parents=True, exist_ok=True)
        predictions = []
        rgb_for_panel = None

        try:
            for name, bundle, weights_path in loaded:
                rgb, disp, depth = predict_image(image_path, bundle, device)
                rgb_for_panel = rgb
                heatmap = colorize_nearness(disp)
                heatmap_path = image_output_dir / "{}_nearbright_heatmap.png".format(name)
                depth_path = image_output_dir / "{}_approx_depth.npy".format(name)
                pil.fromarray(heatmap).save(heatmap_path)
                np.save(depth_path, depth.astype(np.float32))
                predictions.append((name, heatmap, depth))
                summary_rows.append(
                    "{},{},{},{},{}".format(
                        image_path.name,
                        name,
                        str(weights_path).replace(",", ";"),
                        str(depth_path.relative_to(args.output_dir)).replace(",", ";"),
                        str(heatmap_path.relative_to(args.output_dir)).replace(",", ";"),
                    )
                )
        except Exception as exc:
            print("  skipping unreadable/failed image {}: {}".format(image_path.name, exc))
            continue

        if not predictions:
            print("  no predictions created for", image_path.name)
            continue
        panel_path = save_panel(image_path, rgb_for_panel, predictions, image_output_dir)
        print("  panel:", panel_path)

    summary_path = args.output_dir / "external_image_sanity_summary.csv"
    summary_path.write_text("\n".join(summary_rows) + "\n", encoding="utf-8")
    print("Summary:", summary_path)
    print("Done.")


if __name__ == "__main__":
    main()
