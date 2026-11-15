extends Area2D

const DEATH_FADE_PENDING := &"death_fade_pending"
var is_reloading := false

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	var tree := get_tree()
	if tree.has_meta(DEATH_FADE_PENDING):
		tree.remove_meta(DEATH_FADE_PENDING)
		_play_death_fade.call_deferred()

func _on_body_entered(body: Node2D) -> void:
	if is_reloading:
		return

	if body.is_in_group("Player") or body.name == "Player":
		is_reloading = true
		_reload_level.call_deferred()

func _reload_level() -> void:
	var tree := get_tree()
	tree.set_meta(DEATH_FADE_PENDING, true)

	if tree.reload_current_scene() != OK:
		tree.remove_meta(DEATH_FADE_PENDING)
		is_reloading = false

func _play_death_fade() -> void:
	var scene := get_tree().current_scene
	var fade_player := scene.get_node_or_null("CanvasLayer/AnimationPlayer") as AnimationPlayer

	if fade_player != null:
		fade_player.play("fade_out")
