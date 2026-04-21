extends SceneTree

## 批量诊断所有世界场景

func _init():
	print("========================================")
	print("Batch Scene Diagnostic Tool")
	print("========================================\n")
	
	var scene_paths = [
		"res://scenes/world/world_town.tscn",
		"res://scenes/world/world_forest.tscn",
		"res://scenes/world/world_beach.tscn",
		"res://scenes/world/world_mine.tscn",
		"res://scenes/world/world_cave.tscn",
		"res://scenes/world/world_playground.tscn",
	]
	
	var results = []
	
	for scene_path in scene_paths:
		print("\n检查: ", scene_path)
		print("-".repeat(50))
		
		var result = check_scene(scene_path)
		results.append({"path": scene_path, "ok": result})
		
		if result:
			print("✅ 通过")
		else:
			print("❌ 失败")
	
	# 总结
	print("\n" + "=".repeat(50))
	print("诊断总结:")
	print("=".repeat(50))
	
	var pass_count = 0
	var fail_count = 0
	
	for r in results:
		var status = "✅" if r.ok else "❌"
		var short_path = r.path.replace("res://scenes/world/", "")
		print("%s %s" % [status, short_path])
		if r.ok:
			pass_count += 1
		else:
			fail_count += 1
	
	print("\n总计: %d 通过, %d 失败" % [pass_count, fail_count])
	
	if fail_count > 0:
		print("\n⚠️  有场景存在问题，请查看上面的详细输出")
		quit(1)
	else:
		print("\n✅ 所有场景都正常!")
		quit(0)


func check_scene(scene_path: String) -> bool:
	# 检查文件是否存在
	if not FileAccess.file_exists(scene_path):
		print("  ❌ 文件不存在")
		return false
	
	# 尝试加载场景
	var packed_scene = load(scene_path)
	if packed_scene == null:
		print("  ❌ 加载失败")
		return false
	
	# 尝试实例化
	var instance = packed_scene.instantiate()
	if instance == null:
		print("  ❌ 实例化失败")
		return false
	
	instance.free()
	print("  ✅ 加载和实例化成功")
	return true
