@tool
extends EditorScript

## 简化版 UI 布局检查器 - 快速测试版本

func _run():
	print("========================================")
	print("UI Layout Checker - Quick Test")
	print("========================================\n")
	
	var issues = []
	
	# 只检查 main.gd 作为测试
	check_script_file("res://scenes/main.gd", issues)
	
	print("\n发现的问题: %d" % issues.size())
	for issue in issues:
		print("\n[%s] %s:%d" % [issue.type, issue.file, issue.line])
		print("  代码: %s" % issue.content)
		print("  建议: %s" % issue.suggestion)
	
	print("\n========================================")
	print("测试完成！")
	print("========================================")


func check_script_file(file_path: String, issues: Array):
	"""检查单个脚本文件"""
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("无法打开文件: " + file_path)
		return
	
	var content = file.get_as_text()
	file.close()
	
	var lines = content.split("\n")
	var line_num = 0
	
	for line in lines:
		line_num += 1
		
		# 检查动态创建 UI 时的硬编码 offset
		if ".offset_left =" in line or ".offset_top =" in line or ".offset_right =" in line or ".offset_bottom =" in line:
			if "=" in line:
				var parts = line.split("=")
				if parts.size() > 1:
					var value_part = parts[1].strip_edges()
					# 排除注释
					if not value_part.begins_with("#"):
						# 检查是否是数字
						var clean_value = value_part.replace(".", "").replace("-", "").replace(" ", "")
						if clean_value.is_valid_float():
							var num_val = float(clean_value)
							if abs(num_val) > 200:  # 大数值可能是硬编码
								issues.append({
									"type": "HARDCODED_OFFSET",
									"file": file_path,
									"line": line_num,
									"content": line.strip_edges(),
									"suggestion": "使用 set_anchors_preset() 和响应式计算代替硬编码值"
								})

