from __future__ import annotations

import argparse
import colorsys
from pathlib import Path

from PIL import Image, ImageDraw


def parse_palette_txt(path: Path) -> list[tuple[int, int, int]]:
    colors: list[tuple[int, int, int]] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        # format: "01 #484848 (72, 72, 72)"
        if "(" not in line or ")" not in line:
            continue
        rgb_part = line[line.index("(") + 1 : line.index(")")]
        r, g, b = [int(x.strip()) for x in rgb_part.split(",")]
        colors.append((r, g, b))
    return colors


def rgb_to_hex(rgb: tuple[int, int, int]) -> str:
    return "#{:02X}{:02X}{:02X}".format(*rgb)


def clamp_byte(x: float) -> int:
    return max(0, min(255, int(round(x))))


def make_neutral(colors: list[tuple[int, int, int]]) -> list[tuple[int, int, int]]:
    # Keep hue/saturation; snap only lightness to a stable ladder.
    ladder = [0.14, 0.22, 0.30, 0.38, 0.46, 0.54, 0.62, 0.70, 0.78]
    out: list[tuple[int, int, int]] = []
    for r, g, b in colors:
        h, l, s = colorsys.rgb_to_hls(r / 255.0, g / 255.0, b / 255.0)
        target_l = min(ladder, key=lambda x: abs(x - l))
        nr, ng, nb = colorsys.hls_to_rgb(h, target_l, s)
        out.append((clamp_byte(nr * 255), clamp_byte(ng * 255), clamp_byte(nb * 255)))
    return out


def make_warm(colors: list[tuple[int, int, int]]) -> list[tuple[int, int, int]]:
    out: list[tuple[int, int, int]] = []
    for r, g, b in colors:
        h, l, s = colorsys.rgb_to_hls(r / 255.0, g / 255.0, b / 255.0)
        # Shift hue slightly toward warm tones and gently raise lightness.
        h = (h - 0.02) % 1.0
        l = min(1.0, l + 0.02)
        nr, ng, nb = colorsys.hls_to_rgb(h, l, s)
        out.append((clamp_byte(nr * 255), clamp_byte(ng * 255), clamp_byte(nb * 255)))
    return out


def make_contrast_plus(colors: list[tuple[int, int, int]]) -> list[tuple[int, int, int]]:
    out: list[tuple[int, int, int]] = []
    for r, g, b in colors:
        h, l, s = colorsys.rgb_to_hls(r / 255.0, g / 255.0, b / 255.0)
        if l < 0.45:
            l = max(0.0, l - 0.06)
        elif l > 0.65:
            l = min(1.0, l + 0.05)
        nr, ng, nb = colorsys.hls_to_rgb(h, l, s)
        out.append((clamp_byte(nr * 255), clamp_byte(ng * 255), clamp_byte(nb * 255)))
    return out


def write_preview_png(outdir: Path, name: str, colors: list[tuple[int, int, int]]) -> None:
    cols = 12
    cell = 32
    rows = (len(colors) + cols - 1) // cols
    img = Image.new("RGB", (cols * cell, rows * cell), (20, 20, 20))
    draw = ImageDraw.Draw(img)
    for i, c in enumerate(colors):
        x = (i % cols) * cell
        y = (i // cols) * cell
        draw.rectangle((x, y, x + cell - 1, y + cell - 1), fill=c)
    img.save(outdir / f"{name}.png")


def write_outputs(outdir: Path, name: str, colors: list[tuple[int, int, int]]) -> None:
    outdir.mkdir(parents=True, exist_ok=True)
    txt_path = outdir / f"{name}.txt"
    gpl_path = outdir / f"{name}.gpl"

    txt_lines = [f"{i+1:02d} {rgb_to_hex(c)} {c}" for i, c in enumerate(colors)]
    txt_path.write_text("\n".join(txt_lines) + "\n", encoding="utf-8")

    gpl_lines = ["GIMP Palette", f"Name: {name}", "Columns: 12", "#"]
    for c in colors:
        gpl_lines.append(f"{c[0]:3d} {c[1]:3d} {c[2]:3d} {rgb_to_hex(c)}")
    gpl_path.write_text("\n".join(gpl_lines) + "\n", encoding="utf-8")

    print(txt_path)
    print(gpl_path)


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate palette variants")
    parser.add_argument("--input", required=True, help="Input palette txt path")
    parser.add_argument("--outdir", required=True)
    parser.add_argument("--name", required=True)
    parser.add_argument("--variant", choices=["neutral", "warm", "contrast_plus"], default="neutral")
    args = parser.parse_args()

    colors = parse_palette_txt(Path(args.input))
    if args.variant == "neutral":
        out = make_neutral(colors)
    elif args.variant == "warm":
        out = make_warm(colors)
    elif args.variant == "contrast_plus":
        out = make_contrast_plus(colors)
    else:
        raise ValueError(f"Unsupported variant: {args.variant}")

    # Keep order, remove accidental duplicates introduced by lightness snapping.
    deduped: list[tuple[int, int, int]] = []
    for c in out:
        if c not in deduped:
            deduped.append(c)

    outdir = Path(args.outdir)
    write_outputs(outdir, args.name, deduped)
    write_preview_png(outdir, args.name, deduped)


if __name__ == "__main__":
    main()
