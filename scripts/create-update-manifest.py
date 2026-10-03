#!/usr/bin/env python3
"""Build a release update manifest from firmware artifact sidecars."""

import argparse
import hashlib
import json
import re
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--version", required=True)
    parser.add_argument("--directory", type=Path, required=True)
    args = parser.parse_args()

    if not re.fullmatch(r"\d+\.\d+\.\d+", args.version):
        parser.error("version must use MAJOR.MINOR.PATCH")

    records = []
    seen = set()
    for metadata_path in sorted(args.directory.glob("airplay2-receiver-*.json")):
        metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
        variant = metadata["variant"]
        if variant in seen:
            raise SystemExit(f"duplicate firmware variant in artifacts: {variant}")
        seen.add(variant)
        if metadata.get("version") != args.version:
            raise SystemExit(f"version mismatch in {metadata_path.name}")

        asset = args.directory / metadata["asset"]
        if not asset.is_file():
            raise SystemExit(f"missing OTA asset: {metadata['asset']}")
        data = asset.read_bytes()
        if not data:
            raise SystemExit(f"empty OTA asset: {metadata['asset']}")
        records.append({
            "variant": variant,
            "chip": metadata["chip"],
            "layout": metadata["layout"],
            "asset": asset.name,
            "size": len(data),
            "sha256": hashlib.sha256(data).hexdigest(),
        })

    if not records:
        raise SystemExit("no OTA artifact metadata found")
    output = {"schema_version": 1, "version": args.version, "images": records}
    (args.directory / "update-manifest.json").write_text(
        json.dumps(output, indent=2) + "\n", encoding="utf-8"
    )


if __name__ == "__main__":
    main()
