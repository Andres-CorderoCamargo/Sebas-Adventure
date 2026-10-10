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
const DECEL = 560.0
const JUMP_VELOCITY = -300.0

const ACCEL_GROUND = 280.0
const ACCEL_AIR = 300.0

const MAX_ROLL_SPEED = 600.0
const MIN_ROLL_SPEED = 80.0
const ROLL_FRICTION = 0.995
const MAX_CHARGE_TIME = 3.0

const STOMP_VELOCITY = 1000.0

const SLOPE_FORCE_RUN = 100.0

const SLOPE_ROLL_DOWN = 600.0
const SLOPE_ROLL_UP = 250.0
const MIN_WALL_SPEED = 180.0

const BRAKE_DECEL = 560.0
const STICK_FORCE = 20.0

const STEP_HEIGHT = 8.0

const WALL_DRAG = 150.0

# =========================
# DATOS Y HABILIDADES
# =========================

var es_salto_spin := true

var can_double_jump := false

var salto := 1.0

# =========================
# VARIABLES DE ESTADO Y FÍSICAS
# =========================

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var current_state : State = State.NORMAL

var dir := 0.0
var facing_direction := 1.0

var charge_time := 0.0
var roll_speed := 0.0

var detach_timer := 0.0

var floor_grace := 0.0

var smooth_normal := Vector2.UP


var abilities := {
	ABILITIES.DOUBLEJUMP: true,
	ABILITIES.FAST: true,
	ABILITIES.SPINDASH: true,
	ABILITIES.CLIMB: false,
	ABILITIES.STOMP: true
}

# =========================
# BUCLE PRINCIPAL
# =========================

func _ready() -> void:
	floor_max_angle = deg_to_rad(60.0)
	safe_margin = 0.1
	floor_snap_length = 16.0
	floor_stop_on_slope = false
	floor_constant_speed = false
	floor_block_on_wall = true

	if not timerIn.timeout.is_connected(_on_timer_timeout):
		timerIn.timeout.connect(_on_timer_timeout)

func _physics_process(delta: float) -> void:
	detach_timer = max(detach_timer - delta, 0.0)
	dir = Input.get_axis("ui_left", "ui_right")
	update_up_direction()
	apply_gravity(delta)

	match current_state:
		State.NORMAL:   handle_normal(delta)
		State.BRAKING:  handle_braking(delta)
		State.CHARGING: handle_charging(delta)
		State.ROLLING:  handle_rolling(delta)
		State.STOMPING: handle_stomping(delta)

	controlar_timer_inactividad()
	move_and_slide()

	update_floor_grace(delta)
	update_sprite_orientation(delta)
	update_animation()
	alternar_hitbox()
	# Linea magica debugeadora
	# print("floor=", is_on_floor(), " wall=", is_on_wall(), " n=", get_floor_normal(), " vel=", velocity.snapped(Vector2(0.1, 0.1)), " state=", current_state)
# =========================
# MANEJO DE ESTADOS
# =========================

