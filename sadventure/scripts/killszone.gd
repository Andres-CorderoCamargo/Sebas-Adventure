extends Area2D

@onready var timer: Timer = $Timer
@onready var killcollision: CollisionShape2D = $killcollision
@onready var spawnpoint: Marker2D = $spawnpoint

func _ready() -> void:
	timer.start()
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		get_tree().call_deferred("reload_current_scene")


# if body is Player:
#		body.perder_vida()

#		if body.num_vidas > 0:
#			recolocar_jugador(body)

func recolocar_jugador(player: Player) -> void:
	player.velocity = Vector2.ZERO
	player.current_state = player.State.NORMAL

	player.global_position.y -= 100
	player.global_position.x -= 100
