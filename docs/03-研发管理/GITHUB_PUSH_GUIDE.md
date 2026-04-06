# GitHub 推送快速指南（使用 GitHub Desktop）

本文档指导您如何使用 GitHub Desktop 将项目推送到 GitHub（完全免费）。

---

## ✅ 前置条件

- [x] GitHub Desktop 已安装并登录
- [x] 项目已在本地完成开发
- [x] `.gitignore` 文件已配置

---

## 📋 步骤 1：在 GitHub 创建仓库（网页端）

1. **访问 GitHub**
   - 打开浏览器，访问 https://github.com
   - 登录您的账号

2. **创建新仓库**
   - 点击右上角 **"+"** 图标 > **"New repository"**
   - 或直接访问：https://github.com/new

3. **填写仓库信息**
   ```
   Repository name: stardew_valley
   Description: AI-driven farming simulation with intelligent NPCs and multi-LLM provider system
   Visibility: ⚫ Private（私有）或 🌐 Public（公开，推荐展示作品）
   ```
   
   **⚠️ 重要：不要勾选以下选项：**
   - ❌ Initialize this repository with a README
   - ❌ Add .gitignore
   - ❌ Choose a license

4. **点击 "Create repository"**

5. **复制仓库 URL**
   - 页面会显示快速设置说明
   - 复制 HTTPS URL，例如：
     ```
     https://github.com/YOUR_USERNAME/stardew_valley.git
     ```

---

## 💻 步骤 2：使用 Git 初始化本地仓库（命令行）

打开 **PowerShell** 或 **Git Bash**，在项目根目录执行：

```powershell
# 进入项目目录
cd d:\repo\stardew_valley

# 初始化 Git 仓库
git init

# 添加所有文件到暂存区
git add .

# 创建初始提交
git commit -m "Initial commit: Complete environment system and multi-LLM integration

Features:
- Season, Weather, Environment Item systems (Godot)
- Multi-LLM provider router (Ollama, Qwen, Gemini)
- FastAPI backend with smart routing
- Comprehensive documentation and tests

🤖 Generated with Lingma"

# 添加远程仓库（替换为您的实际用户名）
git remote add origin https://github.com/YOUR_USERNAME/stardew_valley.git

# 重命名分支为 main
git branch -M main

# 推送到 GitHub
git push -u origin main
```

**如果遇到错误：**

### 错误 1: "Please tell me who you are"
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### 错误 2: "Authentication failed"
- 使用 GitHub Desktop 登录即可自动处理认证
- 或创建 Personal Access Token：https://github.com/settings/tokens

### 错误 3: "Large files detected"
检查 `.gitignore` 是否正确排除了大文件。

---

## 🖥️ 步骤 3：使用 GitHub Desktop 推送（图形界面，推荐）

如果您更喜欢图形界面：

### 方法 A：添加现有仓库

1. **打开 GitHub Desktop**

2. **添加本地仓库**
   - 点击 **"File"** > **"Add local repository"**
   - 点击 **"Choose..."**
   - 选择 `d:\repo\stardew_valley` 文件夹
   - 如果提示 "This directory does not appear to be a Git repository"
   - 点击 **"create a repository"** 链接

3. **填写仓库信息**
   ```
   Name: stardew_valley
   Description: AI-driven farming simulation
   Git Ignore: None (we already have .gitignore)
   License: None
   README: None
   ```

4. **点击 "Create Repository"**

5. **发布到 GitHub**
   - 点击顶部的 **"Publish repository"** 按钮
   - 确认名称和描述
   - 取消勾选 "Keep this code private"（如果想公开）
   - 点击 **"Publish Repository"**

6. **完成！**
   - 您的代码已推送到 GitHub
   - 可以在浏览器中访问查看

### 方法 B：克隆空仓库后复制文件

如果方法 A 遇到问题：

1. **在 GitHub 创建空仓库**（步骤 1 已完成）

2. **使用 GitHub Desktop 克隆**
   - 点击 **"File"** > **"Clone repository"**
   - 选择您的 `stardew_valley` 仓库
   - 选择本地路径（如 `d:\repo\stardew_valley_new`）
   - 点击 **"Clone"**

3. **复制项目文件**
   - 将 `d:\repo\stardew_valley` 的所有文件复制到新克隆的文件夹
   - **注意：** 不要覆盖 `.git` 文件夹

4. **提交更改**
   - GitHub Desktop 会检测到所有新文件
   - 在左下角输入提交信息：
     ```
     Initial commit: Complete project setup
     
     - Environment system (Season, Weather, Items)
     - Multi-LLM provider integration
     - FastAPI backend
     - Documentation and tests
     ```
   - 点击 **"Commit to main"**

5. **推送**
   - 点击 **"Push origin"** 按钮

---

