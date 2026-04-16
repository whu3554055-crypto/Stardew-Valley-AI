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

### Sprint 0：2-4 小时看到效果

- [ ] N1 锁定视觉基线（网格/光源/关键词）
  - 验收：确认 `16x16`、光源左上、关键词 `温暖/清晰/有层次/不刺眼`。
- [ ] N2 建立三版主色板（neutral/warm/contrast+）
  - 验收：三张同场景静态图对比，选定 1 套主色板。
- [ ] N3 地表四件套落地（草/耕地/浇水耕地/小路）
  - 验收：角色跑动时无明显地块断层或拼贴感。
- [ ] N4 产出第一张“可看截图”
  - 验收：20x20 农场块，含房子+树+石头，输出白天与黄昏各 1 张。

### Sprint 1：1-2 天跑通最小可玩循环

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

- [ ] （留空，完成后从 Now 移入并附 1 句结果）

示例格式：

- [x] N1 锁定视觉基线 - 已冻结 16x16 与左上光源，基线截图完成。

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
- [ ] N2-2（15m）生成 `neutral` 版本（只做亮度整理，不改色相）
- [ ] N2-3（15m）生成 `warm` 版本（整体 +6~-10 度暖偏移）
- [ ] N2-4（15m）生成 `contrast+` 版本（暗部更深，高光略提）
- [ ] N2-5（15m）用同一农场机位输出 3 张对比图
- [ ] N2-6（10m）定稿 1 套主色板并写一句原因

### N3 地表四件套（目标 90-120 分钟）

- [ ] N3-1（15m）草地：从 `ForgottenPlainsTiles` 裁出主 tile 并做无缝
- [ ] N3-2（15m）耕地：从 `dirtFarmland_*.png` 组出可平铺块
- [ ] N3-3（15m）浇水耕地：复制耕地并做湿润高光/暗角
- [ ] N3-4（15m）小路：从 `dirt_*.png` 组合直路/拐角/端点
- [ ] N3-5（15m）过渡：补草地<->耕地、草地<->小路过渡块
- [ ] N3-6（15m）入场景快测：角色连续跑动 2 分钟找断层
- [ ] N3-7（10m）修 3 个最明显断层并截图归档

