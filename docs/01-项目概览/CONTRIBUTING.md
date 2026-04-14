# 贡献指南 (Contributing Guide)

欢迎为 Stardew Valley Clone 项目做出贡献！本指南将帮助您快速上手。

## 📋 目录

- [开发环境设置](#开发环境设置)
- [项目结构](#项目结构)
- [工作流程](#工作流程)
- [代码规范](#代码规范)
- [提交规范](#提交规范)
- [测试要求](#测试要求)
- [文档规范](#文档规范)

---

## 开发环境设置

### 本地开发（推荐用于 Godot 开发）

**必需软件：**
- **Godot Engine 4.2+** - [下载地址](https://godotengine.org/download)
- **Python 3.11+** - 后端服务
- **Git** - 版本控制

**可选工具：**
- **VS Code** - Python 和文档编辑
- **GitHub Desktop** - Git GUI 客户端

### Codespaces 开发（推荐用于后端/文档）

1. 点击仓库页面的 "Code" > "Codespaces" > "Create codespace on main"
2. 等待环境自动配置（约 2-3 分钟）
3. 开始开发！

**注意：** Godot 图形编辑器建议在本地使用，Codespaces 适合：
- Python 后端开发
- 文档编写
- 配置文件管理
- 代码审查

### 环境验证

```bash
# 验证 Godot 安装
godot --version  # 应显示 4.2.x

# 验证 Python 环境
cd hello_agent_backend
python --version  # 应显示 3.11+
pip install -r requirements.txt

# 运行测试套件
pytest tests/ -v
```

---

## 项目结构

```
stardew_valley/
├── autoload/              # Godot 单例（全局管理器）
│   ├── season_manager.gd
│   └── weather_controller.gd
├── environment_system/    # 环境系统模块
│   ├── data_models/       # 数据模型定义
│   └── items/             # 环境物品实现
├── hello_agent_backend/   # Python 后端服务
│   ├── app/               # FastAPI 应用
│   ├── agents/            # Agent 逻辑
│   └── tests/             # Python 测试
├── data/                  # 配置文件和数据
│   └── environment_configs/
├── docs/                  # 技术文档
│   ├── 01-技术架构与优化/
│   └── 03-研发管理/
├── tests/                 # Godot 测试
│   └── unit/
└── .github/               # GitHub 配置
    └── workflows/         # CI/CD 工作流
```

---

## 工作流程

### 1. Fork 和克隆

```bash
# Fork 仓库后克隆到本地
git clone https://github.com/YOUR_USERNAME/stardew_valley.git
cd stardew_valley

# 添加上游远程仓库
git remote add upstream https://github.com/ORIGINAL_OWNER/stardew_valley.git
```

### 2. 创建分支

```bash
# 同步最新代码
git fetch upstream
git checkout main
git merge upstream/main

# 创建功能分支
git checkout -b feature/your-feature-name
# 或
git checkout -b fix/issue-description
```

**分支命名规范：**
- `feature/xxx` - 新功能
- `fix/xxx` - Bug 修复
- `docs/xxx` - 文档更新
- `refactor/xxx` - 代码重构
- `test/xxx` - 测试相关

### 3. 开发和提交

```bash
# 进行修改...

# 查看变更
git status
git diff

# 提交变更（遵循提交规范）
git add .
git commit -m "feat: add fireplace environment item"

# 推送到远程
git push origin feature/your-feature-name
```

### 4. 创建 Pull Request

1. 访问 GitHub 仓库页面
2. 点击 "Compare & pull request"
3. 填写 PR 描述（使用模板）
4. 等待 CI 检查通过
5. 请求代码审查
6. 合并到主分支

---

## 代码规范

### GDScript 规范

```gdscript
# ✅ 好的示例
extends Node2D
class_name EnvironmentItem

## 简短的类描述
## 详细的功能说明

signal effect_changed(item_id: String, new_value: float)

@export var item_id: String = ""
@export var temperature_delta: float = 0.0

var _private_var: int = 0  # 下划线表示私有


func initialize_item() -> void:
    """初始化物品配置。

    从外部 JSON 文件加载配置，如果不存在则使用默认值。

    Returns:
        void
    """
    if item_id.is_empty():
        push_error("[EnvironmentItem] item_id is required")
        return

    _load_config()
    print("[EnvironmentItem] Initialized: %s" % item_id)


func get_current_effects() -> Dictionary:
    """获取当前环境影响效果。

    Returns:
        Dictionary 包含所有效果值
    """
    return {
        "temperature": temperature_delta,
        "humidity": humidity_delta
    }
```

**关键规则：**
- ✅ 始终使用类型注解 (`: String`, `-> void`)
- ✅ 公共函数必须有 docstring（三引号注释）
- ✅ 使用 `push_error()` / `push_warning()` 进行错误处理
- ✅ 变量名使用 `snake_case`
- ✅ 常量使用 `UPPER_CASE`
- ❌ 不要使用未类型的变量 (`var x = 10` ❌ → `var x: int = 10` ✅)

### Python 规范

遵循 [PEP 8](https://peps.python.org/pep-0008/) 和 [Black](https://black.readthedocs.io/) 格式化标准。

```python
# ✅ 好的示例
from typing import Dict, Optional
from fastapi import FastAPI

app = FastAPI()


async def get_npc_memory(npc_id: str, limit: int = 10) -> Dict:
    """Retrieve NPC memory entries from vector database.

    Args:
        npc_id: Unique identifier for the NPC
        limit: Maximum number of memories to retrieve

    Returns:
        Dictionary containing memory entries and metadata

    Raises:
        ValueError: If npc_id is empty
        ConnectionError: If database connection fails
    """
    if not npc_id:
        raise ValueError("npc_id cannot be empty")

    try:
        memories = await query_vector_db(npc_id, limit)
        return {"memories": memories, "count": len(memories)}
    except ConnectionError as e:
        logger.error(f"Database connection failed: {e}")
        raise
```

**关键规则：**
- ✅ 使用 Black 格式化代码 (`black .`)
- ✅ 函数必须有类型注解和 docstring
- ✅ 使用 async/await 处理异步操作
- ✅ 异常必须被捕获并记录日志
- ❌ 不要使用裸 `except:` 子句

---

## 提交规范

遵循 [Conventional Commits](https://www.conventionalcommits.org/) 规范。

### 格式

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Type 类型

- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档更新
- `style`: 代码格式（不影响功能）
- `refactor`: 代码重构
- `test`: 添加或修改测试
- `chore`: 构建过程或辅助工具变动

### 示例

```bash
# 新功能
git commit -m "feat(environment): add air conditioner item with cooling effects"

# Bug 修复
git commit -m "fix(season-manager): correct season transition day calculation"

# 文档更新
git commit -m "docs(readme): add installation instructions for Windows"

# 重构
git commit -m "refactor(weather): extract probability logic to separate function"

# 测试
git commit -m "test(environment-item): add unit tests for energy system"
```

---

## 测试要求

### Godot 测试

所有新功能必须包含单元测试，覆盖率目标 >80%。

```gdscript
# tests/unit/test_your_feature.gd

func test_your_functionality() -> void:
    print("--- Test: Your Functionality ---")

    var obj = YourClass.new()
    obj.initialize()

    assert_eq(obj.get_value(), expected, "Value should match expected")
    assert_true(obj.is_active, "Object should be active")

    obj.queue_free()
    print("PASS: Your functionality works\n")
```

**运行测试：**
```bash
godot --headless --script res://tests/run_tests.gd
```

### Python 测试

```python
# hello_agent_backend/tests/test_your_module.py

import pytest


async def test_get_npc_memory():
    """Test NPC memory retrieval."""
    result = await get_npc_memory("npc_001", limit=5)

    assert "memories" in result
    assert result["count"] <= 5
    assert isinstance(result["memories"], list)
```

**运行测试：**
```bash
cd hello_agent_backend
pytest tests/ -v --cov=.
```

---

## 文档规范

### 技术文档

- 使用中文简体编写
- 文件命名使用数字前缀排序（如 `01-概述.md`）
- 包含目录、示例代码、图表
- 更新时同步更新相关文档

### 代码注释

```gdscript
# ✅ 好的注释
func calculate_damage(base_damage: float, modifier: float) -> float:
    """计算最终伤害值。

    考虑基础伤害、季节修正和天气影响。

    Args:
        base_damage: 基础伤害值
        modifier: 伤害修正系数

    Returns:
        最终伤害值（至少为 1.0）
    """
    # 季节修正（冬季伤害降低 20%）
    var season_modifier = SeasonManager.get_damage_modifier()

    # 确保最小伤害
    return max(1.0, base_damage * modifier * season_modifier)
```

**原则：**
- ✅ 解释 **为什么**（Why），而不是 **做什么**（What）
- ✅ 复杂逻辑必须注释
- ✅ 公开 API 必须有完整 docstring
- ❌ 不要注释显而易见的代码

---

## Pull Request 流程

### PR 检查清单

在提交 PR 前，请确认：

- [ ] 代码遵循项目规范
- [ ] 添加了必要的测试
- [ ] 所有测试通过
- [ ] 更新了相关文档
- [ ] 提交信息符合规范
- [ ] 没有泄露敏感信息（密钥、密码等）
- [ ] CI/CD 检查通过

### PR 描述模板

```markdown
## 描述
简要说明此 PR 的目的和解决的问题。

## 变更类型
- [ ] Bug 修复
- [ ] 新功能
- [ ] 文档更新
- [ ] 代码重构
- [ ] 其他（请说明）

## 测试
描述如何测试这些变更：
- [ ] 单元测试已添加
- [ ] 手动测试已完成
- [ ] 集成测试已通过

## 截图（如适用）
添加界面变更的截图。

## 相关问题
链接到此 PR 解决的问题（如 `Fixes #123`）
```

---

## 沟通渠道

- **Issues**: Bug 报告和功能建议
- **Discussions**: 讨论想法和问题
- **Pull Requests**: 代码审查和反馈

---

## 行为准则

我们致力于提供友好、包容的开发环境。请：

- ✅ 尊重他人观点
- ✅ 建设性地批评代码，而非个人
- ✅ 接受反馈并积极改进
- ❌ 不进行人身攻击或歧视性言论

---

## 许可协议

贡献的代码将采用与项目相同的许可协议。请确保您有权贡献所提交的代码。

---

感谢您的贡献！🎉
