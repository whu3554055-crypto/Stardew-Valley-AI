from __future__ import annotations

import argparse
import zipfile
from io import BytesIO
from pathlib import Path

from PIL import Image


def rgb_to_hex(rgb: tuple[int, int, int]) -> str:
    return "#{:02X}{:02X}{:02X}".format(*rgb)


def main() -> None:
    parser = argparse.ArgumentParser(description="Extract palette from image inside zip")
    parser.add_argument("--zip", dest="zip_path", required=True)
    parser.add_argument("--inner", dest="inner_path", required=True)
    parser.add_argument("--outdir", required=True)
    parser.add_argument("--name", default="palette_n2_1")
    parser.add_argument("--colors", type=int, default=36)
    args = parser.parse_args()

    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    with zipfile.ZipFile(args.zip_path, "r") as zf:
        with zf.open(args.inner_path) as fp:
            data = fp.read()

    img = Image.open(BytesIO(data)).convert("RGBA")

    # Ignore fully transparent pixels.
    solid = [px[:3] for px in img.getdata() if px[3] > 0]
    solid_img = Image.new("RGB", (len(solid), 1))
    solid_img.putdata(solid)

    quantized = solid_img.quantize(colors=args.colors, method=Image.Quantize.FASTOCTREE)
    palette = quantized.getpalette()
    used = quantized.getcolors() or []
    # Sort by frequency descending.
    used_sorted = sorted(used, key=lambda x: x[0], reverse=True)

    colors: list[tuple[int, int, int]] = []
    for _, idx in used_sorted:
        base = idx * 3
        rgb = (palette[base], palette[base + 1], palette[base + 2])
        if rgb not in colors:
            colors.append(rgb)

    txt_path = outdir / f"{args.name}.txt"
    gpl_path = outdir / f"{args.name}.gpl"

    txt_lines = [f"{i+1:02d} {rgb_to_hex(c)} {c}" for i, c in enumerate(colors)]
    txt_path.write_text("\n".join(txt_lines) + "\n", encoding="utf-8")

    gpl_lines = [
        "GIMP Palette",
        f"Name: {args.name}",
        "Columns: 12",
        "#",
    ]
    for c in colors:
        gpl_lines.append(f"{c[0]:3d} {c[1]:3d} {c[2]:3d} {rgb_to_hex(c)}")
    gpl_path.write_text("\n".join(gpl_lines) + "\n", encoding="utf-8")

    print(f"Wrote {len(colors)} colors")
    print(txt_path)
    print(gpl_path)


if __name__ == "__main__":
    main()
