extends CharacterBody2D

const BULLET_SCENE: PackedScene = preload("res://scenes/bullet.tscn")

@export var move_speed: float = 130.0
@export var jump_speed: float = 270.0
@export_range(0.0, 0.30, 0.01) var jump_buffer_time: float = 0.20
@export var horizontal_recoil_deceleration: float = 980.0
@export var ground_recoil_speed: float = 100.0
@export var air_recoil_speed: float = 280.0
@export_range(0.02, 2.0, 0.01) var shot_cooldown: float = 0.30
@export var automatic_fire: bool = true
@export var starting_ammo: int = 0
@export_range(8, 96, 1) var ammo_font_size: int = 26

var ammo: int = 0
var jump_buffer_left: float = 0.0
var shot_direction: Vector2 = Vector2.RIGHT
var shot_cooldown_left: float = 0.0
var horizontal_recoil_active: bool = false
var pending_arrow_knockback: Vector2 = Vector2.ZERO

@onready var player_animation: AnimatedSprite2D = $PlayerAnimation
@onready var ammo_label := find_child("AmmoLabel", true, false) as Label


func _ready() -> void:
	floor_snap_length = 20.0
	ammo = maxi(0, starting_ammo)

	if ammo_label != null:
		ammo_label.modulate = Color.WHITE
		ammo_label.add_theme_font_size_override("font_size", ammo_font_size)
		ammo_label.add_theme_color_override("font_color", Color.WHITE)
		ammo_label.add_theme_color_override("font_outline_color", Color.BLACK)
		ammo_label.add_theme_constant_override("outline_size", 4)

	_update_ammo_label()


func _physics_process(delta: float) -> void:
	var was_on_floor := is_on_floor()
	shot_cooldown_left = maxf(0.0, shot_cooldown_left - delta)

	if not was_on_floor:
		velocity += get_gravity() * delta

	var jump_pressed := Input.is_action_just_pressed("jump")
	if jump_pressed:
		jump_buffer_left = jump_buffer_time
	else:
		jump_buffer_left = maxf(0.0, jump_buffer_left - delta)

	var jumped_this_frame := was_on_floor and (jump_pressed or jump_buffer_left > 0.0)
	if jumped_this_frame:
		velocity.y = -jump_speed
		jump_buffer_left = 0.0

	var move_direction := Input.get_axis("move_left", "move_right")
	if move_direction != 0.0:
		player_animation.flip_h = move_direction < 0.0

	if horizontal_recoil_active:
		velocity.x = move_toward(
			velocity.x, 0.0, horizontal_recoil_deceleration * delta
		)
		if is_zero_approx(velocity.x):
			horizontal_recoil_active = false
	else:
		velocity.x = move_direction * move_speed

	if Input.is_action_just_pressed("aim_forward"):
		shot_direction = Vector2.RIGHT
	elif Input.is_action_just_pressed("aim_down"):
		shot_direction = Vector2.DOWN
	elif Input.is_action_just_pressed("aim_back"):
		shot_direction = Vector2.LEFT

	$GunPivot.rotation = shot_direction.angle()
	$GunPivot.scale.y = -1.0 if shot_direction.x < 0.0 else 1.0

	var grounded_shot := was_on_floor and not jumped_this_frame
	var shoot_requested := Input.is_action_just_pressed("shoot")
	if automatic_fire and Input.is_action_pressed("shoot"):
		shoot_requested = true

	var can_fire := shoot_requested and ammo > 0 and shot_cooldown_left <= 0.0

	if can_fire and _spawn_bullet():
		var recoil_speed := ground_recoil_speed if grounded_shot else air_recoil_speed

		if shot_direction.y != 0.0:
			velocity.y = -shot_direction.y * recoil_speed
		else:
			velocity.x = -shot_direction.x * recoil_speed
			horizontal_recoil_active = true

		ammo -= 1
		_update_ammo_label()
		shot_cooldown_left = shot_cooldown

	if pending_arrow_knockback != Vector2.ZERO:
		if pending_arrow_knockback.x != 0.0:
			velocity.x = pending_arrow_knockback.x
			horizontal_recoil_active = true
		velocity.y = minf(velocity.y, pending_arrow_knockback.y)
		pending_arrow_knockback = Vector2.ZERO

	move_and_slide()
	_update_movement_animation(move_direction)

	if is_on_wall():
		horizontal_recoil_active = false


func take_arrow_hit(direction: Vector2, knockback_speed: float, lift: float) -> void:
	var horizontal_push := 0.0
	if absf(direction.x) > 0.05:
		horizontal_push = signf(direction.x) * knockback_speed

	pending_arrow_knockback = Vector2(horizontal_push, -lift)


func _update_movement_animation(move_direction: float) -> void:
	var is_walking := (
		is_on_floor()
		and move_direction != 0.0
		and not horizontal_recoil_active
		and absf(get_real_velocity().x) > 1.0
	)
	var animation_name: StringName = &"walk" if is_walking else &"idle"

	if player_animation.animation != animation_name or not player_animation.is_playing():
		player_animation.play(animation_name)


func add_ammo(amount: int) -> void:
	ammo += maxi(0, amount)
	_update_ammo_label()

	if amount > 0:
		_play_game_sound(&"play_pickup")


func _update_ammo_label() -> void:
	if ammo_label != null:
		ammo_label.text = "Mermi: %d" % ammo


func _spawn_bullet() -> bool:
	var bullet := BULLET_SCENE.instantiate()

	if not bullet.has_method("launch"):
		push_error("bullet.tscn ana düğümüne bullet.gd bağla.")
		bullet.free()
		return false

	get_tree().current_scene.add_child(bullet)
	bullet.call(
		"launch",
		$GunPivot/Muzzle.global_position,
		$GunPivot.global_position,
		shot_direction,
		get_rid()
	)
	_play_game_sound(&"play_shot")
	return true


func _play_game_sound(method: StringName) -> void:
	var audio := get_node_or_null("/root/AudioManager")
	if audio == null:
		push_error("Globals → Autoload listesinde AudioManager bulunamadı.")
		return

	audio.call(method)


func _on_cut_scene_area_body_entered(body: Node2D) -> void:
	pass
	
func fire_final_shot(target: Node2D) -> bool:
	if is_instance_valid(target):
		var gun_pivot: Node2D = $GunPivot
		var direction := gun_pivot.global_position.direction_to(target.global_position)

		if not direction.is_zero_approx():
			shot_direction = direction
			gun_pivot.rotation = direction.angle()
			gun_pivot.scale.y = -1.0 if direction.x < 0.0 else 1.0

	return _spawn_bullet()
