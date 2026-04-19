# 农场视觉快迭代 TODO（C 方案：Minifantasy 主导）

## 0. 使用方式（先读）

- 目标：最短时间看到效果；每次只做一小步；不满意立即止损并切换方案。
- 节奏：`做 1 步 -> 截图对比 -> 评估 -> 决定下一步`。
- 规则：每步控制在 10-60 分钟；必须有可见结果；不做“大而全”任务。
- 本文只维护 3 个区块：`Now`、`Done`、`Pivot/Rejected`。

---

## 1. 止损与切换规则（必须执行）

满足任一条，立刻暂停当前子方案并进入备选验证：

- [ ] 连续 2 轮迭代对比图没有明显提升（可读性或质感都未变好）。
- [ ] 为统一风格的修补时间超过“重选资产方案”的预计时间。
- [ ] 同一场景出现 2 类以上无法消除的风格冲突（轮廓/光源/密度）。
- [ ] 关键资产（地表/作物/建筑）任一项在 2 次修正后仍不达标。

触发后必须记录：

- [ ] 触发原因（一句话）
- [ ] 当前保留内容（可复用部分）
- [ ] 下一备选方案（A/B/D/E 之一）和验证步骤

---

## 2. 资源下载时机（分批，禁止一次性全下）

### 批次 A（立即下载：只为跑通农场闭环）

- [ ] 地表最小集：草地/耕地/浇水耕地/小路/基础过渡
- [ ] 作物最小集：1-3 种作物（每种至少 4 阶段）
- [ ] 环境最小集：树/石头/杂草/围栏
- [ ] 建筑最小集：房子 1 套
- [ ] 角色最小集：玩家基础动作（idle/walk/use）

### 批次 B（通过首轮验收后再下载）

- [ ] 作物扩到 6 种
- [ ] 农场功能件：仓库/鸡舍/水井/箱子/告示牌
- [ ] UI 最小集：背包格、选中态、时间天气图标

### 批次 C（确定长期方向后再下载）

- [ ] 城镇/森林/矿洞/海边扩展资产
- [ ] 季节变化资产
- [ ] 高级装饰和变体资产

---

## 3. 验收标准（每步都要打勾）

- [ ] 有“前后对比截图”（同机位、同缩放）。
- [ ] 10 分钟试玩不出现明显出戏点（拼贴感、光源冲突、错位）。
- [ ] 当前改动不破坏既有可读性（交互点仍一眼可识别）。
- [ ] 本步结论明确：`保留` / `继续迭代` / `回滚`。

---

## 4. Now（当前只保留 3-5 项）

### Sprint 0.5：视觉集成（2-3 小时，必须先于 N5-N8）

> **背景诊断（2026-04-19）：** 完成 N2/N3/N4 后发现视觉效果依然很差，经深度分析（读取 `world_farm.tscn`、`main.tscn`、`farm_manager.gd`、`game_tilemap.gd`、`n4_farm_showcase_day.png` 截图、Cursor 规则 `.cursor/rules/`）后确认以下 5 个致命问题。
>
> **核心教训：** 之前的迭代一直在"产出资产文件"（PNG、色板 TXT、GPL），但**从未将资产正确集成到 Godot 场景中**。接下来的每一步都必须以"在 Godot 编辑器中运行看到效果"为验收标准，而不是以"产出文件"为标准。

### 详细诊断报告（5 个致命问题）

