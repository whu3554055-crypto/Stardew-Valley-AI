# 视觉升级总纲（32x32 + 轻量 2D 光照）

## 1. 总目标
- 达到“统一像素风、层次清晰、截图可读”的星露谷同档次观感。
- 固定资源规格为 `32x32`，统一采用 `ground -> deco -> occlusion -> actors -> UI` 分层。
- 光照策略固定为：`CanvasModulate + PointLight2D`（轻量方案）。
- 实施顺序固定为：先农场样板，再扩展到 Town/Forest/Beach/Mine。

## 2. 原则层（必须遵守）
- P1：视觉改造必须走体系化管线，禁止继续以场景局部补丁为主。
- P2：统一 `32x32`，禁止混用 16/18/24 等规格。
- P3：资源优先免费可商用且许可清晰（优先 CC0）；未核验许可不可入库。
- P4：场景必须遵守分层结构，不得把遮挡、交互、装饰混在同层。
- P5：PointLight2D 仅关键灯开阴影，禁止全图密集开阴影。
- P6：先农场完成视觉样板与参数模板，再复制到其他场景。
- P7：每轮改动必须配套可读性与性能回归，不以“截图好看”替代验收。

## 3. 长期指导层（持续执行）
- G1：建立可复用资源管线（导入预设、命名规范、图层规范、灯光参数模板）。
- G2：建立视觉北极星对照集（固定机位、白天/夜晚/天气的版本截图对比）。
- G3：环境可先用免费高质量包打底，核心角色/NPC/地标建筑逐步风格化自有化。
- G4：灯光“少而精”，先可读后氛围，性能预算先行。
- G5：许可治理、风格治理、性能治理纳入发布门禁（Checklist 必过）。

## 4. 免费资源库候选（首批）
- Kenney（CC0）
  - <https://kenney.nl/assets/isometric-miniature-farm>
  - <https://kenney.nl/assets/pixel-platformer-farm-expansion>
- itch.io（逐包核验许可）
  - <https://lushmustache.itch.io/pixelfarm>
  - <https://itch.io/game-assets/free/tag-32x32/tag-farming>
- OpenGameArt（可筛 CC0）
  - <http://opengameart.org/content/simple-farm-tiles>
  - <http://opengameart.org/content/farming-set-pixel-art>

## 5. 光照策略决策
- 主方案：`CanvasModulate + PointLight2D`。
- 推荐参数方向：
  - 环境光负责统一氛围；
  - PointLight2D 只用于门口、灯笼、夜间关键引导；
  - 阴影滤波优先 `None` 或低阶 PCF，减少像素糊化和性能成本。
- 阶段二（可选增强）：
  - 引入 `DirectionalLight2D` 统一日照方向；
  - 关键资产少量引入 2D normal map。

## 6. 执行阶段（总方案）
### 阶段 A：资源与规范冻结
- 冻结 32x32 视觉规范（色板、轮廓、命名、层级、碰撞/遮挡规则）。
- 建立资源许可证台账（来源 URL、license、用途、是否可商用、是否需署名）。
- 设定替换优先级：地表/道路 > 建筑 > 树木花草 > 道具 > UI。

### 阶段 B：农场样板（视觉基线）
- `world_farm` 完成 ground/deco/occlusion 三层重建。
- 农场输出昼/夜/天气对照截图与灯光参数快照。
- 完成 LightOccluder2D 简化遮挡策略。

### 阶段 C：多场景扩展
- 将农场规范复制到 Town/Forest/Beach/Mine。
- 每场景仅保留 1-2 个关键特色光源，保持性能预算。
- 保证跨场景色温、明度、UI 对比度连续。

### 阶段 D：回归与验收
- 运行 headless smoke、world shell smoke、必要的测试回归。
- 人工验收截图对比（改造前/后、白天/夜晚/天气）。
- 通过后进入角色/NPC 动画和高价值 normal map 增强。

## 7. TODO List（完整可执行）
- T1：筛选并下载首批免费资源包（Kenney + itch + OGA 备份）。
- T2：建立资源许可证台账并完成首批核验。
- T3：冻结 32x32 视觉规范并确认层级命名。
- T4：农场 ground 层重铺（草地/道路/耕地/噪声细节）。
- T5：农场 deco 层重建（农舍/树木/围栏/花草/道具）。
- T6：农场 occlusion 层与遮挡修正（含 LightOccluder2D）。
- T7：农场接入轻量 2D 光照（环境光 + 关键点光）。
- T8：农场性能回归（灯数量、阴影、occluder 顶点）。
- T9：将农场基线复制到 Town/Forest/Beach/Mine。
- T10：统一 UI 对比度和字体可读性（昼夜可读）。
- T11：全场景 smoke + 手工截图验收。
- T12：建立视觉北极星对照集与版本对比模板。
- T13：核心角色/NPC/地标建筑风格统一计划。
- T14：评估阶段二（DirectionalLight2D + 局部 normal map）。

## 8. Check List（发布门禁）
- CL1：资源许可可追溯，均为免费可商用或已明确约束。
- CL2：所有场景 tile 规格统一为 32x32，无混用。
- CL3：无占位色块感、无大面积重复格子感。
- CL4：建筑、树木、道路、作物在常见视角下可读。
- CL5：夜间可读、白天不过曝、无大面积死黑。
- CL6：PointLight2D/阴影数量受控，性能无明显回退。
- CL7：跨场景色调连续，无明显拼接割裂。
- CL8：headless/world shell/GUT（如适用）回归通过。
- CL9：改造前后截图对比达到“可公开展示”质量。
- CL10：原则层（P1-P7）无违反项，偏离项已记录与说明。

