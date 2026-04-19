from PIL import Image
import os

# 打开精灵图
sprite_sheet = Image.open('assets/sprites/buildings/sunnyside_buildings.png')
print(f"精灵图尺寸: {sprite_sheet.width}x{sprite_sheet.height}")

# 根据用户提供的房屋截图分析特征：
# - 棕色木质墙壁
# - 蓝绿色屋顶
# - 有一个烟囱在右侧
# - 有窗户
# - 门在底部中间
# 估算尺寸约 32x40 像素

# 根据精灵图布局，这个房屋应该在左侧区域
# 让我尝试几个可能的位置

houses_to_try = [
    # 左侧的建筑（根据精灵图截图分析）
    (16, 16, 32, 48, "左上小建筑1"),
    (64, 16, 32, 64, "左上小建筑2（可能是目标）"),
    (112, 16, 32, 48, "左上小建筑3"),
    (16, 80, 48, 80, "左侧中建筑1"),
    (80, 80, 32, 48, "左侧中建筑2"),
    (16, 176, 64, 64, "左侧大建筑1"),
    (96, 176, 96, 80, "左侧大建筑2（可能是目标）"),
]

# 创建输出目录
output_dir = 'assets/sprites/buildings/candidates'
os.makedirs(output_dir, exist_ok=True)

# 裁剪所有候选房屋
for i, (x, y, w, h, desc) in enumerate(houses_to_try, 1):
    if x + w <= sprite_sheet.width and y + h <= sprite_sheet.height:
        house = sprite_sheet.crop((x, y, x + w, y + h))
        output_path = os.path.join(output_dir, f'house_try_{i:02d}.png')
        house.save(output_path)
        print(f"  {i}. {desc}: ({x},{y}) {w}x{h} -> {output_path}")

print(f"\n✅ 已生成 {len(houses_to_try)} 个候选房屋")
print(f"请查看: {output_dir}/ 目录")
print(f"找到正确的房屋后告诉我编号，我会立即集成到游戏中！")
