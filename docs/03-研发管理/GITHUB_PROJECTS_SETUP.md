# GitHub Projects 设置指南

本文档指导您如何设置和使用 GitHub Projects 来管理 Stardew Valley Clone 项目的开发流程。

---

## 📋 前置条件

- GitHub 账号（免费即可）
- 项目已推送到 GitHub 仓库
- 管理员权限

---

## 🎯 步骤 1：创建 Project Board

### 1.1 访问 Projects

1. 打开您的 GitHub 仓库页面
2. 点击顶部导航栏的 **"Projects"** 标签
3. 点击 **"New project"** 按钮

### 1.2 选择模板

推荐使用 **"Kanban"** 模板（看板模式），它包含以下默认列：
- **Todo** - 待办事项
- **In Progress** - 进行中
- **Done** - 已完成

或者选择 **"Blank"** 模板自定义列。

### 1.3 配置项目名称

- **Project name**: `Stardew Valley AI - Development Board`
- **Description**: `产品级开发任务跟踪看板`
- **Visibility**: Public（公开，便于协作）或 Private（私有）

---

## 🏗️ 步骤 2：自定义看板列

建议设置为以下列结构：

```
┌─────────────┬──────────────┬──────────────┬──────────────┬──────────────┐
│   Backlog   │    Ready     │  In Progress │   Review     │    Done      │
│   待规划     │   准备中      │   进行中      │   审查中      │   已完成      │
└─────────────┴──────────────┴──────────────┴──────────────┴──────────────┘
```

### 列说明：

| 列名 | 用途 | 规则 |
|------|------|------|
| **Backlog** | 所有待办任务池 | 按优先级排序 |
| **Ready** | 已明确需求、可开始的任务 | 必须有清晰描述和验收标准 |
| **In Progress** | 正在开发的任务 | 每人同时最多 2 个任务 |
| **Review** | 等待代码审查的任务 | 必须关联 PR |
| **Done** | 已完成并合并的任务 | 自动归档 |

---

## 📝 步骤 3：添加初始任务卡片

### 3.1 使用 Markdown 创建任务

点击 **"Add item"** 或按 `C` 键快速创建卡片。

**卡片标题格式：**
```
[模块] 任务简述
```

**卡片描述模板：**
```markdown
## 任务描述
简要说明需要做什么

## 验收标准
- [ ] 标准 1
- [ ] 标准 2
- [ ] 单元测试通过
- [ ] 文档已更新

## 技术要点
- 关键点 1
- 关键点 2

## 相关文档
- [链接到设计文档]()
- [链接到 API 文档]()

## 预估工作量
小 / 中 / 大
```

### 3.2 建议的初始任务列表

#### Phase 1: 环境系统（已完成 ✅）
```
✅ [Environment] Implement SeasonManager core logic
✅ [Environment] Implement WeatherController core logic
✅ [Environment] Implement EnvironmentItem base class
✅ [Environment] Create example items (Fireplace, AC, Plant)
✅ [Environment] Write unit tests for environment system
```

#### Phase 2: Hello-Agent Backend Foundation
```
☐ [Backend] Set up FastAPI application structure
☐ [Backend] Implement configuration management (.env, settings.py)
☐ [Backend] Create GameAgent core decision engine
☐ [Backend] Integrate LLM services (Ollama/OpenAI)
☐ [Backend] Add logging and error handling middleware
```

#### Phase 3: Vector Memory System
```
☐ [Memory] Integrate LanceDB for vector storage
☐ [Memory] Implement embedding model service
☐ [Memory] Create NPC memory CRUD operations
☐ [Memory] Add similarity search optimization
☐ [Memory] Write integration tests for memory system
```

#### Phase 4: Godot-Agent Communication
```
☐ [Integration] Implement WebSocket client in Godot
☐ [Integration] Adapt MCP protocol for game events
☐ [Integration] Create tool registry mechanism
☐ [Integration] Add reconnection and error handling
☐ [Integration] Test bidirectional communication
```

#### Phase 5: NPC AI Enhancement
```
☐ [NPC] Implement NPCBehaviorController with agent integration
☐ [NPC] Add daily schedule system
☐ [NPC] Create emotion-mood-behavior pipeline
☐ [NPC] Implement relationship tracking
☐ [NPC] Add multi-language dialogue support
```

---

## 🏷️ 步骤 4：设置标签（Labels）

为任务卡片添加标签以便分类筛选。

### 推荐标签体系：

| 标签 | 颜色 | 用途 |
|------|------|------|
| `feature` | #2E8B57 | 新功能开发 |
| `bug` | #DC143C | Bug 修复 |
| `enhancement` | #1E90FF | 功能优化 |
| `documentation` | #FFD700 | 文档工作 |
| `testing` | #9370DB | 测试相关 |
| `refactoring` | #FF6347 | 代码重构 |
| `high-priority` | #FF0000 | 高优先级 |
| `medium-priority` | #FFA500 | 中优先级 |
| `low-priority` | #808080 | 低优先级 |
| `good-first-issue` | #00CED1 | 适合新手 |
| `needs-discussion` | #FF69B4 | 需要讨论 |

**设置方法：**
1. 点击卡片右侧的 `...` 菜单
2. 选择 **"Edit labels"**
3. 点击 **"Manage project labels"**
4. 创建上述标签

---

## 👥 步骤 5：分配团队成员

### 5.1 邀请协作者

1. 进入仓库 **Settings** > **Collaborators**
2. 点击 **"Add people"**
3. 输入 GitHub 用户名或邮箱