## ✅ 步骤 4：验证推送成功

1. **访问 GitHub 仓库页面**
   ```
   https://github.com/YOUR_USERNAME/stardew_valley
   ```

2. **检查文件结构**
   应该看到：
   - ✅ autoload/
   - ✅ environment_system/
   - ✅ hello_agent_backend/
   - ✅ docs/
   - ✅ README.md
   - ✅ .gitignore

3. **检查 README 渲染**
   - README.md 应该正确显示格式化的内容
   - 徽章（badges）可能暂时显示为灰色（CI 未配置）

---

## 🔒 免费功能使用指南

GitHub 提供的**免费功能**完全满足您的需求：

### ✅ 免费包含

| 功能 | 限制 | 是否够用 |
|------|------|---------|
| **仓库存储** | 每个仓库 ≤ 1GB | ✅ 足够（当前项目 ~50MB） |
| **带宽** | 每月 100GB | ✅ 足够 |
| **协作者** | 无限 | ✅ 足够 |
| **Issues** | 无限 | ✅ 足够 |
| **Projects** | 最多 5 个 | ✅ 足够 |
| **Actions (CI/CD)** | 每月 2000 分钟 | ✅ 足够 |
| **Pages (静态网站)** | 1GB 存储 | ✅ 足够 |
| **Packages** | 500MB 存储 | ✅ 足够 |

### ❌ 付费功能（不需要）

| 功能 | 用途 | 是否需要 |
|------|------|---------|
| **GitHub Codespaces** | 云端开发环境 | ❌ 您已选择本地开发 |
| **Advanced Security** | 企业级安全扫描 | ❌ 个人项目不需要 |
| **Support** | 优先技术支持 | ❌ 社区支持足够 |

**结论：** 免费套餐完全够用！无需付费。

---

## 📊 后续操作建议

### 1. 设置仓库元数据

在 GitHub 仓库页面：

1. **添加 Topics（主题标签）**
   - 点击右侧 "About" 区域的齿轮图标
   - 添加 topics：
     ```
     godot-engine
     gamedev
     ai
     npc
     farming-simulation
     python
     fastapi
     llm
     ollama
     open-source
     ```

2. **设置网站预览**
   - 上传一个项目截图作为 social preview
   - Settings > Social preview > Upload

### 2. 邀请协作者（可选）

Settings > Collaborators > Add people

### 3. 启用 Issues（问题追踪）

确保 Settings > Features > Issues 已勾选

### 4. 创建第一个 Release（可选）

当项目达到稳定版本时：
1. 点击 "Releases" > "Create a new release"
2. 标签：v1.0.0
3. 标题：Initial Release
4. 描述主要功能

---

## 🐛 常见问题

### Q1: 推送速度很慢？

**解决方案：**
- 检查网络连接
- 使用代理（如果需要）
- 分批推送大文件

### Q2: 提交了敏感信息（API Key）怎么办？

**立即操作：**
1. 撤销该 API Key（在提供商后台）
2. 生成新的 Key
3. 从 Git 历史中删除敏感文件：
   ```bash
   git filter-branch --force --index-filter \
     'git rm --cached --ignore-unmatch hello_agent_backend/.env' \
     --prune-empty --tag-name-filter cat -- --all
   ```
4. 强制推送：
   ```bash
   git push --force --all
   ```

**预防：** 确保 `.env` 在 `.gitignore` 中

### Q3: 如何更新已推送的代码？

```bash
# 修改文件后
git add .
git commit -m "feat: your changes"
git push
```

或使用 GitHub Desktop：
1. 修改文件
2. Desktop 自动检测更改
3. 输入提交信息
4. 点击 "Commit" > "Push"

### Q4: 如何回滚错误的提交？

**使用 GitHub Desktop：**
1. 右键点击要回滚到的提交
2. 选择 "Revert this commit"
3. 推送 revert commit

**使用命令行：**
```bash
git revert <commit-hash>
git push
```

---

## 📚 相关文档

- [GitHub Projects 设置](GITHUB_PROJECTS_SETUP.md)
- [完整迁移指南](GITHUB_MIGRATION_GUIDE.md)
- [贡献指南](../CONTRIBUTING.md)

---

## ✅ 最终检查清单

推送前确认：

- [ ] 在 GitHub 创建了空仓库
- [ ] 复制了仓库 URL
- [ ] 本地已运行 `git init`
- [ ] 已添加所有文件（`git add .`）
- [ ] 已创建初始提交（`git commit -m "..."`）
- [ ] 已添加远程（`git remote add origin URL`）
- [ ] 已推送（`git push -u origin main`）
- [ ] 在 GitHub 页面验证文件存在

---

祝您推送顺利！🚀

如有问题，请参考本文档或查阅 GitHub 官方文档：https://docs.github.com/
