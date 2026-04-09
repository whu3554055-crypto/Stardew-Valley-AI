class_name GameZones
extends RefCounted

## World hit-tests for stations, fishing, mining, and upgrade zones.
## - **Stations + mine AABB**: `data/presentation/immersion_config.json` → `zones.stations`, `zones.mine`
## - **Fish river/ocean**: same file → `zones.fish_*` (via `ImmersionConfig`)
## - **Farm tier / house upgrade**: `data/farm/tiers.json` / `data/buildings/upgrades.json` (via catalogs)

static func _station_rect(key: String) -> Rect2:
	return ImmersionConfig.get_station_rect(key) if ImmersionConfig else Rect2()

static func rect_kitchen() -> Rect2:
	var r: Rect2 = _station_rect("kitchen")
	if r.size == Vector2.ZERO:
		return Rect2(600, 260, 220, 170)
	return r

static func rect_workbench() -> Rect2:
	var r: Rect2 = _station_rect("workbench")
	if r.size == Vector2.ZERO:
		return Rect2(825, 275, 215, 155)
	return r

static func rect_smelter() -> Rect2:
	var r: Rect2 = _station_rect("smelter")
	if r.size == Vector2.ZERO:
		return Rect2(380, 70, 200, 190)
	return r

static func rect_forest() -> Rect2:
	var r: Rect2 = _station_rect("forest")
	if r.size == Vector2.ZERO:
		return Rect2(40, 95, 280, 180)
	return r

static func rect_near_pierre() -> Rect2:
	var r: Rect2 = _station_rect("near_pierre")
	if r.size == Vector2.ZERO:
		return Rect2(560, 260, 280, 280)
	return r

## Same footprint as `rect_near_pierre` — general store / B key (aligned with ambience “town” rect).
static func can_open_shop_at(pos: Vector2) -> bool:
	return rect_near_pierre().has_point(pos)

static func contains_kitchen(pos: Vector2) -> bool:
	return rect_kitchen().has_point(pos)

static func contains_workbench(pos: Vector2) -> bool:
	return rect_workbench().has_point(pos)

static func contains_smelter(pos: Vector2) -> bool:
	return rect_smelter().has_point(pos)

static func contains_forest(pos: Vector2) -> bool:
	return rect_forest().has_point(pos)

static func is_indoor_station(pos: Vector2) -> bool:
	return contains_kitchen(pos) or contains_smelter(pos) or contains_workbench(pos)

## Farm / house upgrade areas — single entry point for gameplay (data from tier/building JSON).
static func rect_farm_upgrade() -> Rect2:
	if FarmTierCatalog:
		return FarmTierCatalog.get_farm_upgrade_rect()
	return Rect2(400, 300, 360, 220)

static func rect_house_upgrade() -> Rect2:
	if BuildingUpgradeCatalog:
		return BuildingUpgradeCatalog.get_house_rect()
	return Rect2(560, 240, 300, 220)

static func contains_farm_upgrade_zone(pos: Vector2) -> bool:
	return rect_farm_upgrade().has_point(pos)

static func contains_house_upgrade_zone(pos: Vector2) -> bool:
	return rect_house_upgrade().has_point(pos)

static func mine_bounds_dict() -> Dictionary:
	return ImmersionConfig.get_mine_bounds() if ImmersionConfig else {}

static func mine_world_rect() -> Rect2:
	var b: Dictionary = mine_bounds_dict()
	var x0: float = float(b.get("x_min", 70.0))
	var y0: float = float(b.get("y_min", 300.0))
	var x1: float = float(b.get("x_max", 310.0))
	var y1: float = float(b.get("y_max", 520.0))
	return Rect2(x0, y0, x1 - x0, y1 - y0)

static func can_mine_here(pos: Vector2) -> bool:
	return mine_world_rect().has_point(pos)

static func mine_depth_from_global_y(global_y: float) -> int:
	var b: Dictionary = mine_bounds_dict()
	var d1: float = float(b.get("depth_break_1", 380.0))
	var d2: float = float(b.get("depth_break_2", 460.0))
	if global_y < d1:
		return 0
	if global_y < d2:
		return 1
	return 2

## Fishing zones — rects from `ImmersionConfig` / `data/presentation/immersion_config.json` (river checked before ocean).
static func get_fish_zone_id(pos: Vector2) -> String:
	if not ImmersionConfig:
		return ""
	var rr: Rect2 = ImmersionConfig.get_fish_river_rect()
	if rr.has_point(pos):
		return "river"
	var oc: Rect2 = ImmersionConfig.get_fish_ocean_rect()
	if oc.has_point(pos):
		return "ocean"
	return ""
