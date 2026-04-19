from PIL import Image
import os

# 打开精灵图
sprite_sheet = Image.open('assets/sprites/buildings/sunnyside_buildings.png')
print(f"精灵图尺寸: {sprite_sheet.width}x{sprite_sheet.height}")

# 根据精灵图布局裁剪房屋
# 从大图来看，精灵图左上角区域有多个建筑
# 让我们尝试几个可能的位置

# 方案1: 尝试左上角的小房子
houses_to_try = [
    # (x, y, w, h, description)
    (16, 16, 32, 48, "左上角小房子1"),
    (64, 16, 32, 48, "左上角小房子2"),
    (112, 16, 32, 48, "左上角小房子3"),
    (16, 80, 48, 64, "左侧中等房子"),
    (80, 80, 32, 48, "左侧小房子"),
    (16, 160, 48, 64, "左下房子"),
]

# 保存所有尝试的房屋
for i, (x, y, w, h, desc) in enumerate(houses_to_try, 1):
    house = sprite_sheet.crop((x, y, x + w, y + h))
    output_path = f'assets/sprites/buildings/house_try_{i:02d}.png'
    house.save(output_path)
    print(f"  {i}. {desc}: ({x},{y}) 尺寸:{w}x{h} -> {output_path}")

# 保存一个完整精灵图用于在 Godot 中手动裁剪
sprite_sheet.save('assets/sprites/buildings/sunnyside_full_sheet.png')
print(f"\n✅ 已保存完整精灵图: assets/sprites/buildings/sunnyside_full_sheet.png")
print(f"\n建议：在 Godot 编辑器中打开 sunnyside_full_sheet.png，使用 Region 功能手动选择房屋区域")
print(f"或者告诉我你想要裁剪哪个位置的房屋，我可以调整坐标")
