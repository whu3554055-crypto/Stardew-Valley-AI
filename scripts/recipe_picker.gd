extends Panel

const TITLE_BY_MODE := {
	"cooking": "烹饪 — 选择配方（再按 E 关闭）",
	"smelting": "熔炼 — 选择配方（再按 E 关闭）",
	"crafting": "工作台 — 选择配方（再按 E 关闭）",
}

@onready var _title: Label = $Margin/VBox/Title
@onready var item_list: ItemList = $Margin/VBox/ItemList
@onready var detail: Label = $Margin/VBox/Detail
@onready var btn_confirm: Button = $Margin/VBox/Buttons/Confirm
@onready var btn_close: Button = $Margin/VBox/Buttons/Close

var mode: String = ""
var recipes: Array = []

signal recipe_chosen(recipe: Dictionary, mode: String)

func _recipe_btn_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.13, 0.12, 0.11, 0.96)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.4, 0.36, 0.26)
	return sb

func _ready() -> void:
	visible = false
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.06, 0.07, 0.1, 0.96)
	psb.set_border_width_all(1)
	psb.border_color = Color(0.4, 0.36, 0.26)
	psb.content_margin_left = 10
	psb.content_margin_top = 10
	psb.content_margin_right = 10
	psb.content_margin_bottom = 10
	add_theme_stylebox_override("panel", psb)
	if item_list:
		item_list.add_theme_font_size_override("font_size", 14)
		item_list.add_theme_color_override("font_selected_color", Color(0.98, 0.9, 0.55))
		item_list.add_theme_color_override("font_hovered_color", Color(0.92, 0.92, 0.94))
	if detail:
		detail.add_theme_font_size_override("font_size", 13)
		detail.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.4))
		detail.add_theme_constant_override("shadow_offset_x", 1)
		detail.add_theme_constant_override("shadow_offset_y", 1)
	if _title:
		_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
		_title.add_theme_constant_override("shadow_offset_x", 1)
		_title.add_theme_constant_override("shadow_offset_y", 1)
	var rbtn := _recipe_btn_style()
	if btn_confirm:
		btn_confirm.flat = true
		btn_confirm.add_theme_stylebox_override("normal", rbtn)
		btn_confirm.add_theme_stylebox_override("hover", _recipe_btn_style())
		btn_confirm.add_theme_stylebox_override("pressed", _recipe_btn_style())
	if btn_close:
		btn_close.flat = true
		btn_close.add_theme_stylebox_override("normal", _recipe_btn_style())
		btn_close.add_theme_stylebox_override("hover", _recipe_btn_style())
		btn_close.add_theme_stylebox_override("pressed", _recipe_btn_style())
	btn_confirm.pressed.connect(_on_confirm_pressed)
	btn_close.pressed.connect(close_picker)
	item_list.item_selected.connect(_on_item_selected)
	item_list.item_activated.connect(_on_item_activated)

func open_picker(p_mode: String, p_recipes: Array) -> void:
	mode = p_mode
	recipes = p_recipes
	_title.text = str(TITLE_BY_MODE.get(p_mode, "配方"))
	item_list.clear()
	if recipes.is_empty():
		detail.text = "（无配方数据：检查 data/recipes/*.json）"
		btn_confirm.disabled = true
		visible = true
		return
	for r in recipes:
		item_list.add_item(_format_row(r))
	item_list.select(0)
	_on_item_selected(0)
	visible = true
	btn_confirm.disabled = not _recipe_ok(0)

func close_picker() -> void:
	visible = false
	recipes.clear()

func _format_row(recipe: Dictionary) -> String:
	var out_id: String = RecipeHelpers.recipe_output_id(recipe)
	var qty: int = int(recipe.get("output_qty", recipe.get("qty", 1)))
	var nm: String = str(ItemDatabase.get_item(out_id).get("name", out_id))
	var cost: Dictionary = RecipeHelpers.recipe_cost(recipe)
	var ok: bool = _can_afford(cost)
	var tag: String = "[可]" if ok else "[缺]"
	var gap: String = RecipeHelpers.format_material_gap(cost)
	var line: String = "%s %s ×%d" % [tag, nm, qty]
	if not gap.is_empty():
		line += "  |  %s" % gap
	return line

func _can_afford(costs: Dictionary) -> bool:
	for k in costs.keys():
		if InventoryManager.count_item(str(k)) < int(costs[k]):
			return false
	return true

func _recipe_ok(idx: int) -> bool:
	if idx < 0 or idx >= recipes.size():
		return false
	return _can_afford(RecipeHelpers.recipe_cost(recipes[idx]))

func _on_item_selected(idx: int) -> void:
	if idx < 0 or idx >= recipes.size():
		detail.text = ""
		return
	var r: Dictionary = recipes[idx]
	var out_id: String = RecipeHelpers.recipe_output_id(r)
	var qty: int = int(r.get("output_qty", r.get("qty", 1)))
	var st: float = float(r.get("stamina", 2.0))
	var nm: String = str(ItemDatabase.get_item(out_id).get("name", out_id))
	var cost: Dictionary = RecipeHelpers.recipe_cost(r)
	var gap: String = RecipeHelpers.format_material_gap(cost)
	var gap_line: String = gap if not gap.is_empty() else "（材料足够）"
	detail.text = "产出：%s ×%d\n体力：%.0f\n材料：%s" % [nm, qty, st, gap_line]
	btn_confirm.disabled = not _recipe_ok(idx)

func _on_item_activated(idx: int) -> void:
	if _recipe_ok(idx):
		_emit_and_close(idx)

func _on_confirm_pressed() -> void:
	var sel: PackedInt32Array = item_list.get_selected_items()
	if sel.is_empty():
		return
	var idx: int = sel[0]
	if not _recipe_ok(idx):
		return
	_emit_and_close(idx)

func _emit_and_close(idx: int) -> void:
	if idx < 0 or idx >= recipes.size():
		return
	var r: Dictionary = recipes[idx].duplicate(true)
	recipe_chosen.emit(r, mode)
	close_picker()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close_picker()
		get_viewport().set_input_as_handled()
