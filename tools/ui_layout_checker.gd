extends SceneTree

## Godot 工业标准检查工具
## 用于扫描项目中的 UI 布局问题并生成报告

func _init():
	print("========================================")
	print("Godot Industrial Standards Checker")
	print("========================================\n")
	
	var project_path = "res://"
	var issues = []
	
	# 检查所有场景文件
	check_scenes(project_path, issues)
	
	# 检查所有脚本文件
	check_scripts(project_path, issues)
	
	# 生成报告
	generate_report(issues)
	
	print("\n========================================")
	print("检查完成！共发现 %d 个问题" % issues.size())
	print("详细报告已保存到: res://docs/UI_LAYOUT_AUDIT.md")
	print("========================================")


func check_scenes(base_path: String, issues: Array):
	"""检查场景文件中的 UI 布局问题"""
	var dir = DirAccess.open(base_path)
	if not dir:
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		var full_path = base_path.path_join(file_name)
		
		if dir.current_is_dir():
			# 递归检查子目录（跳过 .godot 和 addons）
			if file_name not in [".godot", "addons", ".git"]:
				check_scenes(full_path, issues)
		elif file_name.ends_with(".tscn"):
			check_scene_file(full_path, issues)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()


func check_scene_file(file_path: String, issues: Array):
	"""检查单个场景文件"""
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return
	
	var content = file.get_as_text()
	file.close()
	
	var lines = content.split("\n")
	var line_num = 0
	
	for line in lines:
		line_num += 1
		
		# 检查硬编码的 offset 值（超过一定范围的绝对值）
		if "offset_left" in line or "offset_top" in line or "offset_right" in line or "offset_bottom" in line:
			if is_hardcoded_offset(line):
				issues.append({
					"type": "HARDCODED_OFFSET",
					"file": file_path,
					"line": line_num,
					"content": line.strip_edges(),
					"suggestion": "使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值"
				})
		
		# 检查是否缺少 layout_mode
		if "[node name=" in line and ("type=\"Control\"" in line or "type=\"Panel\"" in line or "type=\"Label\"" in line):
			# 检查后续几行是否有 layout_mode
			var has_layout_mode = false
			for i in range(line_num, min(line_num + 10, lines.size())):
				if "layout_mode" in lines[i]:
					has_layout_mode = true
					break
			
			if not has_layout_mode and "layout_mode" not in content.substr(content.find(line), 500):
				issues.append({
					"type": "MISSING_LAYOUT_MODE",
					"file": file_path,
					"line": line_num,
					"content": line.strip_edges(),
					"suggestion": "为 Control 节点添加 layout_mode 属性以启用现代布局系统"
				})


func check_scripts(base_path: String, issues: Array):
	"""检查脚本文件中的 UI 创建问题"""
	var dir = DirAccess.open(base_path)
	if not dir:
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		var full_path = base_path.path_join(file_name)
		
		if dir.current_is_dir():
			if file_name not in [".godot", "addons", ".git"]:
				check_scripts(full_path, issues)
		elif file_name.ends_with(".gd"):
			check_script_file(full_path, issues)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()


func check_script_file(file_path: String, issues: Array):
	"""检查单个脚本文件"""
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return
	
	var content = file.get_as_text()
	file.close()
	
	var lines = content.split("\n")
	var line_num = 0
	
	for line in lines:
		line_num += 1
		
		# 检查动态创建 UI 时的硬编码 offset
		if ".offset_left =" in line or ".offset_top =" in line:
			if "=" in line and not "#" in line.split("=")[1]:  # 不是注释
				var value = line.split("=")[1].strip_edges()
				if value.replace(".", "").replace("-", "").is_valid_float():
					issues.append({
						"type": "SCRIPT_HARDCODED_OFFSET",
						"file": file_path,
						"line": line_num,
						"content": line.strip_edges(),
						"suggestion": "使用 set_anchors_preset() 和 size_flags 代替硬编码 offset"
					})
		
		# 检查是否使用了正确的锚点预设
		if "set_anchors_preset" in line:
			# 好的做法，记录但不报错
			pass


func is_hardcoded_offset(line: String) -> bool:
	"""判断是否是硬编码的 offset 值"""
	# 排除合理的相对偏移（小数值或使用变量）
	if "=" not in line:
		return false
	
	var value_part = line.split("=")[1]
	
	# 如果是表达式或变量引用，不算硬编码
	if "+" in value_part or "-" in value_part or "*" in value_part or "/" in value_part:
		return false
	if "viewport" in value_part.to_lower() or "size" in value_part.to_lower():
		return false
	
	# 检查是否是大数值的硬编码（超过 200 像素的绝对值）
	var numbers = extract_numbers(value_part)
	for num in numbers:
		if abs(num) > 200:
			return true
	
	return false


