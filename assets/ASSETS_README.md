# 游戏素材需求清单

本文档列出赛博小镇项目所需的所有游戏素材。

## 📁 目录结构

```
assets/
├── sprites/              # 精灵图
│   ├── characters/       # 角色精灵
│   ├── items/           # 物品精灵
│   └── ui/              # UI 元素
├── tilemaps/            # 瓦片地图
│   ├── terrain/         # 地形瓦片
│   └── buildings/       # 建筑瓦片
├── audio/               # 音频文件
│   ├── ambience/        # 环境音
│   ├── emotions/        # 情感音效
│   ├── activities/      # 活动音效
│   ├── locations/       # 地点音效
│   └── ui/              # UI 音效
└── config/              # 配置文件
    └── npcs/            # NPC 配置
```

---

## 🎨 视觉素材需求

### 1. 角色精灵 (sprites/characters/)

**格式**: PNG, 64x64 像素/帧, 4方向 x 4动作
**必需角色**:

| 角色 | 文件名 | 描述 | 状态 |
|------|--------|------|------|
| 玩家 | player.png | 主角，4方向行走动画 | ⬜ 待添加 |
| Pierre | npc_pierre.png | 杂货店老板 | ⬜ 待添加 |
| Abigail | npc_abigail.png | 冒险少女 | ⬜ 待添加 |
| Lewis | npc_lewis.png | 镇长 | ⬜ 待添加 |
| Robin | npc_robin.png | 木匠 | ⬜ 待添加 |
| Penny | npc_penny.png | 教师 | ⬜ 待添加 |
| Sebastian | npc_sebastian.png | 程序员 | ⬜ 待添加 |
| Haley | npc_haley.png | 摄影师 | ⬜ 待添加 |
| Alex | npc_alex.png | 运动员 | ⬜ 待添加 |
| Maru | npc_maru.png | 科学家 | ⬜ 待添加 |

**动画帧**:
- idle (待机): 4帧
- walk (行走): 8帧
- talk (对话): 4帧
- work (工作): 6帧

---

### 2. 物品精灵 (sprites/items/)

**格式**: PNG, 32x32 像素

**分类**:

#### 农作物 (crops/)
- parsnip.png - 防风草
- potato.png - 土豆
- carrot.png - 胡萝卜
- tomato.png - 番茄
- corn.png - 玉米
- pumpkin.png - 南瓜

#### 工具 (tools/)
- hoe.png - 锄头
- watering_can.png - 洒水壶
- scythe.png - 镰刀
- axe.png - 斧头

#### 资源 (resources/)
- wood.png - 木材
- stone.png - 石头
- iron_ore.png - 铁矿石
- gold_ore.png - 金矿石

#### 消耗品 (consumables/)
- health_potion.png - 生命药水
- energy_drink.png - 能量饮料
- bread.png - 面包
- salad.png - 沙拉

---

### 3. UI 元素 (sprites/ui/)

**对话框**:
- dialogue_box.png - 对话背景框 (800x200)
- name_tag.png - 名字标签 (200x40)
- emotion_icon_*.png - 情感图标 (64x64): happy, sad, angry, excited, neutral

**背包界面**:
- inventory_slot.png - 物品槽 (64x64)
- inventory_bg.png - 背包背景 (600x400)
- item_count_bg.png - 数量背景 (32x32)

**商店界面**:
- shop_panel.png - 商店面板 (700x500)
- buy_button.png - 购买按钮
- sell_button.png - 出售按钮
- price_tag.png - 价格标签

**任务界面**:
- quest_log.png - 任务日志背景
- quest_marker.png - 任务标记
- quest_complete.png - 任务完成图标

**其他 UI**:
- health_bar.png - 血条
- energy_bar.png - 能量条
- clock.png - 时钟图标
- calendar.png - 日历图标
- minimap_frame.png - 小地图边框

---

### 4. 地形瓦片 (tilemaps/terrain/)

**格式**: PNG, 瓦片集 16x16 像素

- grass.png - 草地瓦片集 (256x256)
- dirt.png - 泥土瓦片集
- water.png - 水体瓦片集（带动画）
- sand.png - 沙滩瓦片集
- snow.png - 雪地瓦片集
- flowers.png - 花卉装饰瓦片
- rocks.png - 岩石瓦片
- trees.png - 树木瓦片集

---

### 5. 建筑瓦片 (tilemaps/buildings/)

- pierre_shop.png - Pierre 杂货店
- town_hall.png - 市政厅
- carpenter_shop.png - 木匠铺
- hospital.png - 医院
- saloon.png - 酒吧
- blacksmith.png - 铁匠铺

---

## 🔊 音频素材需求

### 1. 环境音 (audio/ambience/)

**格式**: OGG, 立体声, 循环播放

| 文件名 | 描述 | 时长 | 状态 |
|--------|------|------|------|
| spring.ogg | 春季环境音（鸟鸣、微风） | 60s | ⬜ 待添加 |
| summer.ogg | 夏季环境音（蝉鸣、热浪） | 60s | ⬜ 待添加 |
| fall.ogg | 秋季环境音（落叶、凉风） | 60s | ⬜ 待添加 |
| winter.ogg | 冬季环境音（寒风、雪落） | 60s | ⬜ 待添加 |
| rain.ogg | 雨声 | 30s | ⬜ 待添加 |
| storm.ogg | 暴风雨 | 45s | ⬜ 待添加 |
| night.ogg | 夜晚环境音（蟋蟀） | 60s | ⬜ 待添加 |

