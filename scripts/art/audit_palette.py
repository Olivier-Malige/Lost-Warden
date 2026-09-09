"""Report visible RGB colors outside the shared palette; never modify artwork."""

import argparse
from collections import Counter
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]


def read_palette(path):
    colors = set()
    for line in path.read_text().splitlines():
        fields = line.split()
        if len(fields) >= 3 and all(value.isdigit() for value in fields[:3]):
            colors.add(tuple(map(int, fields[:3])))
    if not colors:
        raise ValueError(f"No RGB colors found in {path}")
    return colors


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="*", type=Path, default=[ROOT / "assets/sprites"])
    parser.add_argument("--palette", type=Path, default=ROOT / "assets/palettes/lost_warden_64.gpl")
    args = parser.parse_args()
    palette = read_palette(args.palette)
    files = sorted({file for path in args.paths for file in
                    (path.rglob("*.png") if path.is_dir() else [path])})
    if not files:
        parser.error("No PNG files found")
    failures = 0
    for path in files:
        with Image.open(path) as source:
            pixels = source.convert("RGBA")
            colors = Counter()
            for count, rgba in pixels.getcolors(pixels.width * pixels.height):
                if rgba[3] > 0:
                    colors[rgba[:3]] += count
        outside = {rgb: count for rgb, count in colors.items() if rgb not in palette}
        if not outside:
            continue
        failures += 1
        total = sum(colors.values())
        count = sum(outside.values())
        print(f"{path}: {len(outside)}/{len(colors)} colors outside palette; "
              f"{count}/{total} visible pixels ({count / total:.1%})")
        most_common = sorted(outside, key=outside.get, reverse=True)[:12]
        print("  Most frequent: " + " ".join("#%02X%02X%02X" % rgb for rgb in most_common))
    print(f"{len(files)} PNGs checked; {failures} outside palette.")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
