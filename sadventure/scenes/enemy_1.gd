extends EnnemiBase

# Acuérdate, siempre haces 'super' ! xD

func _hit_player(player):
	super._hit_player(player)
	player.apply_slow(2.0)

func _on_area_body_entered(body: Node2D):
	super._take_hit(body)
