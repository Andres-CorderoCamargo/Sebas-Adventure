extends CharacterBody2D
class_name Player

# =========================
# NODOS
# =========================

@onready var animated_sprite: AnimatedSprite2D = $Sprite
@onready var timerIn: Timer = $TimerInactividad

@onready var hitbox_normal: CollisionShape2D = $HitboxNormal
@onready var hitbox_spin: CollisionShape2D = $HitboxSpin

@onready var camara: Camera2D = $Camara

# =========================
# ENUMS
# =========================

enum ABILITIES { DOUBLEJUMP, FAST, SPINDASH, CLIMB, STOMP }
enum State { NORMAL, BRAKING, CHARGING, ROLLING, CLIMBING, STOMPING }

# =========================
# CONSTANTES
# =========================

const MAX_SPEED = 250.0
const ACCEL = 125.0
const DECEL = 560.0
const JUMP_VELOCITY = -300.0

const ACCEL_GROUND = 120.0
const ACCEL_AIR = 300.0

const MAX_ROLL_SPEED = 600.0
const MIN_ROLL_SPEED = 80.0
const ROLL_FRICTION = 0.995
const MAX_CHARGE_TIME = 3.0
const MAX_ROLL_DISTANCE = 600.0

const STOMP_VELOCITY = 1000.0

# =========================
# DATOS Y HABILIDADES
# =========================

var es_salto_spin := true

var has_doubleJump := false
var can_double_jump := false

var salto := 1.0

var has_spindash := false
var has_climb := false
var has_fast_shoe := true
var has_stomp := true

# =========================
# VARIABLES DE ESTADO Y FÍSICAS
# =========================

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var current_state : State = State.NORMAL

var dir := 0.0
var facing_direction := 1.0

var charge_time := 0.0
var roll_speed := 0.0
var roll_distance := 0.0

# =========================
# BUCLE PRINCIPAL
# =========================

func _ready() -> void:
	if not timerIn.timeout.is_connected(_on_timer_timeout):
		timerIn.timeout.connect(_on_timer_timeout)

func _physics_process(delta: float) -> void:
	dir = Input.get_axis("ui_left", "ui_right")

	apply_gravity(delta)

	match current_state:
		State.NORMAL:   handle_normal(delta)
		State.BRAKING:  handle_braking(delta)
		State.CHARGING: handle_charging(delta)
		State.ROLLING:  handle_rolling(delta)
		State.STOMPING: handle_stomping(delta)

	controlar_timer_inactividad()
	move_and_slide()
	
	update_animation()
	alternar_hitbox()

# =========================
# MANEJO DE ESTADOS
# =========================

func handle_normal(delta: float) -> void:
	update_facing_direction()

	if is_on_floor():
		es_salto_spin = false
		
		if has_doubleJump:
			can_double_jump = true

		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY * salto
			if Input.is_action_pressed("charge"):
				es_salto_spin = false
			else:
				es_salto_spin = true
	
		elif Input.is_action_pressed("ui_down"):
			if abs(velocity.x) > MIN_ROLL_SPEED:
				roll_speed = velocity.x
				velocity = Vector2.ZERO
				current_state = State.ROLLING
				roll_distance = 0.0
				return
			else:
				velocity.x = move_toward(velocity.x, 0.0, DECEL * delta)
				if Input.is_action_just_pressed("charge") and has_spindash:
					enter_charge()
					return
				return

	else:
		if Input.is_action_just_pressed("jump") and can_double_jump:
			velocity.y = JUMP_VELOCITY
			can_double_jump = false
			es_salto_spin = true

		if Input.is_action_just_pressed("charge") and has_stomp:
			enter_stomp()
			return

	if dir != 0:
		var speed_modifier = 1.5 if has_fast_shoe else 1.0
		var target_speed = dir * MAX_SPEED * speed_modifier
		var current_accel = ACCEL_GROUND if is_on_floor() else ACCEL_AIR
		
		velocity.x = move_toward(velocity.x, target_speed, current_accel * delta)

		if is_on_floor() and sign(dir) != sign(velocity.x) and abs(velocity.x) > (MAX_SPEED * 0.6):
			current_state = State.BRAKING
			return
	else:
		velocity.x = move_toward(velocity.x, 0.0, DECEL * delta)

func handle_braking(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, DECEL * delta)

	if dir == 0 or abs(velocity.x) <= MIN_ROLL_SPEED or sign(dir) == sign(velocity.x):
		current_state = State.NORMAL

