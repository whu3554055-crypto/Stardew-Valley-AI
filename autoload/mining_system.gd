extends Node

const GT := preload("res://scripts/gathering_tables.gd")

## Bounds must match Main scene node `MineArea` (global AABB used for point test).
const MINE_GLOBAL_X_MIN := 70.0
const MINE_GLOBAL_X_MAX := 310.0
const MINE_GLOBAL_Y_MIN := 300.0
const MINE_GLOBAL_Y_MAX := 520.0
## Global Y boundaries between depth tiers — must match `MineArea` layer polygons in `main.tscn`.
const MINE_GLOBAL_DEPTH_BREAK_1 := 380.0
const MINE_GLOBAL_DEPTH_BREAK_2 := 460.0

var _last_swing_time: float = -100.0
const SWING_COOLDOWN_SEC := 1.2

func can_mine_here(player_pos: Vector2) -> bool:
	return player_pos.x >= MINE_GLOBAL_X_MIN and player_pos.x <= MINE_GLOBAL_X_MAX \
		and player_pos.y >= MINE_GLOBAL_Y_MIN and player_pos.y <= MINE_GLOBAL_Y_MAX

func depth_from_global_y(global_y: float) -> int:
	return _depth_from_y(global_y)

func _depth_from_y(player_y: float) -> int:
	if player_y < MINE_GLOBAL_DEPTH_BREAK_1:
		return 0
	if player_y < MINE_GLOBAL_DEPTH_BREAK_2:
		return 1
	return 2

func _pickaxe_tier(pickaxe_id: String) -> int:
	match pickaxe_id:
		"pickaxe_iron":
			return 2
		"pickaxe":
			return 1
		_:
			return 0

func try_swing(player_pos: Vector2, pickaxe_id: String) -> Dictionary:
	if not can_mine_here(player_pos):
		return {"ok": false, "message": ""}
	var tier := _pickaxe_tier(pickaxe_id)
	if tier <= 0:
		return {"ok": false, "message": "You need a pickaxe."}
	if GameManager and not GameManager.try_consume_stamina(6.0):
		return {"ok": false, "message": "Too tired to mine."}

	var now: float = Time.get_ticks_msec() / 1000.0
	if now - _last_swing_time < SWING_COOLDOWN_SEC:
		return {"ok": false, "message": "You catch your breath..."}
	_last_swing_time = now
	if GatheringSfx:
		GatheringSfx.play_mine_swing()

	var depth := _depth_from_y(player_pos.y)
	var weights: Dictionary = GT.mining_ore_weights(depth, tier)
	var item_id: String = _weighted_pick(weights)
	if item_id.is_empty():
		item_id = "stone_chunk"
	var res: Dictionary = _grant_ore(item_id, "", depth, tier)
	if res.get("ok", false) and depth >= 2 and tier == 1 and str(res.get("item_id", "")) == "stone_chunk":
		var rh: float = randf()
		if rh < 0.14:
			res["hint"] = "Deep gold is stubborn — try an iron pickaxe on the lowest band."
		elif rh < 0.24:
			res["hint"] = "Pale glints in this band — silver needs the deep vein and an iron pick."
	return res

func _weighted_pick(weights: Dictionary) -> String:
	var total := 0.0
	for k in weights.keys():
		total += float(weights[k])
	if total <= 0.0:
		return ""
	var r: float = randf() * total
	for k in weights.keys():
		r -= float(weights[k])
		if r <= 0.0:
			return str(k)
	for k in weights.keys():
		return str(k)
	return ""

func _grant_ore(item_id: String, empty_msg: String, _depth: int = 0, _tier: int = 0) -> Dictionary:
	var template: Dictionary = ItemDatabase.get_item(item_id)
	if template.is_empty():
		return {"ok": false, "message": "Mine yielded nothing (missing item data)."}
	if not InventoryManager.add_item(template.duplicate(true)):
		return {"ok": false, "message": "Inventory full."}
	if GatheringAlmanac:
		GatheringAlmanac.record_mineral(item_id)
	if QuestSystem:
		QuestSystem.track_event("mine_ore", {"ore_id": item_id, "count": 1})
	var msg: String = empty_msg
	if msg.is_empty():
		var nm: String = str(template.get("name", item_id))
		if item_id == "quartz":
			msg = "A chip of %s catches the light." % nm
		elif item_id == "geode":
			msg = "A rattling %s — the surface layer hides curios." % nm
		elif item_id == "gold_ore":
			msg = "Rich vein! Mined: %s" % nm
		elif item_id == "silver_ore":
			msg = "Pale glint in the rock — %s." % nm
		elif item_id == "amethyst_shard":
			msg = "A violet flash — %s, rare in the deep band." % nm
		elif item_id == "coal":
			msg = "Black seams — %s for the furnace." % nm
		elif item_id == "copper_ore":
			msg = "Greenish flecks — %s." % nm
		elif item_id == "iron_ore":
			msg = "Heavy grey — %s." % nm
		elif item_id == "stone_chunk":
			msg = "The wall crumbles — %s." % nm
		else:
			msg = "Mined: %s" % nm
	var prefix: String = GT.mining_layer_prefix(_depth)
	if not prefix.is_empty():
		msg = "%s %s" % [prefix, msg]
	return {"ok": true, "message": msg, "item_id": item_id}