## 9. 对接文件（现有工程）
- `scenes/world/world_farm.tscn`
- `scripts/world/world_farm_root.gd`
- `scripts/game_tilemap.gd`
- `scenes/world/world_town.tscn`
- `scenes/world/world_forest.tscn`
- `scenes/world/world_beach.tscn`
- `scenes/world/world_mine.tscn`
- `scenes/main.gd`

## 附录 A：资源许可证台账模板
- 资源名：
- 来源 URL：
- 作者/组织：
- License：
- 是否可商用：
- 是否要求署名：
- 是否允许修改：
- 项目用途（场景/对象）：
- 备注：

## 附录 B：视觉验收截图索引模板
- 版本号/提交号：
- 场景：
- 时间段（白天/黄昏/夜晚）：
- 天气：
- 对比图（改造前）：
- 对比图（改造后）：
- 可读性结论：
- 性能记录（FPS/内存）：

## 附录 C：农场首批 2 周冲刺拆解（按提交粒度）

### 执行约定
- 每个功能点对应一个提交，禁止把无关改动混入同一提交。
- 每日结束至少产出 1 张“改造前/后”对比截图并记录在附录 B。
- 每完成 2-3 个提交执行一次 smoke，避免积累式回归风险。

### Week 1（农场基线成型）
- D1：资源入场与许可证核验
  - C1：新增首批资源包索引与下载占位目录。
  - C2：完成许可证台账首轮登记（Kenney + itch + OGA 候选）。
- D2：地表基线重铺（ground）
  - C3：农场草地底色与明暗噪声分布替换。
  - C4：主路径与支路地表逻辑重铺（可读性优先）。
- D3：耕地与农田块语义化
  - C5：耕地区块统一纹理与边界表达。
  - C6：耕地与非耕地过渡细节（避免硬切）。
- D4：建筑立面第一轮（deco）
  - C7：农舍墙体/屋顶/门窗统一风格替换。
  - C8：农舍阴影和轮廓层次修正。
- D5：树木花草与围栏
  - C9：树木簇、花草点缀、围栏统一风格替换。
  - C10：减少重复图案，优化视觉节奏。
- D6：遮挡层（occlusion）与碰撞对齐
  - C11：房屋与树体前景遮挡层修正。
  - C12：遮挡表现与碰撞语义一致性检查。
- D7：周验收（农场 V1）
  - C13：完成昼/夜/天气三组截图对比。
  - C14：执行 smoke + 可读性评审，输出问题清单。

### Week 2（光照与质量打磨）
- D8：轻量 2D 光照接入
  - C15：接入 CanvasModulate 环境光并确定日/夜参数。
  - C16：配置农舍门前与关键引导点 PointLight2D。
- D9：光照性能约束
  - C17：关键灯阴影策略（仅必要灯开阴影）。
  - C18：Occluder 顶点简化与性能回归。
- D10：UI 与场景对比协调
  - C19：HUD 与提示文本对比度统一。
  - C20：昼夜状态下 UI 可读性验证与修正。
- D11：视觉一致性巡检
  - C21：颜色、材质、边缘轮廓统一性巡检。
  - C22：农场内“突兀素材”替换或二次调色。
- D12：玩法可读性巡检
  - C23：交互点（耕地、门口、路径）识别性检查。
  - C24：角色与场景前后景关系复核。
- D13：回归与文档收敛
  - C25：执行 smoke 与关键回归测试。
  - C26：更新附录 B 截图索引与结论。
- D14：农场样板冻结（可复制基线）
  - C27：冻结农场参数模板（地表、光照、遮挡）。
  - C28：输出“扩展到 Town/Forest/Beach/Mine”的复制清单。

## 附录 D：最小开工包（Day1 可直接执行）

### D1 下载清单（先可用、再优化）
- 必选包（至少 1 套主包 + 1 套备份）：
  - Kenney: Isometric Miniature Farm
  - Kenney: Pixel Platformer Farm Expansion
  - itch 候选: PixelFarm（仅在许可核验通过后使用）
  - OGA 候选: Simple Farm Tiles / Farming Set（仅在许可核验通过后使用）
- 原则：先保证风格一致和许可清晰，再考虑素材数量。

### 仓库目录模板（建议）
- `assets/art_source/third_party/farm_pack_primary/`
- `assets/art_source/third_party/farm_pack_backup/`
- `assets/art_source/license/`
- `assets/tiles/farm32/ground/`
- `assets/tiles/farm32/deco/`
- `assets/tiles/farm32/occlusion/`
- `assets/sprites/buildings/farmhouse32/`
- `assets/sprites/props/farm32/`

### 命名与版本模板
- 文件命名：`<domain>_<theme>_<layer>_<variant>_v<nn>.png`
  - 示例：`farm_grass_ground_a_v01.png`
- 图集命名：`atlas_farm32_<category>_v<nn>.png`
  - 示例：`atlas_farm32_ground_v01.png`
- 许可证记录文件：`assets/art_source/license/third_party_assets_register.md`

### Day1 任务卡（最小闭环）
- K1：下载并整理首批资源到目录模板（不直接覆盖现有运行资源）。
- K2：建立许可证登记表并录入首批 3 套候选包。
- K3：挑选“主包 + 备包”各 1 套，标记用途（ground/deco/props）。
- K4：输出 1 份“农场替换优先级清单”（地表 > 建筑 > 树木花草 > 道具）。
- K5：保存 3 张改造前基线截图（白天、夜晚、雨天或阴天）。

### Day1 验收标准
- A1：目录结构完整，团队成员可按路径直接取用素材。
- A2：至少 2 套资源许可已核验并可商用/可修改。
- A3：已有“主包 + 备包”决策结论，避免后续摇摆。
- A4：基线截图已归档，可用于 Week1/Week2 对照。
