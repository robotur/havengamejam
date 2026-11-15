extends Area2D

@export_range(1, 100, 1, "or_greater") var ammo_amount: int = 1


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if is_queued_for_deletion() or not body.has_method("add_ammo"):
		return

	body.call("add_ammo", ammo_amount)
	queue_free()
