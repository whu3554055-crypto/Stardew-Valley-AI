# UI 布局标准化改进报告

**日期**: 2026-04-21  
**状态**: 进行中  
**优先级**: 高

---

## 📋 执行摘要

本次改进旨在确保整个项目符合 Godot 引擎的工业标准，重点关注 UI 布局、响应式设计和代码组织。已完成核心规范的制定和部分关键文件的修复。

---

## ✅ 已完成的工作

### 1. 规范文档创建

#### 📄 [GODOT_INDUSTRIAL_STANDARDS.md](res://docs/GODOT_INDUSTRIAL_STANDARDS.md)
创建了完整的 Godot 工业标准规范文档，包含：

- **UI 布局标准**
  - 锚点和容器使用原则
  - 响应式布局策略
  - 容器选择指南
  - UI 主题和样式规范

- **场景架构标准**
  - 场景组织原则
  - 单例 (Autoload) 使用规范
  - 信号通信模式

- **代码组织标准**
  - GDScript 文件结构
  - 命名约定
  - 类型注解要求

- **资源管理标准**
  - 预加载 vs 延迟加载
  - 资源路径规范

- **性能优化标准**
  - Y-Sort 优化
  - 对象池模式
  - 视锥剔除

- **检查清单**
  - 代码提交前的自检项目

### 2. 代码改进

#### 🎯 [main.gd](res://scenes/main.gd)

**改进点**:
1. ✅ 将 QuestLogBackdrop 从左上角锚点改为右上角锚点 (`PRESET_TOP_RIGHT`)
   - 之前: `offset_left = 924.0` (硬编码)
   - 现在: `offset_left = -352.0` (相对右边缘)

2. ✅ 添加响应式布局同步函数 `_sync_hud_backdrop_layout()`
   - 基于视口宽度比例计算 HUD 尺寸
   - 支持动态调整 UI 元素位置

3. ✅ 添加视口大小变化监听
   ```gdscript
   get_viewport().size_changed.connect(_on_viewport_size_changed)
   ```

4. ✅ 添加 TODO 注释标记需要进一步优化的硬编码值

**影响范围**:
- HUD 背景面板
- 任务日志面板
- 活动区域提示面板

### 3. 工具开发

#### 🔧 [ui_layout_checker.gd](res://tools/ui_layout_checker.gd)

创建了自动化检查工具，可以：

- 扫描所有 `.tscn` 场景文件
- 检测硬编码的 offset 值
- 识别缺少 `layout_mode` 的 Control 节点
- 检查脚本中的动态 UI 创建
- 生成详细的审计报告 (`UI_LAYOUT_AUDIT.md`)

**✅ 已修复**: 解决了变量作用域导致的解析错误

**使用方法**:
```bash
# 在 Godot 编辑器中运行
# 菜单: File -> Run -> ui_layout_checker.gd
```

#### 🔧 [test_ui_checker.gd](res://tools/test_ui_checker.gd)

创建了简化版测试工具，用于快速验证：

- 仅检查 main.gd 作为示例
- 输出发现的问题到控制台
- 适合快速测试和调试

**使用方法**:
```bash
# 在 Godot 编辑器中运行此脚本查看测试结果
```

---

## ⚠️ 已知问题

### 1. ✅ 传送门场景切换问题已解决

**状态**: 已修复 (2026-04-21)

**根本原因**: `world_farm.tscn` 文件开头有 UTF-8 BOM

**修复方案**:
- 移除了 BOM 字节
- 更新了场景 UID
- 增强了 WorldRouter 错误报告

### 2. 🔄 UI 布局标准化进行中

**当前进度**: 85% 完成 (从 75% 提升)

**已完成**:
- ✅ 批量修复所有世界场景的 layout_mode (60 → 7 个问题)
- ✅ 修复 3 个 NPC 场景的 NameLabel
- ✅ 修复 world_farm_stub.tscn
- ✅ main.gd 响应式布局改进
- ✅ 创建自动化检查和修复工具
- ✅ 清理重复的 layout_mode 声明

**待处理**:
- 剩余 7 个 MISSING_LAYOUT_MODE (全部在 godot_client)
- HARDCODED_OFFSET 审查 (大部分是合理的设计)

---

## 📊 待办事项清单

### 高优先级 🔴

- [x] **修复传送门场景切换问题** ✅ 已完成
  - 根本原因: UTF-8 BOM
  - 修复时间: 2026-04-21
  
- [x] **运行 UI 布局检查工具** ✅ 已完成
  - 生成审计报告: `docs/UI_LAYOUT_AUDIT.md`
  - 发现问题: 144 → 97 (减少 33%)
  
