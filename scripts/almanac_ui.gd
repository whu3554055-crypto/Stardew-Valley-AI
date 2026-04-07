extends Panel

@onready var fish_list: ItemList = $Margin/VBox/FishItemList
@onready var mineral_list: ItemList = $Margin/VBox/MineralItemList
@onready var smelt_list: ItemList = $Margin/VBox/SmeltItemList
@onready var meal_list: ItemList = $Margin/VBox/MealItemList

func _ready() -> void:
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.06, 0.07, 0.09, 0.96)
	psb.set_border_width_all(1)
	psb.border_color = Color(0.38, 0.34, 0.24)
	psb.content_margin_left = 10
	psb.content_margin_top = 10
	psb.content_margin_right = 10
	psb.content_margin_bottom = 10
	add_theme_stylebox_override("panel", psb)
	for lst in [fish_list, mineral_list, smelt_list, meal_list]:
		if lst:
			lst.add_theme_font_size_override("font_size", 13)
			lst.add_theme_color_override("font_selected_color", Color(0.98, 0.9, 0.55))
			lst.add_theme_color_override("font_hovered_color", Color(0.92, 0.92, 0.94))
	var vbox: Node = get_node_or_null("Margin/VBox")
	if vbox:
		for c in vbox.get_children():
			if c is Label:
				var lb: Label = c as Label
				lb.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.42))
				lb.add_theme_constant_override("shadow_offset_x", 1)
				lb.add_theme_constant_override("shadow_offset_y", 1)
	if GatheringAlmanac:
		GatheringAlmanac.collection_updated.connect(_on_collection_updated)
	visibility_changed.connect(_on_visibility_changed)
	refresh()

func _on_visibility_changed() -> void:
	if visible:
		refresh()

func _on_collection_updated() -> void:
	refresh()

func refresh() -> void:
	if not fish_list or not mineral_list or not smelt_list or not meal_list or not GatheringAlmanac:
		return
	fish_list.clear()
	mineral_list.clear()
	smelt_list.clear()
	meal_list.clear()
	var fish_ids: Array = GatheringAlmanac.fish_caught.keys()
	fish_ids.sort()
	for fid in fish_ids:
		var n: int = int(GatheringAlmanac.fish_caught.get(fid, 0))
		var nm: String = str(ItemDatabase.get_item(str(fid)).get("name", fid))
		fish_list.add_item("%s  ×%d" % [nm, n])
	var ore_ids: Array = GatheringAlmanac.minerals_mined.keys()
	ore_ids.sort()
	for oid in ore_ids:
		var n2: int = int(GatheringAlmanac.minerals_mined.get(oid, 0))
		var nm2: String = str(ItemDatabase.get_item(str(oid)).get("name", oid))
		mineral_list.add_item("%s  ×%d" % [nm2, n2])
	var bar_ids: Array = GatheringAlmanac.smelted_bars.keys()
	bar_ids.sort()
	for bid in bar_ids:
		var n3: int = int(GatheringAlmanac.smelted_bars.get(bid, 0))
		var nm3: String = str(ItemDatabase.get_item(str(bid)).get("name", bid))
		smelt_list.add_item("%s  ×%d" % [nm3, n3])
	var meal_ids: Array = GatheringAlmanac.meals_cooked.keys()
	meal_ids.sort()
	for mid in meal_ids:
		var n4: int = int(GatheringAlmanac.meals_cooked.get(mid, 0))
		var nm4: String = str(ItemDatabase.get_item(str(mid)).get("name", mid))
		meal_list.add_item("%s  ×%d" % [nm4, n4])
