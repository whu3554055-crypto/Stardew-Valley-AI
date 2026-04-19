from PIL import Image
import os

# 打开精灵图
sprite_sheet = Image.open('assets/sprites/buildings/sunnyside_buildings.png')
print(f"精灵图尺寸: {sprite_sheet.width}x{sprite_sheet.height}")

# 根据用户提供的房屋截图特征：
# - 绿色/蓝绿色屋顶
# - 棕色木质墙壁
# - 右侧有烟囱
# - 上方有窗户
# - 底部有门
# - 右侧还有一个小窗户
# 这应该是一个完整的独立房屋

# 基于640x640的精灵图，尝试常见位置
# Sunnyside World的建筑通常在左上区域，以48x48或64x64的网格排列

candidates = [
    # 左上区域（最常见的位置）
    (0, 0, 64, 80, "位置A1 - 左上角"),
    (64, 0, 64, 80, "位置A2 - 左上中"),
    (128, 0, 64, 80, "位置A3 - 左上右"),
    (0, 80, 64, 96, "位置B1 - 左侧"),
    (64, 80, 64, 96, "位置B2 - 左中"),
    (128, 80, 64, 96, "位置B3 - 左右"),
    
    # 中间区域
    (0, 176, 80, 96, "位置C1 - 中左"),
    (80, 176, 96, 96, "位置C2 - 中心"),
    (176, 176, 96, 96, "位置C3 - 中右"),
    
    # 下方区域（大建筑）
    (0, 272, 112, 128, "位置D1 - 下左大"),
    (112, 272, 160, 128, "位置D2 - 下中大"),
    (0, 400, 96, 128, "位置E1 - 底部左"),
]

# 创建输出目录
output_dir = 'assets/sprites/buildings/candidates'
os.makedirs(output_dir, exist_ok=True)

print("\n正在裁剪候选房屋...")
for i, (x, y, w, h, desc) in enumerate(candidates, 1):
    if x + w <= sprite_sheet.width and y + h <= sprite_sheet.height:
        house = sprite_sheet.crop((x, y, x + w, y + h))
        output_path = os.path.join(output_dir, f'house_{i:02d}.png')
        house.save(output_path)
        print(f"  {i:2d}. {desc}: ({x:3d},{y:3d}) {w:3d}x{h:3d} -> {output_path}")

print(f"\n✅ 已生成 {len(candidates)} 个候选房屋")
print(f"目录: {output_dir}/")
print("\n请在 Godot 中打开这些文件，或截图给我看哪个是正确的！")
print("找到后告诉我编号，我会立即集成到游戏中。")