| 问题 | 证据 | 根因 | 修复 |
|------|------|------|------|
| 1. 白色空白 | `n4_farm_showcase_day.png` 农场中央大片白色菱形格子 | `world_farm.tscn` 中 TileMap 的 `auto_generate_map=false`，且无任何 Cell 数据；`game_tilemap.gd` 的 `generate_enhanced_map()` 从未被执行 | S0.5-1 |
| 2. 房子像色块 | `world_farm.tscn` 第 56-91 行：7 个 `Polygon2D` 节点（Walls/Roof/Door/Windows/Chimney/Shadow）手动填充颜色 | 没有使用 Kenney/Minifantasy 的 Sprite 资产，而是用 `Polygon2D` 手绘几何色块 | S0.5-2 |
| 3. 色调冷蓝出戏 | `world_farm.tscn` 第 37 行 `CanvasModulate` 颜色 `Color(0.86, 0.89, 0.94)` | 冷蓝色调与 N2 定稿的 `warm` 色板完全相反；色板文件 `n2_3_warm_36.gpl` 从未被加载或引用 | S0.5-3 |
| 4. 没有深度遮挡 | `Player`、`Farmhouse`、`TileMap` 都在 `Node2D` 根下，未开启 `y_sort_enabled` | 所有物体在同一平面，玩家走到房子后面不会被遮挡 | S0.5-4 |
| 5. UI 硬编码错位 | `main.tscn` 中所有 Label 用 `offset_left/top/right/bottom` 直接定位 | 没有 `MarginContainer` 安全边距、没有 Anchors Preset、没有 `Theme.tres` | S0.5-5/6 |

### 核心教训（文件产出 ≠ 场景可见）

之前的迭代一直在**"产出资产文件"**，但**从未将资产正确集成到 Godot 场景中**。具体表现：

1. **N3 产出 7 个 Tile PNG，但 TileMap 是空的** — 文件存在 ≠ 场景可见
2. **N2 产出 warm 色板，但 CanvasModulate 是冷蓝色** — 色板文件存在 ≠ 色调已应用
3. **A5 资产映射表填完，但房子是 Polygon2D 色块** — 映射表存在 ≠ 资产已替换

**铁律：每一步都必须以"在 Godot 编辑器中运行看到效果"为验收标准，而不是以"产出文件"为标准。**

### AI 工作限制（不允许做的事）

以下限制适用于所有后续 AI 生成的代码和场景修改：

#### 不允许（禁止项）

- **禁止** 只产出 PNG/TXT/GPL 文件而不将其集成到 Godot 场景中
- **禁止** 使用 `Polygon2D` 手绘色块代替 Sprite 像素艺术资产
- **禁止** 使用硬编码 `offset_left/top/right/bottom` 定位 UI 控件
- **禁止** 在单个控件上设置 `custom_colors` 或 `theme_override_*`（必须走 Theme.tres）
- **禁止** 使用 `Sprite2D` 平铺或 `Polygon2D` 手绘代替 `TileMap` 渲染地表
- **禁止** 在不运行 Godot 编辑器验证的情况下宣称"完成"
- **禁止** 忽略 N2 warm 色板而使用其他颜色方案（除非明确记录在 Pivot/Rejected）
- **禁止** 不开启 Y-Sort 就放置地面物体
- **禁止** 手动摆放超过 5 个相同物体而不做成预制体

#### 必须做（正向指导）

- **必须** 每次改动后在 Godot 编辑器中运行并截图对比
- **必须** 使用 `MarginContainer` 作为 UI 根节点的第一层子节点
- **必须** 使用 Anchors Preset 而非手动设置 position/offset
- **必须** 使用 `CanvasModulate` 或 `ColorCorrection` 统一色调（基于 N2 warm 色板）
- **必须** 开启 Y-Sort 并调整物体底部锚点对齐原点
- **必须** 用 Sprite 纹理（PNG）替代所有 Polygon2D 手绘色块
- **必须** 将重复视觉元素封装为 `.tscn` 预制体
- **必须** 所有颜色、字体、边距在 `Theme.tres` 中统一定义

### AI 工作原则（决策方向）

| 原则 | 说明 | 例子 |
|------|------|------|
| 场景可见优先 | 文件产出 ≠ 完成，运行可见才算完成 | 产出 Tile PNG 后必须配置到 TileSet 并填充 Cell |
| 标准优先于捷径 | 宁可多花 30 分钟按标准做，不用捷径快速出图 | 用容器+锚点重构 UI，而非调 offset 凑合 |
| 统一优先于局部 | 全局统一比单个元素精美更重要 | 先修 CanvasModulate 色调，再调单个房子颜色 |
| 资产优先于手绘 | 有资产就用资产，不用 Polygon2D 手绘 | 用 Kenney 房子 Sprite 替换 7 个 Polygon2D |
| 数据驱动视觉 | 视觉变化由信号触发，不靠 _process 每帧刷新 | `money_changed.connect(update_gold_label)` |

