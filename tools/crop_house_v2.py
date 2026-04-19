from PIL import Image

# 打开精灵图
sprite_sheet = Image.open('assets/sprites/buildings/sunnyside_buildings.png')
print(f"精灵图尺寸: {sprite_sheet.width}x{sprite_sheet.height}")

# 根据用户提供的截图分析房屋位置
# 从完整的精灵图来看，目标房屋（棕色墙壁+蓝色屋顶+烟囱）在左下区域
# 让我尝试几个可能的位置

# 尝试裁剪左下角的大房子
# 根据精灵图布局估算坐标
houses_to_try = [
    # (x, y, width, height, description)
    (16, 448, 96, 128, "左下角大房子（棕色墙+蓝屋顶+烟囱）"),
    (16, 304, 96, 128, "左侧中等房子"),
    (128, 448, 160, 128, "底部中间大房子"),
    (16, 144, 64, 96, "左上区域房子"),
]

# 裁剪并保存所有候选房屋
for i, (x, y, w, h, desc) in enumerate(houses_to_try, 1):
    # 确保不超出图片边界
    if x + w <= sprite_sheet.width and y + h <= sprite_sheet.height:
        house = sprite_sheet.crop((x, y, x + w, y + h))
        output_path = f'assets/sprites/buildings/house_try_{i:02d}.png'
        house.save(output_path)
        print(f"  {i}. {desc}")
        print(f"     坐标: ({x},{y}) 尺寸: {w}x{h}")
        print(f"     保存: {output_path}")
        print()

# 也保存完整精灵图用于参考
sprite_sheet.save('assets/sprites/buildings/sunnyside_full_sheet.png')
print("✅ 已保存完整精灵图: assets/sprites/buildings/sunnyside_full_sheet.png")
print("\n请查看这些裁剪的房屋文件，告诉我哪个是正确的，我会立即集成到游戏中！")
