extends Area2D

## F3: show a sibling label under the same parent while the player is in this area.

@export var hint_label_name: String = "MineLabelSurface"


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _set_hint_visible(v: bool) -> void:
	var p: Node = get_parent()
	if p == null:
		return
	var lab: Node = p.get_node_or_null(hint_label_name)
	if lab is CanvasItem:
		(lab as CanvasItem).visible = v


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_set_hint_visible(true)


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_set_hint_visible(false)
