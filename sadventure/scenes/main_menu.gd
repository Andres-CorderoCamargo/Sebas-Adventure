extends Control

var banned_words = ["fuck", "dick", ""]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_shop_pressed() -> void:
	pass

func _on_skin_pressed() -> void:
	pass
	
func _on_option_pressed() -> void:
	pass

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_line_edit_text_submitted(text: String) -> void:
	if is_name_valid(text) :
		var final_name = sanitize_name(text)
		if final_name == "":
			final_name = "Player"
		DonneesJoueur.player_name = final_name
	else : 
		DonneesJoueur.nom_joueur = "Player"

func is_name_valid(name: String) -> bool:
	var lower = name.to_lower()
	for word in banned_words:
		if word in lower:
			return false
	return true

func sanitize_name(name: String) -> String:
	name = name.strip_edges()
	# limitar tamaño
	name = name.substr(0, 10)
	# quitar caracteres raros
	var regex = RegEx.new()
	regex.compile("[^a-zA-Z0-9_ ]")
	name = regex.sub(name, "", true)
	return name
