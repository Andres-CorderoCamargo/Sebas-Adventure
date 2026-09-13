extends Control


var banned_words = ["fuck", "dick"]

@onready var nameP: LineEdit = $vbox/chooseName/nameP


func _on_line_edit_text_submitted(text: String) -> void:
	var final_name = sanitize_name(text)

	if final_name == "" or not is_name_valid(final_name):
		final_name = "Sebas"

	DonneesJoueur.set_nom(final_name)
	nameP.text = final_name

func is_name_valid(name: String) -> bool:
	var lower = name.to_lower()
	for word in banned_words:
		if word in lower:
			return false
	return true

func sanitize_name(name: String) -> String:
	name = name.strip_edges()

	var regex = RegEx.new()
	regex.compile("[^a-zA-Z0-9_ ]")
	name = regex.sub(name, "", true)

	name = name.substr(0, 10)

	return name.strip_edges()

func _on_start_b_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")
