class_name EnnemiBase
extends CharacterBody2D

signal enemyDestroyed

@export var speed := 60.0
@export var damage := 1
@export var destructible := true
@export var max_health := 1
@export var boost_on_kill := 1.3
@export var hit_cooldown := 0.3

var direction := -1
var health := 1
var can_be_hit := true
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var ray = $pisoOno
@onready var sprite = $sprite

func _ready():
	health = max_health

func _physics_process(delta):
	_apply_gravity(delta)
	_move(delta)
	_special_move(delta)
	move_and_slide()

func _apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

func _move(_delta):
	if is_on_wall() or (is_on_floor() and not ray.is_colliding()):
		direction *= -1
		ray.position.x = abs(ray.position.x) * direction
	velocity.x = direction * speed
	sprite.flip_h = direction > 0

func _special_move(_delta):
	pass

func _on_area_body_entered(body: Node2D) -> void:
	if body is Player:
		if body.current_state == Player.State.DODGING:
			return
		if destructible and body.esta_invulnerable():
			_take_hit(body)
		else:
			_hit_player(body)

func _take_hit(player):
	if player.current_state == Player.State.DODGING:
		return
	print("golpe | state=", player.current_state, " spin=", player.es_salto_spin, " suelo=", player.is_on_floor())
	if not can_be_hit:
		return
	can_be_hit = false
	health -= 1
	player.get_boost(boost_on_kill)
	if health <= 0:
		die()
	else:
		_on_damaged()
		await get_tree().create_timer(hit_cooldown).timeout
		can_be_hit = true

func _hit_player(player):
	if damage > 0:
		player.get_hit(damage)

func _on_damaged():
	pass

func die():
	enemyDestroyed.emit()
	queue_free()
