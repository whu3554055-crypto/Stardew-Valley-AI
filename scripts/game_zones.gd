class_name GameZones
extends RefCounted

## Single source of truth for station hit-tests (keep in sync with main.tscn polygons).

static func rect_kitchen() -> Rect2:
	return Rect2(600, 260, 220, 170)

static func rect_workbench() -> Rect2:
	return Rect2(825, 275, 215, 155)

static func rect_smelter() -> Rect2:
	return Rect2(380, 70, 200, 190)

## Forest: tightened west edge so gap vs furnace (x≈380+) is clearer.
static func rect_forest() -> Rect2:
	return Rect2(40, 95, 280, 180)

static func contains_kitchen(pos: Vector2) -> bool:
	return rect_kitchen().has_point(pos)

static func contains_workbench(pos: Vector2) -> bool:
	return rect_workbench().has_point(pos)

static func contains_smelter(pos: Vector2) -> bool:
	return rect_smelter().has_point(pos)

static func contains_forest(pos: Vector2) -> bool:
	return rect_forest().has_point(pos)
