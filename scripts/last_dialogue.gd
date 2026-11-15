extends CanvasLayer

@export var wizard_trigger: Area2D

@onready var dialogue_box := get_node_or_null("DialogueBox") as Control
@onready var label := find_child("Label", true, false) as Label
@onready var blip_sound := get_node_or_null("AudioStreamPlayer") as AudioStreamPlayer
@onready var gunshot_sound := get_node_or_null("GunshotSound") as AudioStreamPlayer

var witch_lines: Array[String] = [
	"Hah! You abandoned your blade for that hunk of iron, knight?",
	"The sun is setting—it is a part of you now!",
	"You may have stripped me of my honor, witch...",
	"But I learned how to pull the trigger."
]

var current_line := 0
var is_typing := false
var dialogue_active := false
var has_triggered := false
var dialogue_player: Node2D


func _ready() -> void:
	hide()

	if dialogue_box == null or label == null:
		push_error("DialogueUI içinde DialogueBox veya Label bulunamadı.")
		return

	if wizard_trigger == null:
		push_error("DialogueUI Inspector'ında Wizard Trigger alanı boş.")
		return

	if not wizard_trigger.body_entered.is_connected(_on_wizard_trigger_body_entered):
		wizard_trigger.body_entered.connect(_on_wizard_trigger_body_entered)
func _on_wizard_trigger_body_entered(body: Node2D) -> void:
	if has_triggered:
		return

	if body.name == &"Player" or body.is_in_group(&"Player") or body.is_in_group(&"player"):
		has_triggered = true
		start_dialogue(body)


func start_dialogue(player: Node2D) -> void:
	dialogue_player = player
	player.set_physics_process(false)
	current_line = 0
	dialogue_active = true
	dialogue_box.show()
	show()
	show_line(current_line)


func _input(event: InputEvent) -> void:
	if not dialogue_active:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			get_viewport().set_input_as_handled()
			_advance_dialogue()


func _unhandled_input(event: InputEvent) -> void:
	if dialogue_active and event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_advance_dialogue()


func _advance_dialogue() -> void:
	if is_typing:
		label.visible_characters = label.text.length()
		is_typing = false
		return

	current_line += 1
	if current_line < witch_lines.size():
		show_line(current_line)
	else:
		end_game_sequence()


func show_line(index: int) -> void:
	var line := witch_lines[index]
	is_typing = true
	label.text = line
	label.visible_characters = 0

	for i in range(line.length()):
		label.visible_characters += 1

		if blip_sound != null and line[i] != " ":
			blip_sound.play()

		await get_tree().create_timer(0.05).timeout
		if not is_typing or index != current_line:
			return

	is_typing = false


func end_game_sequence() -> void:
	dialogue_active = false
	dialogue_box.hide()
	label.hide()
	$BlackScreen.show()

	var witch := get_parent().get_node_or_null("Witch") as Node2D
	var shot_fired := false

	if is_instance_valid(dialogue_player):
		shot_fired = bool(dialogue_player.call("fire_final_shot", witch))

	if not shot_fired and gunshot_sound != null:
		gunshot_sound.play()

	await get_tree().create_timer(5.0).timeout
	get_tree().change_scene_to_file("res://scenes/Main_Menu.tscn")
