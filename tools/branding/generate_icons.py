#!/usr/bin/env python3
"""Generate all BiblePulse platform icons from one approved 1024px source."""

from __future__ import annotations

import json
import argparse
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SOURCE = ROOT / "assets" / "biblepulse_app_icon.png"


def save(image: Image.Image, path: Path, size: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.resize((size, size), Image.Resampling.LANCZOS).save(path)


def generate_asset_catalog(image: Image.Image, catalog: Path) -> None:
    content = json.loads((catalog / "Contents.json").read_text(encoding="utf-8"))
    for entry in content["images"]:
        filename = entry.get("filename")
        if not filename:
            continue
        points = float(entry["size"].split("x")[0])
        scale = int(entry["scale"].removesuffix("x"))
        save(image, catalog / filename, round(points * scale))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    args = parser.parse_args()
    image = Image.open(args.source).convert("RGB")
    if image.size != (1024, 1024):
        raise ValueError("Icon source must be exactly 1024x1024")
    save(image, DEFAULT_SOURCE, 1024)

    android = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for density, size in android.items():
        save(
            image,
            ROOT / "android/app/src/main/res" / density / "ic_launcher.png",
            size,
        )

    generate_asset_catalog(
        image, ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    )
    generate_asset_catalog(
        image, ROOT / "macos/Runner/Assets.xcassets/AppIcon.appiconset"
    )

    for name, size in {
        "Icon-192.png": 192,
        "Icon-512.png": 512,
        "Icon-maskable-192.png": 192,
        "Icon-maskable-512.png": 512,
    }.items():
        save(image, ROOT / "web/icons" / name, size)
    save(image, ROOT / "web/favicon.png", 32)
    save(image, ROOT / "linux/data/biblepulse.png", 512)

    windows_icon = ROOT / "windows/runner/resources/app_icon.ico"
    windows_icon.parent.mkdir(parents=True, exist_ok=True)
    image.save(
        windows_icon,
        format="ICO",
        sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (256, 256)],
    )
    print("Generated BiblePulse platform icons.")


if __name__ == "__main__":
    main()
