# GitHub 迁移完整指南

本文档提供将 Stardew Valley Clone 项目迁移到 GitHub 的完整步骤和最佳实践。

---

## 📋 目录

1. [方案评估与建议](#方案评估与建议)
2. [已完成的准备工作](#已完成的准备工作)
3. [迁移步骤](#迁移步骤)
4. [后续配置](#后续配置)
5. [团队协作建议](#团队协作建议)
6. [常见问题](#常见问题)

---

## 方案评估与建议

### ✅ 推荐方案：混合开发模式

```
┌─────────────────────────────────────────────────────┐
│           推荐的开发架构                              │
├─────────────────────────────────────────────────────┤
│                                                      │
│  GitHub 仓库 (核心)                                  │
│  ├── 代码版本控制                                    │
│  ├── CI/CD 自动化测试                                │
│  ├── Projects 任务管理                               │
│  └── Issues 问题追踪                                 │
│                                                      │
│  本地 Godot 编辑器                                   │
│  ├── 图形化场景编辑                                  │
│  ├── 实时预览和调试                                  │
│  └── 资源文件管理                                    │
│                                                      │
│  Codespaces (可选，用于后端开发)                     │
│  ├── Python 后端开发                                 │
│  ├── 文档编写                                        │
│  └── 代码审查                                        │
│                                                      │
└─────────────────────────────────────────────────────┘
```

### 为什么不强制使用 Codespaces？

| 方面 | 本地 Godot | Codespaces |
|------|-----------|------------|
| **GUI 体验** | ⭐⭐⭐⭐⭐ 原生流畅 | ⭐⭐ 需要远程桌面，延迟高 |
| **性能** | ⭐⭐⭐⭐⭐ 利用本地硬件 | ⭐⭐⭐ 云端资源受限 |
| **成本** | ⭐⭐⭐⭐⭐ 免费 | ⭐⭐⭐ 有限免费额度 |
| **协作** | ⭐⭐⭐ 需手动同步 | ⭐⭐⭐⭐⭐ 即时共享环境 |
| **适用场景** | Godot 开发、场景编辑 | Python 后端、文档、Code Review |

**结论：**
- ✅ **Godot 开发** → 本地编辑器 + Git 提交
- ✅ **Python 后端** → 本地或 Codespaces 均可
- ✅ **文档编写** → Codespaces 很方便
- ✅ **新成员入职** → Codespaces 快速上手

---

## 已完成的准备工作

我们已经为您创建了以下配置文件：

### 1. `.gitignore` ✅
- 排除 Godot 临时文件
- 排除 Python 缓存和虚拟环境
- 排除敏感信息（.env, 密钥等）
- 排除构建产物

### 2. `.devcontainer/devcontainer.json` ✅
- 预配置 Python 3.11 环境
- 自动安装 Godot Engine 4.2.1
- VS Code 扩展推荐
- 端口转发配置（8080, 5678）
- 数据卷挂载（持久化数据库）

### 3. `.github/workflows/ci.yml` ✅
自动化测试流程：
- ✅ Godot 项目结构验证
- ✅ Python 依赖安装和测试
- ✅ JSON 配置文件验证
- ✅ 文档完整性检查
- （可选）Godot 导出测试

### 4. `CONTRIBUTING.md` ✅
完整的贡献指南：
- 开发环境设置
- 代码规范（GDScript + Python）
- 提交信息规范（Conventional Commits）
- Pull Request 流程
- 测试要求

### 5. `README.md` ✅
更新后的项目说明：
- 快速开始指南
- 本地和 Codespaces 设置
- 已完成功能列表
- 文档导航

### 6. `docs/03-研发管理/GITHUB_PROJECTS_SETUP.md` ✅
GitHub Projects 详细设置指南：
- 看板创建和配置
- 任务卡片管理
- 标签体系
- 自动化规则
- 进度跟踪

### 7. 初始化脚本 ✅
- `scripts/init_git_repo.sh` - Linux/Mac 版本
- `scripts/init_git_repo.ps1` - Windows PowerShell 版本

---

## 迁移步骤

### 步骤 1：在 GitHub 创建仓库

1. 访问 https://github.com/new
2. 填写信息：
   - **Repository name**: `stardew_valley`（或您喜欢的名称）
   - **Description**: `AI-driven farming simulation with intelligent NPCs and dynamic environment system`
   - **Visibility**: Public（开源）或 Private（私有）
   - **⚠️ 不要勾选** "Initialize with README"（我们已有）
3. 点击 **"Create repository"**
4. 复制仓库 URL（如 `https://github.com/YOUR_USERNAME/stardew_valley.git`）

### 步骤 2：运行初始化脚本

#### Windows 用户：
```powershell
# 在项目根目录打开 PowerShell
.\scripts\init_git_repo.ps1
```

#### Mac/Linux 用户：
```bash
# 赋予执行权限
chmod +x scripts/init_git_repo.sh

# 运行脚本
./scripts/init_git_repo.sh
```

#### 或者手动执行：
```bash
# 初始化 Git
git init

# 添加所有文件
git add .

# 创建初始提交
git commit -m "Initial commit: Stardew Valley AI Clone project setup"

# 添加远程仓库（替换为您的 URL）
git remote add origin https://github.com/YOUR_USERNAME/stardew_valley.git

# 推送到 GitHub
git branch -M main
git push -u origin main
```

### 步骤 3：验证推送

访问您的 GitHub 仓库页面，确认：
- ✅ 所有文件和文件夹都存在
- ✅ README.md 正确渲染
- ✅ 目录结构完整

---

## 后续配置

### 1. 设置 GitHub Projects

按照 `docs/03-研发管理/GITHUB_PROJECTS_SETUP.md` 的指南：

```
1. 进入仓库 > Projects 标签
2. 点击 "New project"
3. 选择 "Kanban" 模板
4. 设置列：Backlog, Ready, In Progress, Review, Done
5. 添加初始任务卡片（从实施路线图复制）
6. 创建标签体系
```

**快速创建标签：**
```bash
# 使用 GitHub CLI（如果已安装）
gh label create feature --color 2E8B57 --description "新功能开发"
gh label create bug --color DC143C --description "Bug 修复"
gh label create documentation --color FFD700 --description "文档工作"
gh label create high-priority --color FF0000 --description "高优先级"
gh label create good-first-issue --color 00CED1 --description "适合新手"
```

### 2. 配置分支保护规则

1. 进入 **Settings** > **Branches**
2. 点击 **"Add rule"**
3. 分支名称模式：`main`
4. 启用以下规则：
   - ✅ **Require a pull request before merging**
     - Required approvals: 1
   - ✅ **Require status checks to pass before merging**
     - 选择 CI 工作流：`CI - Build and Test`
   - ✅ **Include administrators**（管理员也遵守规则）
   - ✅ **Force pushes**: Block（禁止强制推送）

### 3. 设置仓库元数据

#### 添加 Topics（主题标签）
在仓库主页右侧 "About" 区域，点击齿轮图标，添加：
```
godot-engine
gamedev
ai
npc
farming-simulation
python
fastapi
llm
multiplayer
open-source
```

#### 添加 License
如果需要，添加开源许可证：
```bash
# 在项目根目录创建 LICENSE 文件
# 推荐使用 MIT 或 Apache 2.0
```

示例 MIT License：
```
MIT License

Copyright (c) 2026 Your Name

Permission is hereby granted...
```

### 4. 配置 CI/CD Badge

在 README.md 中更新 CI 状态徽章：

将 `YOUR_USERNAME` 替换为您的实际 GitHub 用户名：
```markdown
[![CI Status](https://github.com/YOUR_USERNAME/stardew_valley/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR_USERNAME/stardew_valley/actions)
```

### 5. 邀请团队成员

1. 进入 **Settings** > **Collaborators**
2. 点击 **"Add people"**
3. 输入成员的 GitHub 用户名或邮箱
4. 选择权限级别：
   - **Read** - 只读（查看代码、Issues）
   - **Write** - 可写（创建分支、PR）
   - **Admin** - 管理（全部权限，包括设置）

---

## 团队协作建议

### 工作流程

```
1. 从 Projects 看板领取任务
   ↓
2. 创建功能分支：git checkout -b feature/xxx
   ↓
3. 本地开发和测试
   ↓
4. 提交代码：git commit -m "feat: xxx"
   ↓
5. 推送到远程：git push origin feature/xxx
   ↓
6. 创建 Pull Request
   ↓
7. 等待 CI 通过和代码审查
   ↓
8. 合并到 main 分支
   ↓
9. 删除功能分支
   ↓
10. 在 Projects 中标记任务完成
```

### 分支命名规范

```
feature/season-manager      # 新功能
fix/weather-bug             # Bug 修复
docs/readme-update          # 文档更新
refactor/npc-system         # 代码重构
test/environment-items      # 测试相关
chore/dependencies          # 依赖更新
```

### 提交信息规范

遵循 Conventional Commits：

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Type 类型：**
- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档
- `style`: 格式（不影响功能）
- `refactor`: 重构
- `test`: 测试
- `chore`: 构建/工具

**示例：**
```bash
git commit -m "feat(environment): add fireplace item with heating effects"
git commit -m "fix(season): correct transition day calculation"
git commit -m "docs(readme): add installation instructions"
```

### Code Review 清单

审查 PR 时检查：
- [ ] 代码遵循项目规范
- [ ] 有适当的单元测试
- [ ] 所有测试通过
- [ ] 更新了相关文档
- [ ] 没有泄露敏感信息
- [ ] 提交信息清晰
- [ ] 代码可读性好
- [ ] 没有明显的性能问题

---

## 常见问题

### Q1: Codespaces 的费用如何计算？

**免费额度（个人用户）：**
- 每月 120 核时（core-hours）
- 2 核机器可用 60 小时
- 4 核机器可用 30 小时

**超出后收费：**
- 2 核：$0.18/小时
- 4 核：$0.36/小时
- 8 核：$0.72/小时

**节省技巧：**
- 不用时停止 Codespace（不删除）
- 使用 2 核机器进行文档/轻量开发
- 只在需要时用 4+ 核机器

### Q2: 如何在本地和 Codespaces 之间同步？

Git 会自动同步！只需：
```bash
# 在任何地方修改后
git add .
git commit -m "your changes"
git push

# 在另一个地方拉取最新代码
git pull
```

### Q3: Godot 项目文件冲突怎么办？

`.godot/` 目录已在 `.gitignore` 中排除，不会冲突。

如果 `project.godot` 冲突：
```bash
# 保留您的版本
git checkout --ours project.godot

# 或保留远程版本
git checkout --theirs project.godot

# 然后手动调整并重新提交
```

### Q4: 如何保护 API 密钥和敏感信息？

**永远不要提交：**
- `.env` 文件
- `credentials.json`
- 任何包含密钥的文件

**使用环境变量：**
```python
# hello_agent_backend/.env.example（提交这个模板）
API_KEY=your_key_here

# hello_agent_backend/.env（在 .gitignore 中，不提交）
API_KEY=actual_secret_key
```

**在代码中读取：**
```python
import os
from dotenv import load_dotenv

load_dotenv()
api_key = os.getenv("API_KEY")
```

### Q5: CI/CD 失败怎么办？

1. 点击 GitHub Actions 标签查看详细日志
2. 找到失败的步骤和错误信息
3. 本地复现问题
4. 修复后重新提交，CI 会自动重新运行

**常见失败原因：**
- Python 语法错误
- 测试未通过
- JSON 格式错误
- 依赖缺失

### Q6: 如何回滚错误的提交？

```bash
# 方法 1：撤销最后一次提交（保留更改）
git reset HEAD~1

# 方法 2：完全撤销（丢弃更改）
git reset --hard HEAD~1

# 方法 3：创建新的还原提交（推荐，安全）
git revert <commit-hash>
git push
```

### Q7: 多人同时修改同一文件怎么办？

Git 会尝试自动合并。如果冲突：

```bash
# 拉取最新代码
git pull

# 如果有冲突，Git 会提示
# 手动编辑冲突文件，解决冲突标记：
<<<<<<< HEAD
your changes
=======
their changes
>>>>>>> branch-name

# 解决后标记为已解决
git add conflicted_file.py
git commit -m "resolve merge conflict"
```

**预防冲突：**
- 频繁同步（每天至少一次 `git pull`）
- 小粒度提交
- 明确分工，避免多人修改同一文件

---

## 快速参考命令

### 日常开发
```bash
# 查看状态
git status

# 查看变更
git diff

# 添加文件
git add .

# 提交
git commit -m "feat: your feature"

# 推送
git push

# 拉取最新
git pull

# 创建分支
git checkout -b feature/xxx

# 切换分支
git switch main
```

### 问题排查
```bash
# 查看提交历史
git log --oneline

# 查看某个文件的历史
git log --follow -- path/to/file.py

# 撤销未提交的更改
git restore filename.py

# 查看远程仓库
git remote -v
```

---

## 下一步行动清单

- [ ] 在 GitHub 创建新仓库
- [ ] 运行初始化脚本推送代码
- [ ] 创建 GitHub Project Board
- [ ] 设置分支保护规则
- [ ] 添加 Topics 和描述
- [ ] 邀请团队成员
- [ ] 创建第一个 Sprint 里程碑
- [ ] 开始分配任务！

---

## 有用链接

- [GitHub 官方文档](https://docs.github.com/)
- [GitHub Projects 指南](https://docs.github.com/en/issues/planning-and-tracking-with-projects)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Godot Engine 官方](https://godotengine.org/)
- [FastAPI 文档](https://fastapi.tiangolo.com/)

---

祝您迁移顺利！如有问题，请查阅本文档或提出 Issue。🚀
