extends Node2D

@onready var menu_pausa: CanvasLayer = $MenuPausa

func _ready() -> void:
	if menu_pausa:
		menu_pausa.visible = false


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		_alternar_pausa()

func _alternar_pausa():
	var nuevo_estado_pausa = !get_tree().paused
	get_tree().paused = nuevo_estado_pausa
	
	# Mostramos u ocultamos el menú visual dependiendo del estado
	if menu_pausa:
		menu_pausa.visible = nuevo_estado_pausa

func _on_btn_continuar_pressed() -> void:
	# Simplemente llamamos a alternar_pausa() para que limpie todo y quite la pausa
	_alternar_pausa()

func _on_btn_salir_pressed() -> void:
	get_tree().paused = false 
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
