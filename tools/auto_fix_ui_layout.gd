extends SceneTree

## 自动修复 UI 布局问题
## 为所有 Control 节点添加 layout_mode 属性

func _init():
	print("========================================")
	print("Auto-fix UI Layout Issues")
	print("========================================\n")
	
	var scenes_to_fix = [
		"res://scenes/main.tscn",
		"res://scenes/world/world_beach.tscn",
		"res://scenes/world/world_beach_stub.tscn",
		"res://scenes/world/world_cave.tscn",
		"res://scenes/world/world_farm.tscn",
		"res://scenes/world/world_forest.tscn",
		"res://scenes/world/world_forest_stub.tscn",
		"res://scenes/world/world_mine.tscn",
		"res://scenes/world/world_mine_stub.tscn",
		"res://scenes/world/world_playground.tscn",
		"res://scenes/world/world_town.tscn",
		"res://scenes/world/world_town_stub.tscn",
	]
	
	var fixed_count = 0
	
	for scene_path in scenes_to_fix:
		if fix_scene(scene_path):
			fixed_count += 1
	
	print("\n========================================")
	print("修复完成! 共修复 %d 个场景" % fixed_count)
	print("========================================")
	
	quit(0)


func fix_scene(scene_path: String) -> bool:
	if not FileAccess.file_exists(scene_path):
		print("⚠️  文件不存在: ", scene_path)
		return false
	
	print("\n处理: ", scene_path.replace("res://", ""))
	
	var file = FileAccess.open(scene_path, FileAccess.READ)
	if not file:
		print("  ❌ 无法打开文件")
		return false
	
	var content = file.get_as_text()
	file.close()
	
	var lines = content.split("\n")
	var modified = false
	var new_lines = []
	
	for line in lines:
		# 检查是否是 Control 节点定义行
		if line.begins_with("[node name=") and ("type=\"Label\"" in line or "type=\"Panel\"" in line or "type=\"Button\"" in line or "type=\"Control\"" in line):
			new_lines.append(line)
			# 在下一行添加 layout_mode
			new_lines.append("layout_mode = 1")
			modified = true
			print("  ✅ 添加 layout_mode 到: ", line.get_slice('"', 1))
		else:
			new_lines.append(line)
	
	if modified:
		# 保存修改后的文件
		var output = "\n".join(new_lines)
		var write_file = FileAccess.open(scene_path, FileAccess.WRITE)
		if write_file:
			write_file.store_string(output)
			write_file.close()
			print("  💾 已保存")
		else:
			print("  ❌ 无法保存文件")
			return false
	else:
		print("  ⏭️  无需修改")
	
	return true
