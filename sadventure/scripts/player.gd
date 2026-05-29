extends CharacterBody2D

const walk_speed = 100.0
const run_speed = 250.0
const jump = -350.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump
	var directionX = Input.get_axis("ui_left", "ui_right")
	var current_speed = walk_speed
 	
	if Input.is_action_pressed("run") :
		current_speed = run_speed

	if directionX > 0:
		animated_sprite.flip_h = false
	elif directionX < 0:
		animated_sprite.flip_h = true

	if directionX != 0:
		velocity.x = directionX * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)

	move_and_slide()
	update_animation(directionX)


func update_animation(directionX: float) -> void:
	if not is_on_floor():
		set_anim("jumpspin")

	elif directionX != 0:
		set_anim("walk")

	else:
		set_anim("idle")

func set_anim(anim: String) -> void:
	if animated_sprite.animation != anim:
		animated_sprite.play(anim)