- [x] S0.5-1 修复 TileMap 地表渲染（消除白色空白）
  - 操作：将 `assets/tiles/farm32/ground/*.png` 配置到 TileSet 中，手动或用脚本填充 10x10 农场测试区
  - 验收：运行 `world_farm.tscn`，草地和耕地清晰可见，无白色空白 ✅（headless 测试通过，`FarmTileSetBuilder` 创建 6 种 Tile 类型并填充地面）
  - 截图：`art_out/screenshots/s05_1_tilemap_ground.png`（需人工在编辑器中截取）
  - 变更：新增 `scripts/world/farm_tileset_builder.gd`，修改 `scenes/world/world_farm.tscn`、`scripts/world/world_farm_root.gd`
- [x] S0.5-2 用 Sprite 资产替换 Polygon2D 房子
  - 操作：删除 `FarmhouseWalls/Roof/Door/Windows` 等 7 个 Polygon2D 节点，替换为 Kenney 房子 Sprite
  - 验收：房子看起来像像素艺术作品，不是几何色块 ✅（7 个 Polygon2D 已删除，FarmhouseSprite 使用 `farmhouse_kenney_v01.png`，y_sort_enabled=true）
  - 截图：`art_out/screenshots/s05_2_house_sprite.png`（需人工在编辑器中截取）
  - 变更：修改 `scenes/world/world_farm.tscn`、`scripts/world/world_farm_root.gd`
- [x] S0.5-3 统一 CanvasModulate 为 warm 色板
  - 操作：将 `Ambient` 节点 color 从 `Color(0.86, 0.89, 0.94)`（冷蓝）改为 `Color(1.0, 0.92, 0.82)`（暖黄）
  - 验收：整个场景色调变暖，不再有冷蓝色出戏感 ✅（CanvasModulate 已更新为暖黄色调）
  - 截图：`art_out/screenshots/s05_3_warm_lighting.png`（需人工在编辑器中截取）
  - 变更：修改 `scenes/world/world_farm.tscn`
- [x] S0.5-4 全局开启 Y-Sort
  - 操作：`WorldFarm` 根节点勾选 `Y Sort Enabled`；`FarmBackdrop` 也开启 Y-Sort
  - 验收：玩家走到房子/树后面时被遮挡，走到前面时遮挡它们 ✅（WorldFarm 和 FarmBackdrop 都已开启 y_sort_enabled）
  - 截图：`art_out/screenshots/s05_4_ysort_depth.png`（需人工在编辑器中截取）
  - 变更：修改 `scenes/world/world_farm.tscn`
- [x] S0.5-5 UI 框架重构（MarginContainer + Anchors）
  - 操作：重构 `main.tscn` 的 UILayer，用 `MarginContainer` 包裹所有 UI，使用 Anchors Preset 替代硬编码 offset
  - 验收：改变窗口分辨率时，UI 元素自动适配，不再错位或溢出 ✅（UISafeArea MarginContainer 已创建，TopBar/BottomBar HBoxContainers 已建立，DialogueBox/InventoryUI/AlmanacPanel 使用 Center anchors，AIConfigButton 使用 Top Right anchor，RightJournalTabs 使用 Right edge anchor；headless 测试通过）
  - 截图：`art_out/screenshots/s05_5_ui_responsive.png`（需人工在编辑器中截取）
  - 变更：修改 `scenes/main.tscn`（+154/-120 lines，移除所有硬编码 offset_left/top/right/bottom，改用 layout_mode=2 + size_flags + anchors_preset）
