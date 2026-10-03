#!/usr/bin/env python3
"""Select the previous published stable release on the current tag's history."""

import json
import re
import subprocess
import sys


def version(tag):
    match = re.fullmatch(r"v(\d+)\.(\d+)\.(\d+)", tag)
    return tuple(map(int, match.groups())) if match else None


def release_range(current, pages):
    current_version = version(current)
    if current_version is None:
        raise ValueError(f"Invalid release tag: {current}")
    candidates = []
    for page in pages:
        for release in page:
            tag = release["tag_name"]
            tag_version = version(tag)
            if (release["draft"] or release["prerelease"]
                    or not release.get("published_at") or tag_version is None
                    or tag_version >= current_version):
                continue
            # Tags without published releases never form a changelog boundary.
            result = subprocess.run(
                ["git", "merge-base", "--is-ancestor", tag, current],
                check=False, capture_output=True,
            )
            if result.returncode == 0:
                candidates.append((tag_version, tag))
            elif result.returncode != 1:
                raise RuntimeError(result.stderr.decode().strip())
    if candidates:
        return f"{max(candidates)[1]}..{current}"
    return subprocess.check_output(
        ["git", "rev-parse", f"{current}^{{commit}}"], text=True
    ).strip()


if __name__ == "__main__":
    with open(sys.argv[2], encoding="utf-8") as releases:
        print(release_range(sys.argv[1], json.load(releases)))
