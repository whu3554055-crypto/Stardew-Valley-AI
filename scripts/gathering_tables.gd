class_name GatheringTables

## Central weight tables for fishing/mining (gameplay tuning).

static func get_fish_table(zone: String, season: String, hour: int, raining: bool) -> Dictionary:
	# Returns item_id -> relative weight (not normalized).
	var t: Dictionary = {}
	var night := hour < 6 or hour >= 22
	var morning := hour >= 6 and hour < 12
	var afternoon := hour >= 12 and hour < 18

	if zone == "river":
		t["fish_carp"] = 1.2
		t["fish_perch"] = 1.0
		t["fish_trout"] = 0.9 if not night else 1.2
		t["fish_catfish"] = 0.42 if not night else 0.55
		t["junk_boot"] = 0.32
		t["junk_seaweed"] = 0.12
	elif zone == "ocean":
		t["fish_sardine"] = 1.35
		t["fish_perch"] = 0.72
		t["fish_trout"] = 0.48
		t["fish_mackerel"] = 0.58 if afternoon else 0.42
		# Rare ocean prize — more likely at night / summer rain
		t["fish_tuna"] = 0.22 if not night else 0.38
		t["junk_boot"] = 0.36
		t["junk_seaweed"] = 0.55
	else:
		t["junk_boot"] = 1.0

	match season:
		"spring":
			if "fish_trout" in t:
				t["fish_trout"] *= 1.15
		"summer":
			if "fish_sardine" in t:
				t["fish_sardine"] *= 1.2
			if "fish_tuna" in t:
				t["fish_tuna"] *= 1.12
		"fall":
			if "fish_carp" in t:
				t["fish_carp"] *= 1.15
			if "fish_catfish" in t:
				t["fish_catfish"] *= 1.18
		"winter":
			if "fish_perch" in t:
				t["fish_perch"] *= 1.1
			if "fish_mackerel" in t:
				t["fish_mackerel"] *= 1.08

	if raining:
		for k in t.keys():
			if str(k).begins_with("fish_"):
				t[k] *= 1.12
		if "junk_boot" in t:
			t["junk_boot"] *= 1.05
		if "junk_seaweed" in t:
			t["junk_seaweed"] *= 1.08

	if morning and "fish_carp" in t:
		t["fish_carp"] *= 1.08
	if afternoon and "fish_sardine" in t:
		t["fish_sardine"] *= 1.08
	if afternoon and "fish_mackerel" in t:
		t["fish_mackerel"] *= 1.1

	return t


## Short label for mining UI / messages (Y-band depth in MineArea).
## Depth tiers use global Y vs `MiningSystem.MINE_GLOBAL_DEPTH_BREAK_*` (same as `main.tscn` MineLayer* bands).
static func mining_layer_prefix(depth: int) -> String:
	match depth:
		0:
			return "[Surface drift]"
		1:
			return "[Iron seam]"
		2:
			return "[Deep vein]"
		_:
			return ""


static func mining_ore_weights(depth: int, pickaxe_tier: int) -> Dictionary:
	# depth: 0 shallow, 1 mid, 2 deep; pickaxe_tier: 1 basic pickaxe, 2 iron pickaxe (gold at depth)
	var w: Dictionary = {
		"stone_chunk": 1.0,
		"copper_ore": 0.85,
		"coal": 0.65
	}
	if depth >= 1:
		w["iron_ore"] = 0.5 if pickaxe_tier >= 1 else 0.25
	if depth >= 2:
		w["iron_ore"] = float(w.get("iron_ore", 0.0)) + 0.35
		# Small chance for a shiny drop (sell or display)
		w["quartz"] = 0.14
		if pickaxe_tier >= 2:
			w["gold_ore"] = 0.45
		else:
			w["stone_chunk"] *= 1.15

	# Layer themes — emphasis shifts by Y band (see mining_layer_prefix).
	match depth:
		0:
			w["copper_ore"] = float(w.get("copper_ore", 0.0)) * 1.22
			w["coal"] = float(w.get("coal", 0.0)) * 1.1
			w["stone_chunk"] = float(w.get("stone_chunk", 0.0)) * 1.06
			w["geode"] = 0.09
		1:
			if "iron_ore" in w:
				w["iron_ore"] = float(w["iron_ore"]) * 1.2
			w["coal"] = float(w.get("coal", 0.0)) * 1.06
			w["copper_ore"] = float(w.get("copper_ore", 0.0)) * 0.9
		2:
			w["stone_chunk"] = float(w.get("stone_chunk", 0.0)) * 0.9
			if "copper_ore" in w:
				w["copper_ore"] = float(w["copper_ore"]) * 0.75
			if "quartz" in w:
				w["quartz"] = float(w["quartz"]) * 1.15
	return w
