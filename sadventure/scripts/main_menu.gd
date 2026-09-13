extends Control

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/data_menu.tscn")

func _on_shop_pressed() -> void:
	pass

func _on_skin_pressed() -> void:
	pass
	
func _on_option_pressed() -> void:
	pass

func _on_exit_pressed() -> void:
	get_tree().quit()
