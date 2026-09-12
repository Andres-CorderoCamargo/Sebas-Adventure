extends CharacterBody2D
class_name Player

# =========================
# NODOS
# =========================

@onready var animated_sprite: AnimatedSprite2D = $Sprite
@onready var timerIn: Timer = $TimerInactividad

@onready var hitbox_normal: CollisionShape2D = $HitboxNormal
@onready var hitbox_spin: CollisionShape2D = $HitboxSpin

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

const MAX_ROLL_SPEED = 800.0
const MIN_ROLL_SPEED = 50.0
const ROLL_FRICTION = 0.99
const MAX_CHARGE_TIME = 3.0
const MAX_ROLL_DISTANCE = 600.0

const STOMP_VELOCITY = 1000.0

# =========================
# DATOS Y HABILIDADES
# =========================

var es_salto_spin := false

var has_doubleJump := true
var can_double_jump := false

var has_spindash := true 
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
		State.STOMPING: handle_stomp(delta)

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
			velocity.y = JUMP_VELOCITY 
			if Input.is_action_pressed("ui_down"):
				es_salto_spin = true
			else:
				es_salto_spin = false
	
		elif Input.is_action_pressed("ui_down") and abs(velocity.x) < 10.0:
			velocity.x = move_toward(velocity.x, 0.0, DECEL * delta)
			if Input.is_action_just_pressed("charge"):
				enter_charge()
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

	if not is_on_floor():
		exit_charge()
		return

	if Input.is_action_just_released("charge"):
		enter_roll()

func handle_rolling(delta: float) -> void:
	roll_speed *= ROLL_FRICTION
	velocity.x = roll_speed
	roll_distance += abs(velocity.x) * delta

	if roll_distance >= MAX_ROLL_DISTANCE or abs(velocity.x) < MIN_ROLL_SPEED:
		exit_roll()

func handle_stomp(_delta: float) -> void:
	velocity.x = 0.0
	velocity.y = STOMP_VELOCITY

	if is_on_floor():
		exit_stomp()

# =========================
# TRANSICIONES Y ACCIONES
# =========================

func enter_charge() -> void:
	current_state = State.CHARGING
	charge_time = 0.0

func exit_charge() -> void:
	current_state = State.NORMAL
	charge_time = 0.0

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
		State.CHARGING, State.STOMPING:
			set_anim("crouch")
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
