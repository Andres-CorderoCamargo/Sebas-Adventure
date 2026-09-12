extends Control

@onready var ascc: VideoStreamPlayer = $ascc


func _on_ascc_finished() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
