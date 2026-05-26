extends CharacterBody2D

const SPEED = 185.0
const JUMP_VELOCITY = -350.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var directionX := Input.get_axis("ui_left", "ui_right")

	if directionX > 0:
		animated_sprite.flip_h = false
	elif directionX < 0:
		animated_sprite.flip_h = true


	if directionX != 0:
		velocity.x = directionX * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	update_animation(directionX)


func update_animation(directionX: float) -> void:
	if not is_on_floor():
		set_anim("jump")

	elif directionX != 0:
		set_anim("walk")

	else:
		set_anim("idle")

func set_anim(anim: String) -> void:
	if animated_sprite.animation != anim:
		animated_sprite.play(anim)
