extends CharacterBody2D

@export var player_target: Node2D
@export var arrow_scene: PackedScene
@export_range(1, 20, 1, "or_greater") var max_health: int = 2
@export_range(0.0, 2000.0, 1.0, "or_greater") var attack_range: float = 120.0
@export_range(0.0, 5.0, 0.05, "or_greater") var attack_pause: float = 0.8
@export_range(0, 60, 1, "or_greater") var release_frame: int = 2

@onready var body_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var bow_pivot: Node2D = $BowPivot
@onready var bow_sprite: AnimatedSprite2D = $BowPivot/BowSprite
@onready var arrow_spawn: Node2D = $BowPivot/ArrowSpawn

var right_bow_transform: Transform2D
var attack_pause_left: float = 0.0
var arrow_released: bool = false
var health: int = 0
var is_dying: bool = false


func _ready() -> void:
	health = max_health
	var frames := bow_sprite.sprite_frames

	for animation_name in [&"idle", &"shoot"]:
		if not _has_animation_frames(bow_sprite, animation_name):
			push_warning("BowSprite animasyonuna kare ekle: %s" % animation_name)
			set_physics_process(false)
			return

	frames = frames.duplicate() as SpriteFrames
	frames.set_animation_loop(&"shoot", false)
	bow_sprite.sprite_frames = frames
	right_bow_transform = bow_pivot.transform

	bow_sprite.frame_changed.connect(_try_release_arrow)
	bow_sprite.animation_finished.connect(_end_attack)
	bow_sprite.play(&"idle")

	if arrow_scene == null:
		push_warning("Enemy_Archer: Arrow Scene alanına arrow.tscn ekle.")
		set_physics_process(false)


func _physics_process(delta: float) -> void:
	attack_pause_left = maxf(0.0, attack_pause_left - delta)
	var player := _get_player_in_range()

	if player == null:
		_end_attack()
		return

	if attack_pause_left > 0.0 or bow_sprite.animation == &"shoot":
		return

	var facing_left := player.global_position.x < global_position.x
	body_sprite.flip_h = facing_left
	bow_pivot.transform = Transform2D.FLIP_X * right_bow_transform if facing_left else right_bow_transform

	arrow_released = false
	bow_sprite.play(&"shoot")
	_try_release_arrow()


func _get_player_in_range() -> CharacterBody2D:
	var player := player_target as CharacterBody2D
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group(&"player") as CharacterBody2D

	if player != null and global_position.distance_to(player.global_position) <= attack_range:
		return player

	return null


func _try_release_arrow() -> void:
	if is_dying or bow_sprite.animation != &"shoot" or arrow_released:
		return

	var last_frame := bow_sprite.sprite_frames.get_frame_count(&"shoot") - 1
	if bow_sprite.frame < mini(release_frame, last_frame):
		return

	var player := _get_player_in_range()
	if player == null:
		_end_attack()
		return

	arrow_released = true
	var arrow := arrow_scene.instantiate()
	if not arrow.has_method("launch"):
		arrow.free()
		push_error("Arrow ana düğümüne arrow.gd bağla.")
		return

	var origin := arrow_spawn.global_position
	var direction := origin.direction_to(player.global_position)
	if direction.is_zero_approx():
		direction = Vector2.LEFT if body_sprite.flip_h else Vector2.RIGHT

	get_parent().add_child(arrow)
	arrow.call("launch", origin, direction, get_rid(), player)


func _end_attack() -> void:
	if is_dying or bow_sprite.animation != &"shoot":
		return

	if arrow_released:
		attack_pause_left = attack_pause
	bow_sprite.play(&"idle")


func take_bullet_damage(amount: int) -> void:
	if is_dying:
		return

	health = maxi(0, health - amount)
	if health == 0:
		_play_death()


func _play_death() -> void:
	is_dying = true
	set_physics_process(false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	bow_sprite.stop()

	var death_sprite := body_sprite
	if not _has_animation_frames(death_sprite, &"death"):
		death_sprite = bow_sprite

	if not _has_animation_frames(death_sprite, &"death"):
		push_warning("Okçunun Sprite Frames kaynağında death animasyonuna kare ekle.")
		queue_free()
		return

	if death_sprite == body_sprite:
		bow_pivot.hide()

	var frames := death_sprite.sprite_frames.duplicate() as SpriteFrames
	frames.set_animation_loop(&"death", false)
	death_sprite.sprite_frames = frames
	death_sprite.animation_finished.connect(queue_free, CONNECT_ONE_SHOT)
	death_sprite.play(&"death")


func _has_animation_frames(sprite: AnimatedSprite2D, animation_name: StringName) -> bool:
	var frames := sprite.sprite_frames
	return (
		frames != null
		and frames.has_animation(animation_name)
		and frames.get_frame_count(animation_name) > 0
	)
