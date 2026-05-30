extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Velocidades
var maxSpeed = 360
var maxSpeedFloat = 1.0
var accel = 180
var accelFloat = 1.2
var decel = 280
var decelFloat = 2.0
var fastDecel = 680
var fastDecelFloat = 1.0

# Velocidad y salto
var jump_velocity = -300.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Estados
var idleAnim = true
var movePhysics = true
var walkAnim = true
var runAnim = true
var jumpPhysics = true
var jumpAnim = true

func _physics_process(delta):
	_gravity(delta)
 
	# Variable que recupera el movimiento
	var dir = Input.get_axis("ui_left", "ui_right")

	# Dejo aqui esto porque.. quiero y puedo uwu.
	if velocity.x > 0:
		animated_sprite.flip_h = false
	elif velocity.x < 0:
		animated_sprite.flip_h = true

	# Saltooos :));
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and jumpPhysics:
		velocity.y = jump_velocity


	# Movimiento vivo (para que haya aceleracion y desacceleracion) 
	if movePhysics:
		if dir != 0:
			var target_velocity = maxSpeed * maxSpeedFloat * dir
			velocity.x = move_toward(velocity.x, target_velocity, accel * accelFloat * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, decel * decelFloat * delta)

	move_and_slide()
	update_animation(velocity.x)

# Gravedad (para modificarla después si besoin...
func _gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

# Animaciones por separado : Si no, no se reproduciran !!
func update_animation(directionX: float) -> void:
	if not is_on_floor():
		set_anim("jumpspin")

	elif velocity.x != 0 and velocity.x < 300:
		set_anim("walk")

	elif velocity.x > 300 :
		set_anim("")

	else:
		set_anim("idle")

func set_anim(anim: String) -> void:
	if animated_sprite.animation != anim:
		animated_sprite.play(anim)
