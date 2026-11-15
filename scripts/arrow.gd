extends Node2D

@export var speed: float = 180.0
@export var lifetime: float = 1.5
@export var knockback_speed: float = 300.0
@export var knockback_lift: float = 250.0
@export_flags_2d_physics var hit_mask: int = 1

var target_player: CharacterBody2D
var travel_direction: Vector2 = Vector2.RIGHT
var time_left: float = 0.0
var excluded_bodies: Array[RID] = []


func launch(
	origin: Vector2, direction: Vector2, shooter_rid: RID, player: CharacterBody2D
) -> void:
	global_position = origin
	global_rotation = direction.angle()
	travel_direction = direction
	target_player = player
	excluded_bodies = [shooter_rid]
	time_left = lifetime


func _physics_process(delta: float) -> void:
	if time_left <= 0.0:
		queue_free()
		return

	var step_time := minf(delta, time_left)
	var next_position := global_position + travel_direction * speed * step_time
	var collision_mask := hit_mask
	if is_instance_valid(target_player):
		collision_mask |= target_player.collision_layer

	var query := PhysicsRayQueryParameters2D.create(
		global_position, next_position, collision_mask, excluded_bodies
	)
	query.hit_from_inside = true

	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		if is_instance_valid(target_player) and hit.get("collider") == target_player:
			if target_player.has_method("take_arrow_hit"):
				target_player.call("take_arrow_hit", travel_direction, knockback_speed, knockback_lift)
			else:
				push_warning("Player scriptinde take_arrow_hit fonksiyonu bulunamadı.")
		queue_free()
		return

	global_position = next_position
	time_left -= step_time

	if time_left <= 0.0:
		queue_free()
