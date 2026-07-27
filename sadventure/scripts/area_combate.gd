extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.entrar_a_combate()
		# Opcional: pasarle a tu CombatManager los datos de QUÉ enemigo está luchando