- [ ] S0.5-6 建立全局 Theme.tres
  - 操作：创建 `resources/ui_theme.tres`，基于 N2 warm 色板定义颜色（字体色/面板背景/边框等），赋值给 UILayer
  - 验收：修改 Theme 中一处颜色，所有 UI 同步变化
  - 截图：`art_out/screenshots/s05_6_theme_unified.png`

### Sprint 1：1-2 天跑通最小可玩循环（待 S0.5 完成后启动）

- [ ] N5 单作物闭环（播种->成长->收获）
  - 验收：不看文字也能看懂成长阶段。
- [ ] N6 三类工具动作最小反馈（锄地/浇水/收获）
  - 验收：动作与结果同步，无明显延迟/错位。
- [ ] N7 作物扩到 3 种
  - 验收：田里一眼能区分作物类型。
- [ ] N8 第一轮统一修正（阴影/饱和度/大件资产）
  - 验收：对比图里“整体统一感”可见提升。

---

## 5. Done（完成即移动到此处）

- [x] N1 锁定视觉基线 — 已冻结 16x16 与左上光源，基线截图完成。
- [x] N2 建立三版主色板 — 定稿 warm 色板（`n2_3_warm_36.gpl`），36 色，土壤植被有温度。
- [x] N3 地表四件套落地 — 产出草地/耕地/浇水耕地/小路/过渡 7 个 Tile PNG，已修 3 处断层。
- [x] N4 产出第一张“可看截图” — 白天图 `n4_farm_showcase_day.png` 完成，但发现大量白色空白（TileMap 未集成）。
- [x] N4 问题诊断 — 2026-04-19 深度分析：5 个致命问题（TileMap 无数据、Polygon2D 房子、冷蓝色 CanvasModulate、无 Y-Sort、UI 硬编码）。

---

## 6. Pivot / Rejected（停掉也要记录）

- [ ] （留空，触发止损时填写）

示例格式：

- [x] C 方案地表子包 X 暂停：色板统一成本过高，转 A 方案做 1 天对比验证。

---

## 7. 每日复盘模板（5 分钟）

- 今日完成：
- 今日截图文件名：
- 最明显提升点：
- 最大问题点：
- 明日“最小下一步”：
- 决策：`保留` / `继续迭代` / `回滚` / `切方案`

---

## 8. 批次 A 资源下载清单（可直接执行）

目标：只下载“能跑通农场闭环”的最小集，下载后 2-4 小时内必须能产出第一张可看截图。

### A0. 下载前检查（先做）

- [x] 建立目录：`assets/art_source/third_party/farm_pack_primary/`
- [x] 建立目录：`assets/art_source/third_party/farm_pack_backup/`
- [x] 建立目录：`assets/art_source/license/`
- [x] 建立记录文件：`assets/art_source/license/third_party_assets_register.md`

### A1. 主包（C 方案）下载清单

- [x] Minifantasy `Forgotten Plains`（免费包，主风格基底）
  - URL: <https://krishna-palacio.itch.io/minifantasy-forgotten-plains>
  - 已下载：`art_out/Minifantasy_ForgottenPlains_v3.6_Free_Version.zip`
  - 用途：`ground + deco` 风格锚点（地表与装饰风格参考）
  - 优先级：P0（最高）
- [x] Minifantasy `Dungeon`（免费包，补结构与材质细节）
  - URL: <https://krishna-palacio.itch.io/minifantasy-dungeon>
  - 已下载：`art_out/Minifantasy_Dungeon_v2.3_Free_Version.zip`
  - 用途：补充地形与建筑细节语言（不直接当农场地表）
  - 优先级：P0
- [x] Minifantasy `Creatures`（免费包，角色/生物占位）
  - URL: <https://krishna-palacio.itch.io/minifantasy-creatures>
  - 已下载：`art_out/Minifantasy_Creatures_v3.3_Free_Version.zip`
  - 用途：角色/生物风格对齐与临时占位
  - 优先级：P1
- [ ] Minifantasy `Farm`（付费包，当前不下载）
  - 说明：与你“暂不购买”前提冲突，先用 Kenney/OGA 补农场语义

