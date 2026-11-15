extends Control

@onready var label: Label = $Label
@onready var blip_sound: AudioStreamPlayer2D = $AudioStreamPlayer2D

var lines: Array[String] = [
	"Long ago, in a land where swords were the mark of honor; lived a noble knight.",
	"Until a wicked witch cursed his right hand...",
	"sealing a cold piece of iron to his flesh.",
	"If he fails to hunt her down before sunset, this cursed gun will remain fused to him forever."
]

var current_line: int = 0
var is_typing: bool = false

func _ready() -> void:
	show_line(current_line)

func _unhandled_input(event: InputEvent) -> void:
	# Advance when pressing Space, Enter, or Left Mouse Click
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
		if is_typing:
			# Skip typing animation and show full line immediately
			label.visible_characters = label.text.length()
			is_typing = false
		else:
			current_line += 1
			if current_line < lines.size():
				show_line(current_line)
			else:
				# All lines finished -> load Level 1
				get_tree().change_scene_to_file("res://scenes/lv1.tscn")

func show_line(index: int) -> void:
	is_typing = true
	label.text = lines[index]
	label.visible_characters = 0
	
	for i in range(label.text.length()):
		if not is_typing:
			break
		label.visible_characters += 1
		
		# Play beep sound on non-space characters
		if label.text[i] != " ":
			blip_sound.play()
			
		await get_tree().create_timer(0.05).timeout
		
	is_typing = false
