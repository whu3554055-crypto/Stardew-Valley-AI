"""Generate 32x32 placeholder PNGs for silver ore / silver bar (A3 presentation)."""
from __future__ import annotations

import random
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "sprites" / "items" / "resources"


def main() -> None:
	OUT.mkdir(parents=True, exist_ok=True)
	random.seed(42)
	ore = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
	d = ImageDraw.Draw(ore)
	d.ellipse((3, 3, 29, 29), fill=(118, 124, 138, 255), outline=(72, 78, 92, 255))
	for _ in range(90):
		x, y = random.randint(5, 26), random.randint(5, 26)
		v = random.randint(175, 220)
		ore.putpixel((x, y), (v, v + 2, v + 6, 255))
	ore.save(OUT / "silver_ore.png")

	bar = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
	db = ImageDraw.Draw(bar)
	db.rounded_rectangle((4, 11, 28, 21), radius=3, fill=(168, 172, 182, 255), outline=(96, 100, 112, 255))
	for x in range(6, 26):
		g = 155 + int(40 * (x - 6) / 20)
		for y in range(12, 20):
			bar.putpixel((x, y), (g, g + 1, g + 3, 255))
	bar.save(OUT / "silver_bar.png")
	print("Wrote", OUT / "silver_ore.png", OUT / "silver_bar.png")


if __name__ == "__main__":
	main()