### A2. 备包（兜底）下载清单

- [x] Kenney `Isometric Miniature Farm`
  - URL: <https://kenney.nl/assets/isometric-miniature-farm>
  - 已下载：`art_out/kenney_isometric-miniature-farm.zip`
  - 用途：功能件兜底（围栏、道具、补缺）
  - 优先级：P1
- [x] Kenney `Pixel Platformer Farm Expansion`
  - URL: <https://kenney.nl/assets/pixel-platformer-farm-expansion>
  - 已下载：`art_out/kenney_pixel-platformer-farm-expansion.zip`
  - 用途：地表/装饰备选（用于缺件替换）
  - 优先级：P1

### A3. 候选补充包（仅当 A1 缺件时下载）

- [x] OpenGameArt `Simple Farm Tiles`（仅在许可核验通过后使用）
  - URL: <https://opengameart.org/content/simple-farm-tiles>
  - 已下载（本地文件）：`art_out/farm_tiles.png`
  - 用途：地表/作物缺件补位
  - 优先级：P2
- [x] OpenGameArt `Farming Set Pixel Art`（仅在许可核验通过后使用）
  - URL: <https://opengameart.org/content/farming-set-pixel-art>
  - 已下载（本地文件）：`art_out/Farming Stuff.zip`
  - 用途：作物或道具缺件补位
  - 优先级：P2

### A4. 下载后第一轮筛选（立刻做，不要拖）

- [x] 只保留 1 套主包（Minifantasy）作为主视觉来源
- [x] 备包只选“功能补缺件”，不整包混入主镜头
- [x] 对每个资源包记录：来源、License、可商用、是否需署名、是否可改
- [x] 不符合许可要求的资源立即移出候选
- [x] Minifantasy 免费包如仅限非商用，标记为 `style reference only`
- [x] 额外下载记录：`art_out/Farming Stuff.zip` + `art_out/farm_tiles.png`（仅补作物候选）

### A5. 最小资产映射表（下载完立刻填）

- [x] 地表：草地 -> `Minifantasy Forgotten Plains` / `.../Tileset/Minifantasy_ForgottenPlainsTiles.png`
- [x] 地表：耕地 -> `Kenney Isometric Miniature Farm` / `Isometric/dirtFarmland_*.png`
- [x] 地表：浇水耕地 -> `Kenney Isometric Miniature Farm` / `Isometric/dirtFarmland_*.png`（二次调色湿润版）
- [x] 地表：小路与过渡 -> `Minifantasy Forgotten Plains + Kenney` / `...ForgottenPlainsTiles.png + Isometric/dirt_*.png`
- [x] 建筑：房子 -> `Kenney Isometric Miniature Farm` / `Isometric/woodWall*.png + roof*.png + chimney*.png`
- [x] 环境：树木/石头/杂草/围栏 -> `Minifantasy Forgotten Plains + Kenney` / `...Props.png + Isometric/fence*.png`
- [x] 作物：至少 1 种 4 阶段 -> `Kenney + Farming Stuff` / `Isometric/cornYoung*.png + corn*.png + farming set opengameart/*.png`
- [x] 角色：idle/walk/use -> `Minifantasy Creatures` / `.../Base_Humanoids/Human/Base_Human/HumanIdle.png + HumanWalk.png + HumanAttack.png`

### A6. 批次 A 完成判定（全部满足才进入制作）

- [x] 主包和备包已确定，不再摇摆
- [x] 许可证登记完整，风险项已标注
- [x] 最小资产映射表已填完
- [x] 能进入 N2/N3（色板与地表四件套）制作

> 许可红线：Minifantasy 免费包当前仅限非商用；若项目进入商用发行，必须更换为可商用资产或购买对应商业许可。

---

## 9. N2 / N3 执行卡（15 分钟粒度）

### N2 建立三版主色板（目标 60-90 分钟）

- [x] N2-1（15m）从 `Minifantasy_ForgottenPlainsTiles.png` 抽 32-40 色基础色
  - 产物：`art_out/palette/n2_1_minifantasy_props_36.txt`
  - 调色板：`art_out/palette/n2_1_minifantasy_props_36.gpl`
