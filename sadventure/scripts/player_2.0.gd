extends CharacterBody2D

class_name Player

# =========================
# Datos importantes 
# =========================

var num_vidas = 3 # Por defecto son tres xd

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer
@onready var nom_joueur: Label = $Camera2D/nomJoueur

# =========================
# Habilidades 
# =========================

var has_doubleJump = false
var can_double_jump = false

var has_spindash = false 

var has_climb = false

# =========================
# CONSTANTES
# =========================

const MAX_SPEED = 360.0
const ACCEL = 216.0
const DECEL = 560.0
const JUMP_VELOCITY = -300.0

const MAX_ROLL_SPEED = 800.0
const MIN_ROLL_SPEED = 50.0
const ROLL_FRICTION = 0.99
const MAX_CHARGE_TIME = 3.0
const MAX_ROLL_DISTANCE = 600.0

# =========================
# ESTADOS
# =========================

enum State {
	NORMAL,
	BRAKING,
	CHARGING,
	ROLLING,
	CLIMBING
}

# =========================
# VARIABLES
# =========================

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var current_state : State = State.NORMAL

var dir = 0.0
var facing_direction = 1.0

var charge_time = 0.0
var roll_speed = 0.0
var roll_distance = 0.0

# =========================
# BUCLE PRINCIPAL (physics_process)
# =========================

func _physics_process(delta):
	dir = Input.get_axis("ui_left", "ui_right")

	apply_gravity(delta) # Aplicamos gravedad en todo momento.

	match current_state:
		State.NORMAL:
			handle_normal(delta)

		State.BRAKING:
			handle_braking(delta)

		State.CHARGING:
			handle_charging(delta)

		State.ROLLING:
			handle_rolling(delta)

	controlar_timer_inactividad()
	controlar_vidas()
	move_and_slide()
	update_animation()

# =========================
# ESTADO NORMAL
# =========================

func handle_normal(delta):
	update_facing_direction()

	if Input.is_action_pressed("ui_down"):
		velocity.x = move_toward(velocity.x, 0.0, DECEL * delta)

		if Input.is_action_just_pressed("charge") and is_on_floor():
			enter_charge()
		return

	if is_on_floor():
		if has_doubleJump:
			can_double_jump = true
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY

	else:
		if Input.is_action_just_pressed("jump") and can_double_jump:
			velocity.y = JUMP_VELOCITY
			can_double_jump = false
			# Opcional: Aquí disparar una partícula o animación especial del doble salto

	if dir != 0:
		var target_speed = dir * MAX_SPEED
		velocity.x = move_toward(velocity.x, target_speed, ACCEL * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, DECEL * delta)

	if Input.is_action_just_pressed("charge") and is_on_floor():
		enter_charge()

	if dir != 0 and sign(dir) != sign(velocity.x) and abs(velocity.x) > (MAX_SPEED * 0.6) and is_on_floor():
		current_state = State.BRAKING
		return

# =========================
# ESTADO BRAKING
# =========================
func handle_braking(delta):
	velocity.x = move_toward(velocity.x, 0.0, DECEL * delta)

	if dir == 0 or abs(velocity.x) <= MIN_ROLL_SPEED:
		current_state = State.NORMAL

	elif sign(dir) == sign(velocity.x):
		current_state = State.NORMAL

# =========================
# ESTADO CHARGING
# =========================

func handle_charging(delta):
	velocity.x = 0.0
	charge_time = min(charge_time + delta, MAX_CHARGE_TIME)

	if not is_on_floor():
		exit_charge()
		return

	if Input.is_action_just_released("charge"):
		enter_roll()

# =========================
# ESTADO ROLLING
# =========================

func handle_rolling(delta):
	roll_speed *= ROLL_FRICTION
	velocity.x = roll_speed

	roll_distance += abs(velocity.x) * delta

	if (roll_distance >= MAX_ROLL_DISTANCE or abs(velocity.x) < MIN_ROLL_SPEED):
		exit_roll()

# =========================
# TRANSICIONES
# =========================

func enter_charge():
	current_state = State.CHARGING
	charge_time = 0.0

func exit_charge():
	current_state = State.NORMAL
	charge_time = 0.0

func enter_roll():
	if not has_spindash :
		exit_charge()
		return
		
	current_state = State.ROLLING
	var charge_percent = charge_time / MAX_CHARGE_TIME

	roll_speed = lerp(MIN_ROLL_SPEED, MAX_ROLL_SPEED, charge_percent ) * facing_direction

	roll_distance = 0.0
	velocity.x = roll_speed

func exit_roll():
	current_state = State.NORMAL
	roll_speed = 0.0
	roll_distance = 0.0

# =========================
# Gravedad
# =========================

func apply_gravity(delta):
	if not is_on_floor() and current_state != State.CHARGING:
		velocity.y += gravity * delta

# =========================
# Orientacion sprite + animacion
# =========================

func update_facing_direction():
	if dir > 0:
		facing_direction = 1.0
	elif dir < 0:
		facing_direction = -1.0

	animated_sprite.flip_h = facing_direction < 0

func update_animation():
	if current_state == State.BRAKING:
		#set_anim("skid")  <- O el nombre que tenga tu animación de frenado/derrape
		return

	if current_state == State.CHARGING:
		set_anim("crouch")
		return

	if current_state == State.ROLLING:
		set_anim("spin")
		return

	if not is_on_floor():
		set_anim("spin")

	elif Input.is_action_pressed("ui_down"):
		set_anim("crouch")

	elif abs(velocity.x) > 300:
		set_anim("run")

	elif abs(velocity.x) > 0:
		set_anim("walk")

	else:
		set_anim("idle")

func set_anim(anim: String):
	if animated_sprite.animation != anim:
		animated_sprite.play(anim)

# =========================
# inicio
# =========================

func _ready() -> void:
	actualizar_label_nombre(DonneesJoueur.nom_joueur)

	DonneesJoueur.nom_change.connect(actualizar_label_nombre)

	if not timer.timeout.is_connected(_on_timer_timeout):
		timer.timeout.connect(_on_timer_timeout)

# =========================
# Nombre jugador
# =========================

func actualizar_label_nombre(nuevo_nombre: String):
	if nom_joueur:
		nom_joueur.text = nuevo_nombre

# =========================
# Inactividad
# =========================

func controlar_timer_inactividad():
	if dir == 0 and velocity.x == 0 and is_on_floor() and current_state == State.NORMAL:
		if timer.is_stopped():
			timer.start(40.0) # Sonic se desespera, so do I

	else:
		if not timer.is_stopped():
			timer.stop()

func _on_timer_timeout():
	get_tree().quit()

func controlar_vidas() :
	pass
