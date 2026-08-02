#!/usr/bin/env python3
"""Fail closed when bundled content lacks approved redistribution metadata."""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from datetime import date
from pathlib import Path

CONTENT_EXTENSIONS = {".json", ".usfm", ".usfx", ".xml", ".txt", ".mp3", ".m4a"}
CONTENT_DIRECTORIES = (
    "assets/bible",
    "assets/devotionals",
    "assets/plans",
    "assets/hymns",
    "assets/audio",
)
REQUIRED_FIELDS = {
    "id",
    "feature",
    "path",
    "source",
    "license",
    "attribution",
    "commercialUse",
    "redistribution",
    "approved",
    "sha256",
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def validate(root: Path, manifest_path: Path) -> list[str]:
    errors: list[str] = []
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if manifest.get("schemaVersion") != 1:
        errors.append("content manifest schemaVersion must be 1")

    entries = manifest.get("assets")
    if not isinstance(entries, list):
        return errors + ["content manifest assets must be a list"]

    approved_paths: set[str] = set()
    ids: set[str] = set()
    for index, entry in enumerate(entries):
        label = f"assets[{index}]"
        if not isinstance(entry, dict):
            errors.append(f"{label} must be an object")
            continue
        missing = REQUIRED_FIELDS.difference(entry)
        if missing:
            errors.append(f"{label} missing fields: {', '.join(sorted(missing))}")
            continue
        if entry["id"] in ids:
            errors.append(f"duplicate content id: {entry['id']}")
        ids.add(entry["id"])

        relative = Path(entry["path"])
        if relative.is_absolute() or ".." in relative.parts:
            errors.append(f"{label} has unsafe path: {relative}")
            continue
        normalized = relative.as_posix()
        asset = root / relative
        if not asset.is_file():
            errors.append(f"manifest asset does not exist: {normalized}")
            continue
        if not entry["approved"] or not entry["redistribution"]:
            errors.append(f"manifest asset is not approved for redistribution: {normalized}")
        if not entry["commercialUse"]:
            errors.append(f"manifest asset is not approved for app-store distribution: {normalized}")
        expires_at = entry.get("expiresAt")
        if expires_at and date.fromisoformat(expires_at) < date.today():
            errors.append(f"content rights expired for: {normalized}")
        actual_hash = sha256(asset)
        if actual_hash.lower() != str(entry["sha256"]).lower():
            errors.append(f"checksum mismatch for: {normalized}")
        approved_paths.add(normalized)

    bundled_paths: set[str] = set()
    for directory in CONTENT_DIRECTORIES:
        content_root = root / directory
        if not content_root.exists():
            continue
        bundled_paths.update(
            path.relative_to(root).as_posix()
            for path in content_root.rglob("*")
            if path.is_file() and path.suffix.lower() in CONTENT_EXTENSIONS
        )

    for path in sorted(bundled_paths - approved_paths):
        errors.append(f"bundled content has no approved manifest entry: {path}")
    for path in sorted(approved_paths - bundled_paths):
        errors.append(f"manifest path is outside known content directories: {path}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument(
        "--manifest",
        type=Path,
        default=Path("assets/content_manifest.json"),
    )
    args = parser.parse_args()
    root = args.root.resolve()
    manifest = args.manifest
    if not manifest.is_absolute():
        manifest = root / manifest
    try:
        errors = validate(root, manifest)
    except (OSError, ValueError, json.JSONDecodeError) as error:
        errors = [f"content validation failed: {error}"]
    if errors:
        print("\n".join(f"ERROR: {error}" for error in errors), file=sys.stderr)
        return 1
    print("Content manifest is valid.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
