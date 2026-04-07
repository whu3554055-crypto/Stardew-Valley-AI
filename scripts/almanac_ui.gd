extends Panel

@onready var fish_list: ItemList = $Margin/VBox/FishItemList
@onready var mineral_list: ItemList = $Margin/VBox/MineralItemList

func _ready() -> void:
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
	if not fish_list or not mineral_list or not GatheringAlmanac:
		return
	fish_list.clear()
	mineral_list.clear()
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