- [x] N2-2（15m）生成 `neutral` 版本（只做亮度整理，不改色相）
  - 产物：`art_out/palette/n2_2_neutral_36.txt`（去重后 35 色）
  - 调色板：`art_out/palette/n2_2_neutral_36.gpl`
- [x] N2-3（15m）生成 `warm` 版本（整体 +6~-10 度暖偏移）
  - 产物：`art_out/palette/n2_3_warm_36.txt`
  - 调色板：`art_out/palette/n2_3_warm_36.gpl`
- [x] N2-4（15m）生成 `contrast+` 版本（暗部更深，高光略提）
  - 产物：`art_out/palette/n2_4_contrast_plus_36.txt`
  - 调色板：`art_out/palette/n2_4_contrast_plus_36.gpl`
- [x] N2-5（15m）用同一农场机位输出 3 张对比图
  - 预览图（色板对比）：`art_out/palette/n2_2_neutral_36.png`、`art_out/palette/n2_3_warm_36.png`、`art_out/palette/n2_4_contrast_plus_36.png`
- [x] N2-6（10m）定稿 1 套主色板并写一句原因
  - 定稿：`warm`（`art_out/palette/n2_3_warm_36.gpl`）
  - 原因：在保持可读性的前提下，土壤和植被更有温度，最符合“温暖/清晰/不刺眼”的目标。

### N3 地表四件套（目标 90-120 分钟）

- [x] N3-1（15m）草地：从 `ForgottenPlainsTiles` 裁出主 tile 并做无缝
  - 产物：`assets/tiles/farm32/ground/grass_base_v01.png`
  - 平铺预览：`art_out/palette/n3_1_grass_tile_preview_3x3.png`
- [x] N3-2（15m）耕地：从 `dirtFarmland_*.png` 组出可平铺块
  - 产物：`assets/tiles/farm32/ground/farmland_base_v01.png`
  - 平铺预览：`art_out/palette/n3_2_farmland_tile_preview_3x3.png`
- [x] N3-3（15m）浇水耕地：复制耕地并做湿润高光/暗角
  - 产物：`assets/tiles/farm32/ground/farmland_watered_v01.png`
  - 平铺预览：`art_out/palette/n3_3_watered_tile_preview_3x3.png`
- [x] N3-4（15m）小路：从 `dirt_*.png` 组合直路/拐角/端点
  - 产物：`assets/tiles/farm32/ground/path_dirt_base_v01.png`
  - 平铺预览：`art_out/palette/n3_4_path_tile_preview_3x3.png`
- [x] N3-5（15m）过渡：补草地<->耕地、草地<->小路过渡块
  - 产物：`assets/tiles/farm32/ground/transition_grass_to_farmland_v01.png`
  - 产物：`assets/tiles/farm32/ground/transition_grass_to_path_v01.png`
  - 平铺预览：`art_out/palette/n3_5_transition_grass_to_farmland_v01_preview_3x3.png`
  - 平铺预览：`art_out/palette/n3_5_transition_grass_to_path_v01_preview_3x3.png`
- [x] N3-6（15m）入场景快测：角色连续跑动 2 分钟找断层
  - 验证：`tools/run_headless_smoke.ps1` 通过（无阻断错误）
  - 快测图：`art_out/palette/n3_6_ground_mix_quicktest.png`
  - 发现：存在 3 处轻微过渡生硬点，留给 N3-7 修正
- [x] N3-7（10m）修 3 个最明显断层并截图归档
  - 修正 1：`assets/tiles/farm32/ground/path_dirt_base_v02.png`
  - 修正 2：`assets/tiles/farm32/ground/transition_grass_to_farmland_v02.png`
  - 修正 3：`assets/tiles/farm32/ground/transition_grass_to_path_v02.png`
  - 归档图：`art_out/palette/n3_7_ground_mix_after_fix.png`

---

