extends Area2D

const LVL2 := "res://scenes/lvl_2.tscn"
const LVL3 := "res://scenes/lvl3.tscn"
const LVL4 := "res://scenes/lvl_4.tscn"

var is_changing_level := false

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if is_changing_level:
		return

	if body.is_in_group("Player") or body.name == "Player":
		is_changing_level = true
		_change_level.call_deferred()

func _change_level() -> void:
	var tree := get_tree()
	var current_file := tree.current_scene.scene_file_path.get_file()
	var hedef: String

	match current_file:
		"lv1.tscn":
			hedef = LVL2
		"lvl_2.tscn":
			hedef = LVL3
		"lvl3.tscn":
			hedef = LVL4
		_:
			is_changing_level = false
			return

	if tree.change_scene_to_file(hedef) != OK:
		is_changing_level = false
		
