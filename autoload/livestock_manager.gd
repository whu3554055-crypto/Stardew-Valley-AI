# autoload/livestock_manager.gd
extends Node
## 畜牧 MVP：畜栏区购买动物、按游戏日收取产物；数据在 `GameManager.player_data.livestock_animals`。

const CONFIG_PATH := "res://data/farm/livestock.json"

var _cfg: Dictionary = {}
var _animal_defs: Dictionary = {}
var _buy_order: Array = []

func _ready() -> void:
	_load_config()


func _load_config() -> void:
	_cfg = {}
	_animal_defs = {}
	_buy_order = []
	var f: FileAccess = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if f == null:
		push_warning("[LivestockManager] Missing %s" % CONFIG_PATH)
		return
	var json := JSON.new()
	if json.parse(f.get_as_text()) != OK:
		f.close()
		push_warning("[LivestockManager] JSON parse error: %s" % CONFIG_PATH)
		return
	f.close()
	var data: Variant = json.data
	if data is Dictionary:
		_cfg = data
	_animal_defs = _cfg.get("animal_types", {})
	_buy_order = _cfg.get("buy_order", [])


func barn_rect() -> Rect2:
	var a: Variant = _cfg.get("barn_zone", [])
	if a is Array and (a as Array).size() >= 4:
		var ar: Array = a as Array
		return Rect2(float(ar[0]), float(ar[1]), float(ar[2]), float(ar[3]))
	return Rect2(920, 285, 200, 140)


func contains_barn(pos: Vector2) -> bool:
	return barn_rect().has_point(pos)


func _game_day_ordinal() -> int:
	if not GameManager:
		return 0
	var y: int = int(GameManager.player_data.get("year", 1))
	var d: int = int(GameManager.player_data.get("day", 1))
	var s: String = str(GameManager.player_data.get("season", "spring")).to_lower()
	var seasons: PackedStringArray = PackedStringArray(["spring", "summer", "fall", "winter"])
	var si: int = 0
	for i in seasons.size():
		if seasons[i] == s:
			si = i
			break
	return (y - 1) * 112 + si * 28 + d


func _ensure_animals_array() -> Array:
	if not GameManager:
		return []
	if not GameManager.player_data.has("livestock_animals"):
		GameManager.player_data["livestock_animals"] = []
	var arr: Variant = GameManager.player_data["livestock_animals"]
	if arr is Array:
		return arr as Array
	GameManager.player_data["livestock_animals"] = []
	return GameManager.player_data["livestock_animals"] as Array


func count_type(type_id: String) -> int:
	var n: int = 0
	for a in _ensure_animals_array():
		if str((a as Dictionary).get("type", "")) == type_id:
			n += 1
	return n


func _next_animal_id() -> String:
	var arr: Array = _ensure_animals_array()
	var max_n: int = 0
	for a in arr:
		var id: String = str((a as Dictionary).get("id", ""))
		if id.begins_with("lv_"):
			var tail: String = id.substr(3)
			if tail.is_valid_int():
				max_n = maxi(max_n, tail.to_int())
	return "lv_%d" % (max_n + 1)


func _def(type_id: String) -> Dictionary:
	var d: Variant = _animal_defs.get(type_id, {})
	return d if d is Dictionary else {}


func try_buy_next_type() -> Dictionary:
	## Returns { "ok": bool, "message": String }
	if not GameManager or not InventoryManager:
		return {"ok": false, "message": "no_game"}
	for type_id in _buy_order:
		var def: Dictionary = _def(str(type_id))
		if def.is_empty():
			continue
		var max_o: int = int(def.get("max_owned", 99))
		if count_type(str(type_id)) >= max_o:
			continue
		var cost: int = int(def.get("buy_gold", 0))
		var gold: int = int(GameManager.player_data.get("gold", 0))
		if gold < cost:
			return {"ok": false, "message": "cant_afford", "type": str(type_id), "cost": cost}
		GameManager.player_data["gold"] = gold - cost
		var animal: Dictionary = {
			"id": _next_animal_id(),
			"type": str(type_id),
			"last_collect_ordinal": _game_day_ordinal()
		}
		_ensure_animals_array().append(animal)
		return {"ok": true, "message": "bought", "type": str(type_id), "cost": cost}
	return {"ok": false, "message": "all_full"}


func try_collect_all() -> Dictionary:
	## Returns ok/empty/inventory_full; `collected` is Array of { item_id, qty, animal_type } for UI copy.
	var lines: PackedStringArray = PackedStringArray()
	var tips: PackedStringArray = PackedStringArray()
	var collected: Array = []
	if not GameManager or not InventoryManager or not ItemDatabase:
		return {"ok": false, "lines": lines, "tips": tips, "collected": collected}
	var ord_now: int = _game_day_ordinal()
	var arr: Array = _ensure_animals_array()
	if arr.is_empty():
		return {"ok": false, "lines": lines, "tips": tips, "collected": collected, "empty": true}
	var any: bool = false
	for entry in arr:
		var a: Dictionary = entry as Dictionary
		var tid: String = str(a.get("type", ""))
		var def: Dictionary = _def(tid)
		if def.is_empty():
			continue
		var interval: int = maxi(1, int(def.get("days_between", 1)))
		var last: int = int(a.get("last_collect_ordinal", 0))
		if ord_now < last + interval:
			continue
		var item_id: String = str(def.get("produce_item_id", ""))
		var amt: int = maxi(1, int(def.get("produce_amount", 1)))
		var tpl: Dictionary = ItemDatabase.get_item(item_id)
		if tpl.is_empty():
			push_warning("[LivestockManager] Unknown produce item: %s" % item_id)
			continue
		for _i in amt:
			if not InventoryManager.add_item(tpl.duplicate(true)):
				return {"ok": any, "lines": lines, "tips": tips, "collected": collected, "inventory_full": true}
		a["last_collect_ordinal"] = ord_now
		any = true
		var nm: String = str(tpl.get("name", item_id))
		lines.append("Livestock: collected %s ×%d (%s)" % [nm, amt, tid])
		tips.append("%s ×%d" % [nm, amt])
		collected.append({"item_id": item_id, "qty": amt, "animal_type": tid})
	return {"ok": any, "lines": lines, "tips": tips, "collected": collected}