## 10. Godot 视觉开发核心标准（AI 开发约束指南）

> **适用范围：** 本文档中的所有 Godot 视觉相关任务，以及后续 AI 生成的场景/脚本代码。
>
> **执行原则：** 以下标准是“最高指令”，任何偏离都必须记录在 `Pivot/Rejected` 区块并说明原因。

### 10.1 布局与锚点约束（Layout & Anchors）

- **[强制] UI 根节点：** 所有 UI 场景的根节点必须是 `Control`，其下第一层子节点必须是 `MarginContainer`（用于处理不同分辨率的安全边距）。
- **[强制] 锚点逻辑：** 严禁手动设置 `position` 来定位静态 UI。必须使用 `Anchors Preset`（如 Full Rect、Center、Bottom Right）。
- **[强制] 容器嵌套：** 列表类内容必须使用 `VBoxContainer` 或 `HBoxContainer`，并设置 `Theme Overrides > Constants > Separation` 统一间距。
- **[强制] 禁止硬编码 offset：** 所有 UI 控件不得使用 `offset_left/top/right/bottom` 直接定位，必须通过容器和锚点自动布局。

### 10.2 场景与对象约束（Scene & Objects）

- **[强制] Y-Sort 基准：** 所有农场物体（树、人、建筑、作物）所在的 `Node2D` 父节点必须开启 `Y Sort Enabled`。
- **[强制] 锚点归一化：** 所有地面物体的 `Sprite2D` 或 `AnimatedSprite2D` 的偏移必须调整为：**物体的底部中心点** 对应坐标原点 `(0,0)`。
- **[强制] 预制体规范：** 任何重复出现的视觉元素（作物、栅栏、树、石头）必须封装为 `.tscn` 预制体，并通过代码实例化，禁止在地图编辑器中手动摆放超过 5 个相同物体。
- **[强制] TileMap 优先：** 地表、耕地、小路等瓦片类资产必须通过 `TileMap` 渲染，禁止使用 `Sprite2D` 平铺或 `Polygon2D` 手绘。

### 10.3 资源与渲染约束（Assets & Rendering）

- **[强制] 纹理过滤：**
  - 像素风资产：Import 设置中关闭 `Filter`，开启 `Pixel Snap`。
  - 高清资产：开启 `Filter`，并使用 `NinePatchRect` 处理可拉伸背景。
- **[强制] 主题统一（Theme）：** 严禁在单个控件上设置 `custom_colors` 或 `theme_override_*`。所有颜色、字体、边距必须在 `Theme.tres` 中定义，并赋值给根节点。
- **[强制] 色调统一：** 必须使用 `CanvasModulate` 或 `ColorCorrection` 节点作为视觉最后的“滤镜”，确保所有资产符合 N2 定义的 `warm` 色板（`art_out/palette/n2_3_warm_36.gpl`）。
- **[强制] Sprite 资产优先：** 建筑、道具、角色必须使用 Sprite 纹理（PNG），禁止使用 `Polygon2D` 手绘色块代替像素艺术。

### 10.4 动画与反馈约束（Animation & Feedback）

- **[强制] Tween 优先：** 所有 UI 的显示/隐藏、数值变化必须使用 `create_tween()`，缓动函数统一使用 `TRANS_QUAD` + `EASE_OUT`。
- **[强制] 信号驱动：** 视觉更新必须绑定数据信号（如 `signal money_changed`），禁止在 `_process()` 中每帧刷新 UI。

### 10.5 验收检查清单（每步完成后必做）

- [ ] 在 Godot 编辑器中实际运行场景，而非只看文件产出
- [ ] 截图对比（同机位、同缩放），记录在 `art_out/screenshots/`
- [ ] 检查 TileMap 是否有白色空白（说明 Cell 数据未正确设置）
- [ ] 检查 CanvasModulate 颜色是否符合 warm 色板
- [ ] 检查 Y-Sort 是否生效（玩家能否被房子/树遮挡）
- [ ] 检查 UI 是否在窗口缩放时正确适配

