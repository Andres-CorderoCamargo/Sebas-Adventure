extends Area2D

@onready var timer: Timer = $Timer
@onready var killcollision: CollisionShape2D = $killcollision
@onready var spawnpoint: Marker2D = $spawnpoint

func _ready() -> void:
	timer.start()
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body is Player:
		if body.esta_invulnerable() and body.is_vulnerable == false and body.invuln_timer <= 0.0:
			queue_free()   # le joueur attaque (roll/stomp) → l'ennemi meurt
		else:
			body.get_hit(1, global_position)

func recolocar_jugador(player: Player) -> void:
	player.velocity = Vector2.ZERO
	player.current_state = player.State.NORMAL

	player.global_position.y -= 100
	player.global_position.x -= 100