### 5.2 分配任务

在卡片详情中：
1. 点击 **"Assignees"**
2. 选择负责人
3. 可选：添加多个协作者

---

## 🔗 步骤 6：关联 Issues 和 PRs

### 6.1 从 Issue 创建卡片

1. 在 Issue 页面右侧找到 **"Projects"**
2. 点击下拉菜单选择您的 Project
3. 卡片会自动同步状态

### 6.2 自动关联 PR

在 PR 描述中使用关键词：
```markdown
Fixes #123
Closes #456
Resolves #789
```

当 PR 合并时，关联的 Issue 和卡片会自动移动到 **Done** 列。

---

## ⚙️ 步骤 7：配置自动化规则

### 7.1 内置自动化

GitHub Projects 支持简单的工作流自动化：

**示例规则：**
```yaml
When a card is added to "In Progress":
  - Assign to current user

When a PR is opened:
  - Move card to "Review"

When a PR is merged:
  - Move card to "Done"
  - Close associated issues
```

**设置方法：**
1. 点击 Project 页面右上角的 `...` 菜单
2. 选择 **"Workflows"**
3. 启用预设规则或创建自定义规则

### 7.2 高级自动化（可选）

使用 GitHub Actions 实现复杂自动化：

```yaml
# .github/workflows/project-automation.yml
name: Project Automation

on:
  pull_request:
    types: [opened, closed]

jobs:
  update-project:
    runs-on: ubuntu-latest
    steps:
      - name: Move card to Review
        if: github.event.action == 'opened'
        uses: alex-page/github-project-automation-plus@v0.8.3
        with:
          project: "Stardew Valley AI - Development Board"
          column: "Review"
          repo-token: ${{ secrets.GITHUB_TOKEN }}

      - name: Move card to Done
        if: github.event.action == 'closed' && github.event.pull_request.merged == true
        uses: alex-page/github-project-automation-plus@v0.8.3
        with:
          project: "Stardew Valley AI - Development Board"
          column: "Done"
          repo-token: ${{ secrets.GITHUB_TOKEN }}
```

---

## 📊 步骤 8：使用视图（Views）

### 8.1 看板视图（Board View）
- 默认视图
- 适合日常任务管理

### 8.2 表格视图（Table View）
- 类似电子表格
- 适合批量编辑和筛选

**设置筛选器：**
```
Filter by:
  - Assignee: @me
  - Label: high-priority
  - Status: In Progress
```

### 8.3 路线图视图（Roadmap View）
- 时间线展示
- 适合里程碑规划

**设置方法：**
1. 点击 **"Add view"** > **"Roadmap"**
2. 为卡片添加 **Start date** 和 **End date**
3. 按季度或月份分组

---

## 📈 步骤 9：进度跟踪和报告

### 9.1 查看统计信息

在项目页面顶部会显示：
- 总任务数
- 各列任务数
- 完成百分比

### 9.2 使用 Insights

GitHub 仓库的 **Insights** 标签提供：
- 提交活动
- PR 合并趋势
- Issue 关闭率
- 贡献者统计

### 9.3 每周进度报告（手动）

创建周报 Issue 模板：

```markdown
## 本周完成
- 任务 1
- 任务 2

## 进行中
- 任务 3 (预计下周完成)

## 下周计划
- 任务 4
- 任务 5

## 阻塞问题
- 问题 1（需要 XXX 协助）

## 关键指标
- 完成率: X%
- PR 合并数: X
- Bug 修复数: X
```

---

## 🎓 最佳实践

### ✅ 推荐做法

1. **保持卡片小而具体**
   - ❌ "实现 NPC 系统"（太大）
   - ✅ "实现 NPC 对话管理器"（具体）

2. **及时更新状态**
   - 开始工作时立即移到 "In Progress"
   - 完成后立即创建 PR 并移到 "Review"

3. **每个卡片都有清晰验收标准**
   - 避免模糊描述
   - 列出可验证的条件

4. **限制进行中的任务数**
   - 每人同时最多 2-3 个任务
   - 专注完成，避免上下文切换

5. **定期清理 Done 列**
   - 每月归档已完成卡片
   - 保持看板整洁

### ❌ 避免的陷阱

1. **不要创建过多列**
   - 5-7 列是最佳范围
   - 太多列会增加管理成本

2. **不要忘记关联 PR**
   - 始终在 PR 描述中引用 Issue
   - 使用 `Fixes #123` 语法

3. **不要忽略 Backlog 整理**
   - 每两周审查一次 Backlog
   - 删除过时或不再需要的任务

4. **不要过度依赖自动化**
   - 自动化是辅助，不是替代
   - 保持人工审查和判断

---

## 🔗 有用资源

- [GitHub Projects 官方文档](https://docs.github.com/en/issues/planning-and-tracking-with-projects)
- [项目管理最佳实践](https://github.blog/2022-06-08-best-practices-for-using-github-issues/)
- [自动化工作流示例](https://github.com/marketplace?type=actions&query=project)

---

## 💡 快速开始清单

- [ ] 创建 Project Board（Kanban 模板）
- [ ] 设置 5 列：Backlog, Ready, In Progress, Review, Done
- [ ] 添加初始任务卡片（从实施路线图复制）
- [ ] 创建标签体系（feature, bug, priority 等）
- [ ] 邀请团队成员
- [ ] 配置基础自动化（PR 移动卡片）
- [ ] 创建第一个 Sprint 里程碑
- [ ] 开始使用！

---

祝您项目管理顺利！🚀
