extends Node

# 拾取系统
# 管理地面上的可拾取物品

signal item_picked_up(item_id: String, quantity: int)

var pickup_items = {}

func _ready():
	print("拾取系统初始化")

func register_pickup_item(position: Vector2, item_id: String, quantity: int = 1):
	"""注册一个可拾取物品到地面"""
	var item_data = {
		"item_id": item_id,
		"quantity": quantity,
		"position": position,
		"sprite": create_item_sprite(item_id, position)
	}

	pickup_items[item_id + "_" + str(position)] = item_data
	print("物品生成: ", item_id, " x", quantity, " at ", position)

func create_item_sprite(item_id: String, position: Vector2) -> Sprite2D:
	"""创建物品精灵"""
	var sprite = Sprite2D.new()

	# 加载物品图标
	var item_path = "res://assets/sprites/items/"
	var item_texture = null

	# 根据物品ID确定路径
	if item_id in ["parsnip", "potato", "carrot", "tomato", "corn", "pumpkin"]:
		item_texture = load(item_path + "crops/" + item_id + ".png")
	elif item_id in ["wood", "stone", "iron_ore", "gold_ore"]:
		item_texture = load(item_path + "resources/" + item_id + ".png")
	elif item_id in ["health_potion", "energy_drink", "bread", "salad"]:
		item_texture = load(item_path + "consumables/" + item_id + ".png")

	if item_texture:
		sprite.texture = item_texture
	else:
		# 使用占位符
		sprite.texture = create_placeholder_texture()

	sprite.position = position
	sprite.scale = Vector2(0.8, 0.8)

	# 添加浮动动画
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(sprite, "position:y", position.y - 5, 1.0)
	tween.tween_property(sprite, "position:y", position.y, 1.0)

	return sprite

func create_placeholder_texture() -> ImageTexture:
	"""创建占位符纹理"""
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 0, 1))  # 黄色方块
	return ImageTexture.create_from_image(img)

func try_pickup(player_position: Vector2) -> Dictionary:
	"""尝试拾取玩家附近的物品"""
	var pickup_range = 50.0

	for key in pickup_items.keys():
		var item = pickup_items[key]
		var distance = player_position.distance_to(item["position"])

		if distance < pickup_range:
			# 拾取成功
			var picked_item = item.duplicate()

			# 移除精灵
			if is_instance_valid(item["sprite"]):
				item["sprite"].queue_free()

			# 从列表中移除
			pickup_items.erase(key)

			# 发射信号
			emit_signal("item_picked_up", picked_item["item_id"], picked_item["quantity"])

			print("拾取: ", picked_item["item_id"], " x", picked_item["quantity"])
			return picked_item

	return {}

func spawn_random_items(area_center: Vector2, count: int = 5):
	"""在指定区域随机生成物品（测试用）"""
	var items = ["wood", "stone", "parsnip", "carrot"]

	for i in range(count):
		var random_item = items[randi() % items.size()]
		var offset = Vector2(randi() % 200 - 100, randi() % 200 - 100)
		register_pickup_item(area_center + offset, random_item, randi() % 3 + 1)

func get_nearby_items(player_position: Vector2, range_pixels: float = 50.0) -> Array:
	"""获取玩家附近的物品列表"""
	var nearby = []

	for key in pickup_items.keys():
		var item = pickup_items[key]
		var distance = player_position.distance_to(item["position"])

		if distance < range_pixels:
			nearby.append({
				"item_id": item["item_id"],
				"quantity": item["quantity"],
				"distance": distance
			})

	# 按距离排序
	nearby.sort_custom(func(a, b): return a["distance"] < b["distance"])
	return nearby
