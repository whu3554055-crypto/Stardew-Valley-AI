extends SceneTree

## 场景诊断工具 - 作为主循环运行

func _init():
	print("========================================")
	print("Scene File Diagnostic Tool")
	print("========================================\n")
	
	var scene_path = "res://scenes/world/world_farm.tscn"
	
	print("检查场景: ", scene_path)
	print()
	
	# 1. 检查文件是否存在
	if not FileAccess.file_exists(scene_path):
		print("❌ 错误: 场景文件不存在!")
		quit(1)
		return
	
	print("✅ 文件存在")
	
	# 2. 读取并解析场景文件
	var file = FileAccess.open(scene_path, FileAccess.READ)
	if not file:
		print("❌ 错误: 无法打开文件")
		quit(1)
		return
	
	var content = file.get_as_text()
	file.close()
	
	# 3. 检查场景头部
	if not content.begins_with("[gd_scene"):
		print("❌ 错误: 文件格式不正确")
		quit(1)
		return
	
	print("✅ 文件格式正确")
	
	# 4. 提取 load_steps
	var load_steps_match = RegEx.new()
	load_steps_match.compile("load_steps=(\\d+)")
	var result = load_steps_match.search(content)
	var declared_load_steps = 0
	
	if result:
		declared_load_steps = int(result.get_string(1))
		print("📊 声明的 load_steps: ", declared_load_steps)
	
	# 5. 统计实际资源数量
	var ext_resource_count = count_pattern(content, "\\[ext_resource")
	var sub_resource_count = count_pattern(content, "\\[sub_resource")
	var total_resources = ext_resource_count + sub_resource_count
	
	print("📊 ext_resource 数量: ", ext_resource_count)
	print("📊 sub_resource 数量: ", sub_resource_count)
	print("📊 总资源数量: ", total_resources)
	
	if total_resources != declared_load_steps:
		print("⚠️  警告: load_steps 与实际资源数量不匹配!")
	else:
		print("✅ load_steps 匹配")
	
	# 6. 检查所有外部资源路径
	print("\n检查外部资源依赖:")
	var ext_resource_regex = RegEx.new()
	ext_resource_regex.compile('\\[ext_resource[^\\]]*path="([^"]+)"')
	var ext_results = ext_resource_regex.search_all(content)
	
	var all_deps_ok = true
	for ext_result in ext_results:
		var dep_path = ext_result.get_string(1)
		if not dep_path.begins_with("res://"):
			continue
		
		if not FileAccess.file_exists(dep_path):
			print("  ❌ 缺失: ", dep_path)
			all_deps_ok = false
		else:
			print("  ✅ 存在: ", dep_path)
	
	if all_deps_ok:
		print("✅ 所有依赖都存在")
	
	# 7. 检查脚本语法
	print("\n检查脚本依赖:")
	var script_regex = RegEx.new()
	script_regex.compile('\\[ext_resource type="Script" path="([^"]+)"')
	var script_results = script_regex.search_all(content)
	
	var all_scripts_ok = true
	for script_result in script_results:
		var script_path = script_result.get_string(1)
		
		if not FileAccess.file_exists(script_path):
			print("  ❌ 脚本缺失: ", script_path)
			all_scripts_ok = false
			continue
		
		# 尝试加载脚本检查语法
		var script = load(script_path)
		if script == null:
			print("  ❌ 脚本加载失败（可能有语法错误）: ", script_path)
			all_scripts_ok = false
		else:
			print("  ✅ 脚本正常: ", script_path)
	
	if all_scripts_ok:
		print("✅ 所有脚本都正常")
	
	# 8. 尝试加载场景
	print("\n尝试加载场景...")
	var packed_scene = load(scene_path)
	if packed_scene == null:
		print("❌ 场景加载失败 - 这是 Error 19 的根本原因")
		print("\n建议的修复步骤:")
		print("1. 在 Godot 编辑器中打开 scenes/world/world_farm.tscn")
		print("2. 检查是否有错误提示")
		print("3. 按 Ctrl+S 重新保存场景")
		print("4. 菜单: Project -> Clear Cache Files")
		print("5. 重启 Godot 编辑器")
		quit(1)
		return
	
	print("✅ 场景加载成功")
	
	# 9. 尝试实例化
	print("\n尝试实例化场景...")
	var instance = packed_scene.instantiate()
	if instance == null:
		print("❌ 场景实例化失败")
		quit(1)
		return
	
	print("✅ 场景实例化成功")
	instance.free()
	
	print("\n========================================")
	print("诊断完成 - 场景文件正常!")
	print("========================================")
	print("\n如果游戏中仍然出现 Error 19，请：")
	print("1. 清理 .godot/editor 缓存文件夹")
	print("2. 重启 Godot 编辑器")
	print("3. 重新运行游戏")
	
	quit(0)


func count_pattern(text: String, pattern: String) -> int:
	var regex = RegEx.new()
	regex.compile(pattern)
	var results = regex.search_all(text)
	return results.size()