func extract_numbers(text: String) -> Array:
	"""从文本中提取数字"""
	var numbers = []
	var regex = RegEx.new()
	regex.compile("-?\\d+\\.?\\d*")
	
	var results = regex.search_all(text)
	for result in results:
		var num_str = result.get_string()
		if num_str.is_valid_float():
			numbers.append(float(num_str))
	
	return numbers


func generate_report(issues: Array):
	"""生成审计报告"""
	var report = "# UI 布局审计报告\n\n"
	report += "**生成时间**: %s\n\n" % Time.get_datetime_string_from_system()
	report += "**问题总数**: %d\n\n" % issues.size()
	
	# 按类型分组
	var grouped = {}
	for issue in issues:
		var type = issue.type
		if not grouped.has(type):
			grouped[type] = []
		grouped[type].append(issue)
	
	# 生成统计
	report += "## 问题统计\n\n"
	report += "| 问题类型 | 数量 |\n"
	report += "|---------|------|\n"
	for type in grouped.keys():
		report += "| %s | %d |\n" % [type, grouped[type].size()]
	report += "\n---\n\n"
	
	# 详细问题列表
	for type in grouped.keys():
		report += "## %s\n\n" % get_type_description(type)
		
		for issue in grouped[type]:
			var relative_path = issue.file.replace("res://", "")
			report += "### 📄 %s:%d\n\n" % [relative_path, issue.line]
			report += "**代码**:\n```gdscript\n%s\n```\n\n" % issue.content
			report += "**建议**: %s\n\n" % issue.suggestion
			report += "---\n\n"
	
	# 修复指南
	report += generate_fix_guide()
	
	# 保存报告
	var file = FileAccess.open("res://docs/UI_LAYOUT_AUDIT.md", FileAccess.WRITE)
	if file:
		file.store_string(report)
		file.close()
		print("\n✅ 审计报告已保存到: res://docs/UI_LAYOUT_AUDIT.md")
	else:
		print("\n❌ 无法保存审计报告")
	
	quit(0)


func get_type_description(type: String) -> String:
	match type:
		"HARDCODED_OFFSET":
			return "🔴 硬编码 Offset 值 - 场景文件"
		"MISSING_LAYOUT_MODE":
			return "🟡 缺少 Layout Mode - 场景文件"
		"SCRIPT_HARDCODED_OFFSET":
			return "🔴 硬编码 Offset 值 - 脚本文件"
		_:
			return type


func generate_fix_guide() -> String:
	var guide = """
## 🔧 修复指南

### 1. 硬编码 Offset 修复示例

#### ❌ 错误做法
```gdscript
panel.offset_left = 924.0
panel.offset_top = 44.0
panel.offset_right = 1276.0
panel.offset_bottom = 632.0
```

#### ✅ 正确做法
```gdscript
# 方法 1: 使用锚点预设
panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
panel.offset_left = -352.0  # 从右边缘向左偏移
panel.offset_top = 44.0
panel.offset_right = -4.0
panel.offset_bottom = 632.0

# 方法 2: 使用容器自动布局
var vbox = VBoxContainer.new()
vbox.add_theme_constant_override("separation", 8)
parent.add_child(vbox)

var panel = Panel.new()
panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
vbox.add_child(panel)
```

### 2. 响应式布局最佳实践

```gdscript
# 监听视口变化
get_viewport().size_changed.connect(_on_viewport_resized)

func _on_viewport_resized():
    var viewport_size = get_viewport().get_visible_rect().size
    
    # 基于屏幕比例计算尺寸
    var panel_width = viewport_size.x * 0.3  # 占屏幕宽度 30%
    var panel_height = viewport_size.y * 0.5  # 占屏幕高度 50%
    
    # 更新 UI
    my_panel.custom_minimum_size = Vector2(panel_width, panel_height)
```

### 3. 容器选择指南

- **垂直列表**: `VBoxContainer`
- **水平排列**: `HBoxContainer`
- **网格布局**: `GridContainer`
- **滚动区域**: `ScrollContainer`
- **居中对齐**: `CenterContainer`
- **添加边距**: `MarginContainer`

### 4. 批量修复脚本

对于大量需要修复的场景，可以使用以下 GDScript 辅助函数：

```gdscript
func convert_to_responsive_layout(control: Control, preset: int):
    control.set_anchors_preset(preset)
    control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    control.size_flags_vertical = Control.SIZE_EXPAND_FILL
```

---

## 📚 参考资源

- [Godot UI 系统文档](https://docs.godotengine.org/en/stable/tutorials/ui/index.html)
- [控制节点大小调整](https://docs.godotengine.org/en/stable/tutorials/ui/controlling_3d_gui.html)
- [本项目 Godot 工业标准](res://docs/GODOT_INDUSTRIAL_STANDARDS.md)
"""
	return guide
