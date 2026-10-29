extends Control

var banned_words = ["fuck", "dick"]

@onready var nameP: LineEdit = $vbox/chooseName/nameP

func _ready() -> void:
	nameP.text_submitted.connect(_on_name_submitted)

func _on_name_submitted(text: String) -> void:
	apply_name(text)

func apply_name(text: String) -> void:
	var final_name = sanitize_name(text)

	if final_name == "" or not is_name_valid(final_name):
		final_name = "Sebas"

	DonneesJoueur.set_nom(final_name)
	nameP.text = final_name

func is_name_valid(player_name: String) -> bool:
	var lower = player_name.to_lower()
	for word in banned_words:
		if word in lower:
			return false
	return true

func sanitize_name(player_name: String) -> String:
	player_name = player_name.strip_edges()

	var regex = RegEx.new()
	regex.compile("[^a-zA-Z0-9_ ]")
	player_name = regex.sub(player_name, "", true)

	player_name = player_name.substr(0, 10)

	return player_name.strip_edges()

func _on_start_b_pressed() -> void:
	apply_name(nameP.text) 
	get_tree().change_scene_to_file("res://scenes/game.tscn")
