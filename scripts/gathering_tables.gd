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
		t["junk_boot"] = 0.32
		t["junk_seaweed"] = 0.12
	elif zone == "ocean":
		t["fish_sardine"] = 1.35
		t["fish_perch"] = 0.72
		t["fish_trout"] = 0.48
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
		"winter":
			if "fish_perch" in t:
				t["fish_perch"] *= 1.1

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

	return t


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
	return w
