"""
Generate farm soil texture for TileMap
Creates tilled soil tile sprite
"""

import os
from PIL import Image, ImageDraw

def create_soil_texture(output_dir="assets/sprites/environment/farm"):
    """Generate tilled soil texture"""

    os.makedirs(output_dir, exist_ok=True)

    # Tilled soil tile (64x64)
    img = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Base soil color
    soil_color = (101, 67, 33)  # Brown soil

    # Fill with soil
    draw.rectangle([0, 0, 63, 63], fill=soil_color)

    # Add furrow lines (tilled soil pattern)
    furrow_color = (80, 50, 25)  # Darker brown
    for y in range(8, 64, 12):
        draw.line([(0, y), (63, y)], fill=furrow_color, width=2)

    # Add some texture variation
    for x in range(0, 64, 4):
        for y in range(0, 64, 4):
            if (x + y) % 16 == 0:
                draw.point((x, y), fill=(120, 80, 40))

    # Save
    filepath = os.path.join(output_dir, "tilled_soil.png")
    img.save(filepath)
    print(f"Created: {filepath}")

    # Also create untilled grass tile
    grass_img = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
    grass_draw = ImageDraw.Draw(grass_img)

    # Base grass color
    grass_color = (34, 139, 34)  # Forest green
    grass_draw.rectangle([0, 0, 63, 63], fill=grass_color)

    # Add grass texture
    for i in range(100):
        x = (i * 7) % 64
        y = (i * 11) % 64
        grass_draw.point((x, y), fill=(50, 160, 50))

    grass_filepath = os.path.join(output_dir, "grass_tile.png")
    grass_img.save(grass_filepath)
    print(f"Created: {grass_filepath}")

    print(f"\nGenerated farm tiles in: {output_dir}")

if __name__ == "__main__":
    create_soil_texture()
