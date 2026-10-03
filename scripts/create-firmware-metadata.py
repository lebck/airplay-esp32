#!/usr/bin/env python3
"""Write validated metadata for one firmware build artifact."""

import argparse
import json
import re
from pathlib import Path


ID_PATTERN = re.compile(r"[A-Za-z0-9][A-Za-z0-9._-]*")
VERSION_PATTERN = re.compile(
    r"\d+\.\d+\.\d+(-test-[A-Za-z0-9][A-Za-z0-9._-]*)?"
)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--variant", required=True)
    parser.add_argument("--chip", required=True)
    parser.add_argument("--layout", required=True)
    parser.add_argument("--version-file", type=Path, required=True)
    parser.add_argument("--asset", required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    for name in ("variant", "chip", "layout"):
        if not ID_PATTERN.fullmatch(getattr(args, name)):
            parser.error(f"{name} must be a simple alphanumeric identifier")
    if Path(args.asset).name != args.asset:
        parser.error("asset must be a filename, not a path")
    if not Path(args.asset).is_file():
        parser.error(f"OTA asset does not exist: {args.asset}")

    version = args.version_file.read_text(encoding="utf-8").strip()
    if not VERSION_PATTERN.fullmatch(version):
        parser.error(f"unsupported firmware version: {version}")

    metadata = {
        "variant": args.variant,
        "chip": args.chip,
        "layout": args.layout,
        "version": version,
        "asset": args.asset,
    }
    args.output.write_text(json.dumps(metadata) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
