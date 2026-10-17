extends CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("esc"):
		_alternar_pausa()
		get_viewport().set_input_as_handled()

func _alternar_pausa() -> void:
	var nuevo_estado := not get_tree().paused
	get_tree().paused = nuevo_estado
	visible = nuevo_estado

func _on_continuar_pressed() -> void:
	_alternar_pausa()

func _on_salir_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
