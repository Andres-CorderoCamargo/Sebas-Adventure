extends Control

@onready var govideo: VideoStreamPlayer = $govideo
@onready var retry: Button = $retry

func _on_govideo_finished() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_retry_pressed() -> void:
	pass # Replace with function body.