func handle_normal(delta: float) -> void:
	if is_on_floor() and detach_timer <= 0.0:
		es_salto_spin = false
		if has_abilities(ABILITIES.DOUBLEJUMP):
			can_double_jump = true

		var n := get_floor_normal()
		var tangent := Vector2(-n.y, n.x)
		var ground_speed := velocity.dot(tangent)

		# Superficie muy empinada y poca velocidad: te despegas y caes
		if n.y > -0.7 and abs(ground_speed) < MIN_WALL_SPEED:
			detach_timer = 0.2
			velocity = n * 80.0
			return

		## Escalón pequeño: si empujas contra una pared, intenta subirla
		#if is_on_wall() and dir != 0:
			#try_step_up(dir)

		var steep := n.y > -0.7   # pared, techo o curva muy inclinada

		var slope_force := tangent.y * SLOPE_FORCE_RUN
		if dir != 0:
			slope_force *= 0.15
		ground_speed += slope_force * delta

		# En superficies empinadas siempre pierdes velocidad
		if steep:
			ground_speed = move_toward(ground_speed, 0.0, WALL_DRAG * delta)

		# Salto ---
		if Input.is_action_just_pressed("jump"):
			velocity = tangent * ground_speed + n * (-JUMP_VELOCITY * salto)
			es_salto_spin = not Input.is_action_pressed("charge")
			return

		# Agacharse / rodar
		if Input.is_action_pressed("ui_down"):
			if abs(ground_speed) > MIN_ROLL_SPEED:
				roll_speed = ground_speed
				velocity = Vector2.ZERO
				current_state = State.ROLLING
				return
			else:
				ground_speed = move_toward(ground_speed, 0.0, DECEL * delta)
				velocity = tangent * ground_speed - n * STICK_FORCE
				if Input.is_action_just_pressed("charge") and has_abilities(ABILITIES.SPINDASH):
					enter_charge()
				return

		# Frenar (antes de acelerar)
		if dir != 0 and sign(dir) != sign(ground_speed) and abs(ground_speed) > MAX_SPEED * 0.6:
			velocity = tangent * ground_speed - n * STICK_FORCE
			current_state = State.BRAKING
			return

		# Correr
		if dir != 0:
			var speed_modifier = 1.5 if has_abilities(ABILITIES.FAST) else 1.0
			var target_speed = dir * MAX_SPEED * speed_modifier
			ground_speed = move_toward(ground_speed, target_speed, ACCEL_GROUND * delta)
		else:
			var decel := DECEL * clampf(-n.y, 0.0, 1.0)
			ground_speed = move_toward(ground_speed, 0.0, decel * delta)

		velocity = tangent * ground_speed - n * STICK_FORCE

	else:
		# En el aire
		if Input.is_action_just_pressed("jump") and can_double_jump:
			velocity.y = JUMP_VELOCITY
			can_double_jump = false
			es_salto_spin = true

		if Input.is_action_just_pressed("charge") and has_abilities(ABILITIES.STOMP):
			enter_stomp()
			return

		if dir != 0:
			var speed_modifier = 1.5 if has_abilities(ABILITIES.FAST) else 1.0
			velocity.x = move_toward(velocity.x, dir * MAX_SPEED * speed_modifier, ACCEL_AIR * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, DECEL * delta)

func handle_braking(delta: float) -> void:
	if not is_on_floor():
		current_state = State.NORMAL
		return

	var n := get_floor_normal()
	var tangent := Vector2(-n.y, n.x)
	var ground_speed := velocity.dot(tangent)

	ground_speed += tangent.y * SLOPE_FORCE_RUN * delta
	ground_speed = move_toward(ground_speed, 0.0, BRAKE_DECEL * delta)

	velocity = tangent * ground_speed - n * STICK_FORCE

	if dir == 0 or abs(ground_speed) <= MIN_ROLL_SPEED or sign(dir) == sign(ground_speed):
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
	if is_on_floor():
		var n := get_floor_normal()
		var tangent := Vector2(-n.y, n.x)
		var plano := clampf(-n.y, 0.0, 1.0)   # 1 = suelo plano, 0 = pared

		# La fricción solo actúa en suelo plano
		var friccion := lerpf(1.0, ROLL_FRICTION, plano)
		roll_speed *= pow(friccion, delta * 60.0)

		# Pendiente: subir frena poco, y menos aún en paredes
		var bajando := roll_speed * tangent.y > 0.0
		var fuerza := SLOPE_ROLL_DOWN
		if not bajando:
			fuerza = SLOPE_ROLL_UP * lerpf(0.4, 1.0, plano)
		roll_speed += tangent.y * fuerza * delta

		velocity = tangent * roll_speed - n * STICK_FORCE

		if n.y > -0.7:
			roll_speed = move_toward(roll_speed, 0.0, WALL_DRAG * delta)

		if Input.is_action_just_pressed("jump"):
			velocity = tangent * roll_speed + n * (-JUMP_VELOCITY * salto)
			es_salto_spin = true
			can_double_jump = true
			exit_roll()
			return
	else:
		roll_speed *= pow(ROLL_FRICTION, delta * 60.0)
		velocity.x = roll_speed

	if abs(roll_speed) < MIN_ROLL_SPEED:
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

func enter_charge() -> void:
	current_state = State.CHARGING
	velocity = Vector2.ZERO
	charge_time = 0.0

func exit_charge() -> void:
	current_state = State.NORMAL
	charge_time = 0.0

func enter_roll() -> void:
	if not has_abilities(ABILITIES.SPINDASH):
		exit_charge()
		return

	current_state = State.ROLLING
	var charge_percent = charge_time / MAX_CHARGE_TIME
	
	roll_speed = lerp(MIN_ROLL_SPEED, MAX_ROLL_SPEED, charge_percent) * facing_direction
	velocity.x = roll_speed

