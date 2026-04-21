# AgenticContentOrchestrator 重构实施指南

**创建日期**: 2026-04-21  
**状态**: 🔄 **进行中 (Phase 1 完成)**

---

## 📋 当前进度

### ✅ 已完成

- [x] **Phase 1**: 创建 AgenticChainStorage 模块 (164行)
  - 运行时链ID管理
  - 手动队列管理
  - 持久化存储

### ⏳ 待完成

- [ ] **Phase 2**: AgenticChainValidator (验证器)
- [ ] **Phase 3**: AgenticThemeManager (主题管理)
- [ ] **Phase 4**: AgenticCropCatalog (作物目录)
- [ ] **Phase 5**: AgenticPerformanceMonitor (性能监控)
- [ ] **Phase 6**: AgenticFallbackGenerator (回退生成器)
- [ ] **Phase 7**: 重构主协调器
- [ ] **Phase 8**: 集成测试和清理

---

## 🎯 剩余模块实施指南

### Phase 2: AgenticChainValidator

**职责**: 链模板验证、防护栏检查、签名去重

**需要从原文件提取的函数**:
```gdscript
_validate_chain_template(chain: Dictionary) -> Dictionary
_check_guardrails(chain: Dictionary) -> Dictionary
_record_today_objective_signature(chain: Dictionary) -> void
_record_recent_signature(chain: Dictionary) -> void
_is_duplicate_signature(signature: String) -> bool
_check_value_budget(chains: Array) -> bool
```

**需要的成员变量**:
```gdscript
var _recent_signatures: Array[String] = []
var _reject_reason_counts: Dictionary = {}
var _daily_rejects: Dictionary = {}
```

**实现要点**:
1. 验证链的基本结构（title, objectives, rewards等）
2. 检查防护栏规则（内容安全、平衡性）
3. 签名去重（避免重复生成相似内容）
4. 值预算检查（防止过度奖励）

**预计行数**: 230-270行

---

### Phase 3: AgenticThemeManager

**职责**: 主题选择、轮换策略、玩家偏好学习

**需要提取的函数**:
```gdscript
_select_theme(reason: Dictionary) -> String
_record_theme_usage(theme: String) -> void
_get_preferred_themes() -> Array[String]
_should_rotate_theme() -> bool
_get_last_used_theme() -> String
```

**需要的成员变量**:
```gdscript
var _recent_theme_history: Array[String] = []
var _player_pref_scores: Dictionary = {}
var _continuity_hint: String = ""
```

**实现要点**:
1. 智能主题选择算法（考虑历史、偏好、连续性）
2. 主题轮换避免重复
3. 玩家偏好学习（基于完成情况）
4. 主题历史记录管理

**预计行数**: 180-220行

---

### Phase 4: AgenticCropCatalog

**职责**: 作物数据加载、季节映射、作物查询

**需要提取的函数**:
```gdscript
_load_crop_catalog() -> void
_get_crop_season(crop_id: String) -> String
_get_crops_for_season(season: String) -> Array[String]
_is_crop_valid_for_season(crop_id: String, season: String) -> bool
```

**需要的成员变量**:
```gdscript
const CROP_DATA_PATH := "res://data/farm/crops.json"
var _crop_seasons_by_id: Dictionary = {}
```

**实现要点**:
1. 从JSON文件加载作物数据
2. 建立作物ID到季节的映射
3. 提供便捷的查询接口
4. 缓存数据避免重复加载

**预计行数**: 130-170行

---

### Phase 5: AgenticPerformanceMonitor

**职责**: 生成统计、失败率跟踪、断路器管理

**需要提取的函数**:
```gdscript
_record_success() -> void
_record_failure(reason: String) -> void
_should_breaker_open() -> bool
_maybe_reopen_breaker() -> void
_get_stats() -> Dictionary
_emit_runtime_status() -> void
```

**需要的成员变量**:
```gdscript
var _stats: Dictionary = {"attempted": 0, "published": 0, "failed": 0}
var _consecutive_failures: int = 0
var _breaker_state: String = "open"
var _breaker_last_closed_day: int = -1
var _failure_pressure: Dictionary = {"streak": 0, "last_day": -1}
```

**实现要点**:
1. 跟踪生成成功/失败次数
2. 断路器模式（连续失败时暂停生成）
3. 自动恢复机制（半开状态测试）
4. 实时状态报告

**预计行数**: 130-170行

---

### Phase 6: AgenticFallbackGenerator

**职责**: 程序化链生成、安全回退、降级策略

**需要提取的函数**:
```gdscript
_build_procedural_chain(theme: String, objective: String) -> Dictionary
_try_safe_fallback_chain(theme: String) -> Dictionary
_generate_chain_via_ai(theme: String, objective: String) -> Dictionary
```

**需要的依赖**:
- AdvancedAIAgentManager（AI调用）
- 程序化生成逻辑

**实现要点**:
1. AI优先生成（调用LLM）
2. 程序化回退（基于模板）
3. 安全回退（保证有内容可用）
4. 降级策略链

**预计行数**: 180-220行

---

### Phase 7: 重构主协调器

**目标**: 将 agentic_content_orchestrator.gd 从1,805行精简到~300行