func handle_charging(delta: float) -> void:
	velocity.x = 0.0
	charge_time = min(charge_time + delta, MAX_CHARGE_TIME)

	if not is_on_floor() and velocity.y > 100.0:
		exit_charge()
		return

	if Input.is_action_just_pressed("charge"):
		charge_time = min(charge_time + 0.8, MAX_CHARGE_TIME)

	if Input.is_action_just_released("ui_down"):
		enter_roll()

func handle_rolling(delta: float) -> void:
	roll_speed *= pow(ROLL_FRICTION, delta * 60.0) 
	velocity.x = roll_speed
	roll_distance += abs(velocity.x) * delta
	
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY * salto
		es_salto_spin = true

		can_double_jump = true 

		exit_roll()
		return

	if roll_distance >= MAX_ROLL_DISTANCE or abs(velocity.x) < MIN_ROLL_SPEED:
		exit_roll()

func handle_stomping(_delta: float) -> void:
	velocity.x = 0.0
	velocity.y = STOMP_VELOCITY

	if is_on_floor():
		if camara and camara.has_method("apply_shake"):
			camara.apply_shake()
		exit_stomp()

# =========================
# TRANSICIONES Y ACCIONES
# =========================

func enter_charge() -> void: #No utilisada de momento
	current_state = State.CHARGING
	velocity = Vector2.ZERO
	hitbox_spinning()
	charge_time = 0.0
	hitbox_normale()

func exit_charge() -> void:
	current_state = State.NORMAL
	charge_time = 0.0;

func enter_roll() -> void:
	if not has_spindash:
		exit_charge()
		return

	current_state = State.ROLLING
	var charge_percent = charge_time / MAX_CHARGE_TIME
	
	roll_speed = lerp(MIN_ROLL_SPEED, MAX_ROLL_SPEED, charge_percent) * facing_direction
	roll_distance = 0.0
	velocity.x = roll_speed

func exit_roll() -> void:
	current_state = State.NORMAL
	roll_speed = 0.0
	roll_distance = 0.0

func enter_stomp() -> void:
	current_state = State.STOMPING
	velocity.x = 0.0 
	velocity.y = STOMP_VELOCITY

func exit_stomp() -> void:
	current_state = State.NORMAL

# =========================
# UTILIDADES Y SISTEMAS
# =========================

func apply_gravity(delta: float) -> void:
	if not is_on_floor() and current_state != State.CHARGING:
		velocity.y += gravity * delta

func esta_invulnerable() -> bool:
	return current_state == State.ROLLING or current_state == State.STOMPING

func controlar_timer_inactividad() -> void:
	if dir == 0 and velocity.x == 0 and is_on_floor() and current_state == State.NORMAL:
		if timerIn.is_stopped():
			timerIn.start(40.0)
	else:
		if not timerIn.is_stopped():
			timerIn.stop()

func _on_timer_timeout() -> void:
	get_tree().quit()

# =========================
# ALTERNAR HITBOX
# =========================

func alternar_hitbox() -> void:
	if current_state == State.ROLLING or current_state == State.STOMPING or (not is_on_floor() and es_salto_spin):
		hitbox_spinning()
	else:
		hitbox_normale()

func hitbox_spinning() -> void:
	hitbox_normal.set_deferred("disabled", true)
	hitbox_spin.set_deferred("disabled", false)

func hitbox_normale() -> void:
	hitbox_normal.set_deferred("disabled", false)
	hitbox_spin.set_deferred("disabled", true)

# =========================
# ANIMACIONES
# =========================

func update_facing_direction() -> void:
	if dir > 0:
		facing_direction = 1.0
	elif dir < 0:
		facing_direction = -1.0
	animated_sprite.flip_h = facing_direction < 0

func update_animation() -> void:
	match current_state:
		State.BRAKING:  return
		State.CHARGING:
			set_anim("charging")
			return
		State.STOMPING:
			set_anim("spin")
			return
		State.ROLLING:
			set_anim("spin")
			return

	if not is_on_floor():
		if es_salto_spin:
			set_anim("spin")
		else:
			set_anim("jump")
	elif Input.is_action_pressed("ui_down") and abs(velocity.x) < 10.0:
		set_anim("crouch")
	elif abs(velocity.x) > 250:
		set_anim("run")
	elif abs(velocity.x) > 150:
		set_anim("fastwalk")
	elif abs(velocity.x) > 0:
		set_anim("walk")
	else:
		set_anim("idle")

func set_anim(anim: String) -> void:
	if animated_sprite.animation != anim:
		animated_sprite.play(anim)
