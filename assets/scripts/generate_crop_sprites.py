"""
Generate crop sprite placeholders for farming system
Creates growth stage sprites for all crop types
"""

import os
from PIL import Image, ImageDraw

def create_crop_sprites(output_dir="assets/sprites/crops"):
    """Generate crop sprites for all growth stages"""

    # Crop definitions with colors for each stage
    crops = {
        "parsnip": {
            "name": "防风草",
            "stages": 4,
            "colors": [
                (139, 69, 19),    # Stage 0: Seed (brown)
                (144, 238, 144),  # Stage 1: Sprout (light green)
                (34, 139, 34),    # Stage 2: Growing (green)
                (0, 100, 0),      # Stage 3: Mature (dark green with white root)
            ]
        },
        "potato": {
            "name": "土豆",
            "stages": 5,
            "colors": [
                (139, 69, 19),    # Stage 0: Seed
                (144, 238, 144),  # Stage 1: Sprout
                (34, 139, 34),    # Stage 2: Growing
                (0, 128, 0),      # Stage 3: Maturing
                (0, 100, 0),      # Stage 4: Mature
            ]
        },
        "cauliflower": {
            "name": "花椰菜",
            "stages": 6,
            "colors": [
                (139, 69, 19),    # Stage 0: Seed
                (144, 238, 144),  # Stage 1: Sprout
                (34, 139, 34),    # Stage 2: Small plant
                (0, 128, 0),      # Stage 3: Growing
                (0, 100, 0),      # Stage 4: Large plant
                (255, 255, 240),  # Stage 5: Mature (white head)
            ]
        },
        "corn": {
            "name": "玉米",
            "stages": 7,
            "colors": [
                (139, 69, 19),    # Stage 0: Seed
                (144, 238, 144),  # Stage 1: Sprout
                (34, 139, 34),    # Stage 2: Small stalk
                (0, 128, 0),      # Stage 3: Growing stalk
                (0, 100, 0),      # Stage 4: Tall stalk
                (34, 139, 34),    # Stage 5: With leaves
                (255, 215, 0),    # Stage 6: Mature (golden corn)
            ]
        }
    }

    os.makedirs(output_dir, exist_ok=True)

    for crop_id, crop_data in crops.items():
        print(f"Generating {crop_data['name']} sprites...")

        for stage in range(crop_data["stages"]):
            # Create sprite
            img_size = 64
            img = Image.new('RGBA', (img_size, img_size), (0, 0, 0, 0))
            draw = ImageDraw.Draw(img)

            color = crop_data["colors"][stage]

            if stage == 0:
                # Seed - small brown dot
                cx, cy = img_size // 2, img_size - 15
                draw.ellipse([cx-4, cy-4, cx+4, cy+4], fill=color)
            elif stage == 1:
                # Sprout - tiny green shoot
                cx, cy = img_size // 2, img_size - 20
                draw.line([(cx, cy+10), (cx, cy)], fill=color, width=2)
                draw.ellipse([cx-3, cy-3, cx+3, cy+3], fill=color)
            elif stage < crop_data["stages"] - 1:
                # Growing plant - increasing size
                plant_height = 15 + (stage * 8)
                plant_width = 8 + (stage * 4)
                cx = img_size // 2
                base_y = img_size - 10

                # Stem
                draw.rectangle(
                    [cx-2, base_y-plant_height, cx+2, base_y],
                    fill=color
                )

                # Leaves
                leaf_size = plant_width // 2
                draw.ellipse(
                    [cx-leaf_size-5, base_y-plant_height+5,
                     cx-5, base_y-plant_height+5+leaf_size*2],
                    fill=color
                )
                draw.ellipse(
                    [cx+5, base_y-plant_height+8,
                     cx+leaf_size+5, base_y-plant_height+8+leaf_size*2],
                    fill=color
                )
            else:
                # Mature crop
                cx = img_size // 2
                base_y = img_size - 10

                if crop_id == "parsnip":
                    # White root vegetable with green top
                    draw.rectangle([cx-3, base_y-35, cx+3, base_y-10], fill=(0, 100, 0))
                    draw.ellipse([cx-8, base_y-15, cx+8, base_y], fill=(255, 250, 205))
                    # Green leaves on top
                    draw.ellipse([cx-10, base_y-40, cx-2, base_y-30], fill=(0, 128, 0))
                    draw.ellipse([cx+2, base_y-40, cx+10, base_y-30], fill=(0, 128, 0))

                elif crop_id == "potato":
                    # Brown tuber underground, green plant above
                    draw.rectangle([cx-3, base_y-30, cx+3, base_y-10], fill=(0, 100, 0))
                    draw.ellipse([cx-10, base_y-12, cx+10, base_y-2], fill=(139, 69, 19))
                    draw.ellipse([cx-12, base_y-35, cx-4, base_y-25], fill=(0, 128, 0))
                    draw.ellipse([cx+4, base_y-35, cx+12, base_y-25], fill=(0, 128, 0))

                elif crop_id == "cauliflower":
                    # Large white head with green leaves
                    draw.rectangle([cx-4, base_y-40, cx+4, base_y-15], fill=(0, 100, 0))
                    draw.ellipse([cx-15, base_y-45, cx+15, base_y-15], fill=(255, 255, 240))
                    draw.ellipse([cx-15, base_y-20, cx-5, base_y-10], fill=(0, 128, 0))
                    draw.ellipse([cx+5, base_y-20, cx+15, base_y-10], fill=(0, 128, 0))

                elif crop_id == "corn":
                    # Tall stalk with golden corn cob
                    draw.rectangle([cx-3, base_y-50, cx+3, base_y-10], fill=(0, 100, 0))
                    # Corn cob
                    draw.ellipse([cx-6, base_y-35, cx+6, base_y-15], fill=(255, 215, 0))
                    # Long leaves
                    draw.ellipse([cx-15, base_y-45, cx-5, base_y-30], fill=(0, 128, 0))
                    draw.ellipse([cx+5, base_y-40, cx+15, base_y-25], fill=(0, 128, 0))

            # Save sprite
            filename = f"{crop_id}_stage_{stage}.png"
            filepath = os.path.join(output_dir, filename)
            img.save(filepath)
            print(f"  Created: {filename}")

    print(f"\nGenerated {sum(c['stages'] for c in crops.values())} crop sprites")
    print(f"Output directory: {output_dir}")

if __name__ == "__main__":
    create_crop_sprites()