---

### 2. 情感音效 (audio/emotions/)

**格式**: WAV, 单声道, 短音效 (<2s)

- happy.wav - 开心音效（轻快铃声）
- sad.wav - 悲伤音效（低沉音调）
- excited.wav - 兴奋音效（高音调）
- angry.wav - 生气音效（重低音）
- surprised.wav - 惊讶音效（短促高音）
- neutral.wav - 中性音效（轻微提示音）

---

### 3. 活动音效 (audio/activities/)

- farming_till.wav - 耕地音效
- farming_plant.wav - 种植音效
- farming_water.wav - 浇水音效
- farming_harvest.wav - 收获音效
- walking_grass.wav - 草地脚步声
- walking_wood.wav - 木板脚步声
- walking_stone.wav - 石板脚步声
- chop_wood.wav - 砍树音效
- mine_pickaxe.wav - 挖矿音效
- fish_cast.wav - 钓鱼抛竿音效
- fish_bite.wav - 鱼上钩音效

---

### 4. 地点音效 (audio/locations/)

- shop_enter.wav - 进入商店音效
- shop_bell.wav - 商店门铃
- town_crowd.ogg - 城镇人群嘈杂声（循环）
- farm_animals.ogg - 农场动物声音（循环）
- forest_birds.ogg - 森林鸟鸣（循环）
- beach_waves.ogg - 海滩海浪声（循环）

---

### 5. UI 音效 (audio/ui/)

- click.wav - 点击按钮
- confirm.wav - 确认操作
- cancel.wav - 取消操作
- hover.wav - 鼠标悬停
- notification.wav - 通知提示音
- quest_complete.wav - 任务完成音效
- level_up.wav - 升级音效
- error.wav - 错误提示音

---

## 📝 素材来源建议

### 免费资源网站

1. **OpenGameArt.org**
   - URL: https://opengameart.org/
   - 推荐搜索: "pixel art characters", "farm tiles", "RPG items"

2. **itch.io Game Assets**
   - URL: https://itch.io/game-assets
   - 推荐: "Stardew Valley style assets"

3. **Kenney.nl**
   - URL: https://kenney.nl/assets
   - 推荐: "1-Bit Platformer Pack", "Topdown Tanks"

4. **Craftpix Freebies**
   - URL: https://craftpix.net/freebies/
   - 推荐: "Farm Tileset", "Character Sprites"

### AI 生成工具

1. **角色精灵**: Aseprite + AI 辅助
2. **物品图标**: Stable Diffusion / Midjourney
3. **音效**: BFXR / Chiptone (8-bit 风格)
4. **环境音**: Freesound.org

### 付费资源（可选）

1. **Unity Asset Store** (可用于 Godot)
2. **itch.io 付费素材包**
3. **定制美术外包**

---

## 🎯 优先级排序

### P0 - 立即需要（基础可玩）
- [ ] 玩家角色精灵
- [ ] 3个主要 NPC 精灵（Pierre, Abigail, Lewis）
- [ ] 基础 UI 元素（对话框、背包槽）
- [ ] 基础地形瓦片（草地、泥土、水）
- [ ] 点击和确认音效

### P1 - 短期需要（良好体验）
- [ ] 所有 10 个 NPC 精灵
- [ ] 农作物和工具精灵
- [ ] 完整 UI 套件
- [ ] 季节环境音
- [ ] 情感音效

### P2 - 中期需要（丰富内容）
- [ ] 建筑和室内场景
- [ ] 更多物品类型
- [ ] 活动音效
- [ ] 地点环境音

### P3 - 长期优化（ polish ）
- [ ] 高级动画效果
- [ ] 粒子特效
- [ ] 高质量背景音乐
- [ ] 语音配音

---

## 📐 技术规范

### 图像规范
- **格式**: PNG (支持透明通道)
- **色彩模式**: RGBA
- **调色板**: 限制在 32 色以内（复古风格）
- **像素完美**: 避免抗锯齿模糊

### 音频规范
- **音乐**: OGG Vorbis, 44.1kHz, 立体声
- **音效**: WAV, 22.05kHz, 单声道
- **音量标准化**: -6dB 峰值

### 命名规范
- 使用 snake_case（小写下划线）
- 前缀标识类型: `npc_`, `item_`, `ui_`, `sfx_`
- 避免空格和特殊字符

---

## ✅ 素材检查清单

使用此清单跟踪素材收集进度：

```
视觉素材:
□ 玩家角色 (4方向 x 4动作)
□ 10个 NPC 角色
□ 20+ 物品图标
□ 完整 UI 套件 (30+ 元素)
□ 地形瓦片集 (8种地形)
□ 建筑瓦片集 (6栋建筑)

音频素材:
□ 7个季节/天气环境音
□ 6个情感音效
□ 15个活动音效
□ 6个地点音效
□ 8个 UI 音效

总计: 约 90+ 个素材文件
```

---

**最后更新**: 2026-04-06
**负责人**: 美术团队 / 素材设计师