**保留的核心逻辑**:
```gdscript
func maybe_generate_for_day(narrative: Dictionary = {}) -> void:
    # 1. 检查是否应该生成
    if not _should_generate():
        return
    
    # 2. 检查手动队列
    var manual_chain = chain_storage.take_manual_chain()
    if not manual_chain.is_empty():
        return _process_manual_chain(manual_chain)
    
    # 3. 选择主题
    var theme = theme_manager.select_theme(reason)
    
    # 4. 生成链（AI或回退）
    var chain_data = await fallback_generator.generate_chain(theme, objective)
    
    # 5. 验证
    if not validator.validate(chain_data):
        performance_monitor.record_failure("validation_failed")
        return
    
    # 6. 保存和发布
    chain_storage.add_runtime_chain(chain_data.id)
    performance_monitor.record_success()
```

**删除的代码**:
- 所有已迁移到子模块的函数
- 重复的存储逻辑
- 内联的验证逻辑
- 硬编码的主题选择

**预计最终行数**: 250-300行

---

### Phase 8: 集成测试和清理

**测试清单**:
- [ ] 存储模块：加载/保存正确
- [ ] 验证模块：有效链通过，无效链拒绝
- [ ] 主题模块：主题选择不重复
- [ ] 作物模块：季节映射正确
- [ ] 监控模块：统计准确，断路器工作
- [ ] 回退模块：AI失败时能回退
- [ ] 主协调器：端到端流程正常

**清理工作**:
- 删除原文件中已迁移的代码
- 更新Autoload注册
- 更新文档引用
- 性能回归测试

---

## 🔧 实施策略

### 策略A: 并行开发（推荐用于团队）

1. 每个开发者负责1-2个模块
2. 同时开发，最后集成
3. 需要清晰的接口定义

**优点**: 速度快（1-2天）  
**缺点**: 需要多人协作

---

### 策略B: 串行开发（适合单人）

1. 按Phase 2-7顺序逐个完成
2. 每完成一个模块立即测试
3. 最后重构主协调器

**优点**: 风险低，易于调试  
**缺点**: 速度慢（4-5天）

---

### 策略C: 渐进式迁移（最安全）

1. 创建新模块但不立即使用
2. 逐步将原函数的调用改为新模块
3. 确认无误后删除旧代码

**优点**: 零风险，可随时回滚  
**缺点**: 过渡期代码冗余

---

## 💡 快速开始模板

### 新模块基础结构

```gdscript
extends Node
## ModuleName - Brief description.
## 
## Responsibilities:
## - Responsibility 1
## - Responsibility 2

# === 常量 ===

const SOME_CONSTANT := "value"

# === 成员变量 ===

var _internal_state: Dictionary = {}

# === 信号 ===

signal something_happened(data: Dictionary)

# === 生命周期方法 ===

func _ready() -> void:
	_initialize()

# === 公共方法 ===

func public_api(param: String) -> Dictionary:
	"""Public method documentation"""
	pass

# === 私有方法 ===

func _internal_helper() -> void:
	"""Internal helper documentation"""
	pass
```

---

## 📊 预期成果

### 重构前后对比

| 指标 | 重构前 | 重构后 | 改善 |
|------|--------|--------|------|
| **主文件大小** | 1,805行 | ~300行 | **-83%** |
| **模块数量** | 1个 | 7个 | **+600%** |
| **平均模块大小** | 1,805行 | ~200行 | **-89%** |
| **函数数/文件** | 86 | 10-15 | **-85%** |
| **可测试性** | 困难 | 容易 | **+90%** |
| **可维护性** | 困难 | 容易 | **+85%** |

---

## ⚠️ 注意事项

### 1. 保持向后兼容

在过渡期，确保外部调用者的接口不变：

```gdscript
# 原文件保留兼容层
func old_api():
    return new_module.new_api()
```

### 2. 信号连接

确保所有信号正确连接：

```gdscript
# 在主协调器的_ready中
chain_storage.runtime_chain_added.connect(_on_chain_added)
validator.validation_failed.connect(_on_validation_failed)
```

### 3. 初始化顺序

Autoload的初始化顺序很重要：

```
1. AgenticChainStorage
2. AgenticChainValidator
3. AgenticThemeManager
4. AgenticCropCatalog
5. AgenticPerformanceMonitor
6. AgenticFallbackGenerator
7. AgenticContentOrchestrator (主协调器)
```

### 4. 错误处理

每个模块应该有完善的错误处理：

```gdscript
func do_something() -> Dictionary:
    if not _is_initialized:
        return {"ok": false, "error": "Not initialized"}
    
    # ... logic
    
    return {"ok": true, "result": result}
```

---

## 🚀 下一步行动

### 立即执行

1. **阅读本指南**，理解整体架构
2. **选择实施策略**（推荐策略B或C）
3. **开始Phase 2**：创建AgenticChainValidator

### 短期目标（1周内）

- 完成所有7个模块
- 通过集成测试
- 删除旧代码

### 中期目标（1个月内）

- 性能基准测试
- 文档完善
- 团队培训

---

## 📝 提交规范

每个Phase完成后提交：

```bash
git commit -m "refactor: Create AgenticChainValidator module (Phase 2)

- Extracted validation logic from orchestrator
- Implements chain template validation
- Guardrail checks and signature deduplication
- 250 lines, single responsibility

Part of agentic_content_orchestrator refactoring"
```

---

## 🎯 成功标准

重构成功的标志：

- ✅ 所有模块独立测试通过
- ✅ 主协调器 < 350行
- ✅ 无功能回归
- ✅ 性能无下降
- ✅ 代码审查通过
- ✅ 文档更新完成

---

**指南版本**: 1.0  
**最后更新**: 2026-04-21  
**维护者**: AI Assistant  
**相关文档**: [REFACTORING_ANALYSIS_AGGENTIC_ORCHESTRATOR.md](./REFACTORING_ANALYSIS_AGGENTIC_ORCHESTRATOR.md)
