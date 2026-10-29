extends CharacterBody2D

signal enemyDestroyed

const SPEED = 60.0
var direction = -1
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var ray = $pisoOno
@onready var sprite = $sprite

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	if is_on_wall() or (is_on_floor() and not ray.is_colliding()):
		direction *= -1
		ray.position.x = abs(ray.position.x) * direction

	velocity.x = direction * SPEED
	move_and_slide()


func _on_area_body_entered(body: Node2D) -> void:
	if body is Player:
		if body.esta_invulnerable():
			body.get_boost(1.3)
			emit_signal("enemyDestroyed")
			print("I'm dead")
			queue_free()
		else:
			body.get_hit(1)