func exit_roll() -> void:
	current_state = State.NORMAL
	roll_speed = 0.0

func enter_stomp() -> void:
	current_state = State.STOMPING
	velocity.x = 0.0 
	velocity.y = STOMP_VELOCITY

func exit_stomp() -> void:
	current_state = State.NORMAL

# =========================
# UTILIDADES Y SISTEMAS
# =========================

func has_abilities(a: ABILITIES) -> bool:
	return abilities.get(a, false)

func unlock_habilities(a: ABILITIES) -> void: # para la futura tienda !
	abilities[a] = true

func update_up_direction() -> void:
	if detach_timer > 0.0:
		up_direction = Vector2.UP
		return

	var en_superficie := current_state == State.NORMAL or current_state == State.ROLLING or current_state == State.BRAKING

	if is_on_floor() and en_superficie:
		var n := get_floor_normal()
		var muy_inclinada := n.y > -0.7   # más de ~45°
		if muy_inclinada and velocity.length() >= MIN_WALL_SPEED:
			up_direction = n
		else:
			up_direction = Vector2.UP
	else:
		up_direction = Vector2.UP

func apply_gravity(delta: float) -> void:
	var pegado := detach_timer <= 0.0 and is_on_floor() and (current_state == State.NORMAL or current_state == State.ROLLING or current_state == State.BRAKING)
	if pegado:
		return
	velocity.y += gravity * delta

func detach_from_surface() -> void:
	up_direction = Vector2.UP
	exit_roll()

func esta_invulnerable() -> bool:
	return current_state == State.ROLLING or current_state == State.STOMPING

func controlar_timer_inactividad() -> void:
	if dir == 0 and velocity.length() < 25.0 and is_on_floor() and current_state == State.NORMAL:
		if timerIn.is_stopped():
			timerIn.start(40.0)
	else:
		if not timerIn.is_stopped():
			timerIn.stop()

func _on_timer_timeout() -> void:
	if OS.has_feature("editor"):
		get_tree().quit()

#func try_step_up(direction: float) -> void:
	#if direction == 0.0:
		#return
#
	#var forward := Vector2(sign(direction) * 2.0, 0.0)
#
	#var h := 1.0
	#while h <= STEP_HEIGHT:
		#var raised := global_transform.translated(Vector2(0, -h))
		## Libre arriba (no choca al subir) y libre al avanzar desde ahí
		#if not test_move(global_transform, Vector2(0, -h)) and not test_move(raised, forward):
			#global_position.y -= h
			#return
		#h += 1.0

func update_floor_grace(delta: float) -> void:
	if is_on_floor():
		floor_grace = 0.08
		smooth_normal = smooth_normal.lerp(get_floor_normal(), 12.0 * delta).normalized()
	else:
		floor_grace = max(floor_grace - delta, 0.0)
		smooth_normal = smooth_normal.lerp(Vector2.UP, 6.0 * delta).normalized()

func en_suelo() -> bool:
	return floor_grace > 0.0

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

func update_sprite_orientation(delta: float) -> void:
	var target_rotation := 0.0

	var girando := current_state == State.ROLLING \
		or current_state == State.STOMPING \
		or current_state == State.CHARGING

	if en_suelo() and not girando:
		var ang := smooth_normal.angle() + PI / 2.0
		if abs(ang) > deg_to_rad(8.0):
			target_rotation = ang

	animated_sprite.rotation = lerp_angle(animated_sprite.rotation, target_rotation, 12.0 * delta)

	if current_state == State.BRAKING:
		pass
	elif dir > 0:
		facing_direction = 1.0
	elif dir < 0:
		facing_direction = -1.0
	animated_sprite.flip_h = facing_direction < 0

func update_animation() -> void:
	match current_state:
		State.BRAKING:
			return
		State.CHARGING:
			set_anim("charging")
			return
		State.STOMPING, State.ROLLING:
			set_anim("spin")
			return

	var speed := velocity.length()

	if not en_suelo():
		if es_salto_spin:
			set_anim("spin")
		else:
			set_anim("jump")
	elif Input.is_action_pressed("ui_down") and speed < 10.0:
		set_anim("crouch")
	elif speed > 250:
		set_anim("run")
	elif speed > 150:
		set_anim("fastwalk")
	elif speed > 25:
		set_anim("walk")
	else:
		set_anim("idle")

func set_anim(anim: String) -> void:
	if animated_sprite.animation != anim:
		animated_sprite.play(anim)
