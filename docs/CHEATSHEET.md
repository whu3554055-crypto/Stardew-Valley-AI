# 快速参考卡片 - 星露谷AI项目

> **用途**: 日常快速查阅关键信息  
> **更新**: 每周Sprint结束时更新

---

## 📅 当前进度

```
日期: 2026-04-06
阶段: Milestone 1 - 技术基础重构
Sprint: 1/14
完成度: 5%

下一个里程碑: M1 (04-30) - 还有24天
```

---

## 🎯 今日重点

### 技术任务
- [ ] 集成godot-sqlite GDExtension
- [ ] 设计数据库Schema
- [ ] 编写DatabaseManager单例

### 商务任务
- [ ] 注册Steam开发者账号
- [ ] 创建社交媒体账号

---

## 📊 关键指标

### 技术指标
```
目标FPS: 60
当前FPS: ___ (F3查看)
内存占用: ___ MB
活跃NPC数: ___
AI缓存大小: ___
```

### 业务指标
```
Steam愿望单: ___
Discord成员: ___
Twitter粉丝: ___
Beta申请者: ___
```

---

## 🔧 常用命令

### Godot开发
```bash
# 运行游戏
godot scenes/main.tscn

# 导出项目
godot --export "Windows Desktop" export/game.exe

# 运行测试
godot --test

# 性能profiling
# 游戏中按F3
```

### Git工作流
```bash
# 开始新功能
git checkout -b feature/xxx

# 提交代码
git add .
git commit -m "feat: 添加SQLite集成"
git push origin feature/xxx

# 合并到主分支
# 通过GitHub PR
```

### 数据库操作
```gdscript
# 查询示例
var db = DatabaseManager.get_instance()
var result = db.query("SELECT * FROM npc_memories WHERE npc_id='pierre'")

# 插入数据
db.insert("npc_memories", {
    "id": "mem_001",
    "npc_id": "pierre",
    "content": "Met the player",
    "importance": 0.5
})
```

---

## 📞 紧急联系

| 角色 | 联系人 | 方式 |
|------|--------|------|
| 主程 | @___ | Discord/电话 |
| AI工程师 | @___ | Discord/电话 |
| 美术 | @___ | Discord |
| PM | @___ | Discord/电话 |

---

## ⚠️ 已知问题

### P0 - 阻塞性
- [ ] 问题描述...

### P1 - 重要
- [ ] 问题描述...

### P2 - 一般
- [ ] 问题描述...

---

## 📚 文档快速链接

### 核心文档
- [执行摘要](00-执行摘要.md) - 决策者必读
- [技术方案](01-技术架构与优化/01-技术架构升级方案.md)
- [商业方案](02-商业运营/01-商业运营方案.md)
- [研发计划](03-研发管理/01-研发周期与里程碑.md)

### 实用工具
- [OPTIMIZATION_GUIDE.md](../OPTIMIZATION_GUIDE.md) - 性能优化
- [QUICK_START_OPTIMIZATION.md](../QUICK_START_OPTIMIZATION.md) - 15分钟快速优化
- [IMPLEMENTATION_CHECKLIST.md](../IMPLEMENTATION_CHECKLIST.md) - 实施清单

---

## 💡 每日提示

### Day 1-5: 数据库周
**Tip**: SQLite事务是原子性的,利用这个特性保证数据完整性

### Day 6-10: 向量搜索周
**Tip**: LanceDB支持元数据过滤,结合向量相似度和条件查询

### Day 11-15: 社交图周
**Tip**: BFS遍历适合找社交圈,Dijkstra适合找最短路径

---

## 🎮 测试检查清单

### 每日冒烟测试
- [ ] 游戏能正常启动
- [ ] 玩家可以移动
- [ ] NPC可以对话
- [ ] 存档/读档正常
- [ ] 无崩溃

### 每周回归测试
- [ ] 所有任务可完成
- [ ] 所有NPC可互动
- [ ] 性能指标达标
- [ ] 多语言切换正常
- [ ] 手柄支持完整

---

## 📈 Sprint燃尽图

```
Story Points:
计划: ___
完成: ___
剩余: ___

Burndown:
Day 1: ████████
Day 2: ███████
Day 3: ██████
...
```

---

## 🌟 本周成就

- [ ] 完成SQLite集成
- [ ] 零P0 Bug
- [ ] FPS稳定60
- [ ] 获得第一个玩家好评
- [ ] ...

---

## 📝 会议记录

### Daily Standup
```
昨天做了:
今天要做:
遇到阻碍:
```

### Sprint Review
```
完成的功能:
待改进的:
下Sprint计划:
```

---

## 🔗 外部资源

### 学习
- [Godot官方文档](https://docs.godotengine.org/)
- [SQLite教程](https://www.sqlitetutorial.net/)
- [LanceDB文档](https://lancedb.github.io/lancedb/)

### 社区
- [Godot中文社区](https://godotengine.org/zh-cn/community)
- [独立游戏开发](https://indienova.com/)
- [r/gamedev](https://www.reddit.com/r/gamedev/)

---

## 💭 灵感记录

**游戏设计想法**:
- ...

**技术优化思路**:
- ...

**营销活动创意**:
- ...

---

**记住**: 每天进步1%,7个月后就是10倍提升! 🚀

**最后更新**: 2026-04-06
