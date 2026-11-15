extends Node2D

@export var speed: float = 350.0
@export var lifetime: float = 0.45
@export_range(1, 20, 1, "or_greater") var damage: int = 1
@export_flags_2d_physics var wall_collision_mask: int = 1

var travel_direction: Vector2 = Vector2.RIGHT
var collision_check_start: Vector2
var excluded_bodies: Array[RID] = []
var time_left: float = 0.0


func launch(
	muzzle_position: Vector2,
	pivot_position: Vector2,
	direction: Vector2,
	shooter_rid: RID
) -> void:
	global_position = muzzle_position
	global_rotation = direction.angle()
	travel_direction = direction
	collision_check_start = pivot_position
	excluded_bodies = [shooter_rid]
	time_left = lifetime


func _physics_process(delta: float) -> void:
	if time_left <= 0.0:
		queue_free()
		return

	var travel_time := minf(delta, time_left)
	var next_position := global_position + travel_direction * speed * travel_time
	var query := PhysicsRayQueryParameters2D.create(
		collision_check_start, next_position, wall_collision_mask, excluded_bodies
	)
	query.hit_from_inside = true

	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var target := hit.get("collider") as Node
		if target != null and target.has_method("take_bullet_damage"):
			target.call("take_bullet_damage", damage)
		queue_free()
		return

	global_position = next_position
	collision_check_start = next_position
	time_left -= travel_time

	if time_left <= 0.0:
		queue_free()