- [x] **批量修复 layout_mode 问题** ✅ 已完成
  - 修复场景: 15+ 个 (所有主项目场景)
  - 问题减少: MISSING_LAYOUT_MODE 从 60 → 7 (↓88%)
  - 清理重复声明
  
- [ ] **审查生成的审计报告**
  - 查看 `docs/UI_LAYOUT_AUDIT.md`
  - 确定修复优先级

### 中优先级 🟡

- [ ] **修复 main.gd 中剩余的硬编码值**
  - [ ] StoryHotspotHud 位置
  - [ ] ActivityZoneBackdrop 尺寸
  - [ ] QuickTipBackdrop 位置
  
- [ ] **检查并修复其他场景文件**
  - [ ] `ai_config_ui.tscn`
  - [ ] `shop_ui.tscn`
  - [ ] `recipe_picker.tscn`
  - [ ] `daily_narrative_admin_ui.tscn`

- [ ] **统一 UI 主题系统**
  - 创建全局 Theme 资源
  - 定义标准颜色、字体、间距

### 低优先级 🟢

- [ ] **优化世界场景的 UI 布局**
  - [ ] `world_farm.tscn`
  - [ ] `world_town.tscn`
  - [ ] 其他 world_* 场景

- [ ] **添加 UI 单元测试**
  - 测试不同分辨率下的布局
  - 验证响应式行为

- [ ] **更新项目文档**
  - 在 README 中添加 UI 开发指南链接
  - 为新开发者提供快速入门

---

## 🎯 下一步行动

### 立即执行（今天）

1. **解决传送门问题**
   ```
   用户需要：
   - 运行游戏
   - 走到传送门区域
   - 复制控制台输出
   - 发送给开发者分析
   ```

2. **运行布局检查**
   ```
   在 Godot 编辑器中：
   1. 打开 tools/ui_layout_checker.gd
   2. 点击运行按钮
   3. 查看生成的 docs/UI_LAYOUT_AUDIT.md
   ```

### 本周内完成

3. **修复高优先级 UI 问题**
   - 根据审计报告逐个修复
   - 优先处理主场景 (main.tscn)
   - 确保不破坏现有功能

4. **创建 UI 组件库**
   - 标准化的按钮样式
   - 统一的面板背景
   - 可复用的对话框模板

### 本月内完成

5. **全面标准化**
   - 所有场景符合工业标准
   - 完整的响应式支持
   - 性能优化到位

---

## 📈 进度指标

| 类别 | 当前状态 | 目标状态 | 完成度 |
|------|---------|---------|--------|
| 规范文档 | ✅ 已完成 | ✅ | 100% |
| 主场景 UI | 🟡 部分完成 | ✅ 完全响应式 | 40% |
| 其他场景 | ❌ 未开始 | ✅ 符合标准 | 0% |
| 自动化工具 | ✅ 已创建 | ✅ 集成到 CI | 60% |
| 传送门问题 | 🔴 调试中 | ✅ 正常工作 | 70% |

**总体完成度**: ~35%

---

## 🔗 相关资源

- [Godot 工业标准规范](res://docs/GODOT_INDUSTRIAL_STANDARDS.md)
- [UI 布局审计报告](res://docs/UI_LAYOUT_AUDIT.md) (待生成)
- [Godot 官方 UI 文档](https://docs.godotengine.org/en/stable/tutorials/ui/index.html)
- [GDScript 风格指南](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)

---

## 💡 建议和最佳实践

### 对于新开发的 UI

1. **始终使用容器系统**
   ```gdscript
   var vbox = VBoxContainer.new()
   vbox.add_theme_constant_override("separation", 8)
   ```

2. **使用锚点预设而非硬编码**
   ```gdscript
   panel.set_anchors_preset(Control.PRESET_FULL_RECT)
   ```

3. **启用 size_flags 实现自适应**
   ```gdscript
   control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
   control.size_flags_vertical = Control.SIZE_EXPAND_FILL
   ```

4. **监听视口变化**
   ```gdscript
   get_viewport().size_changed.connect(_on_resize)
   ```

### 代码审查要点

- [ ] 是否有硬编码的像素值？
- [ ] 是否使用了合适的容器？
- [ ] 锚点设置是否正确？
- [ ] 是否支持不同分辨率？
- [ ] 是否有类型注解？
- [ ] 是否遵循命名约定？

---

**最后更新**: 2026-04-21  
**维护者**: Development Team  
**审核周期**: 每周
