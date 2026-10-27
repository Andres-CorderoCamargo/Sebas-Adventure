extends CharacterBody2D
class_name Player

# =========================
# NODOS
# =========================

@onready var animated_sprite: AnimatedSprite2D = $Sprite
@onready var timerIn: Timer = $timInaDead
@onready var timerIn2: Timer = $timInaAnim


@onready var hitbox_normal: CollisionShape2D = $HitboxNormal
@onready var hitbox_spin: CollisionShape2D = $HitboxSpin

@onready var camara: Camera2D = $Camara

# =========================
# ENUMS
# =========================

enum ABILITIES { DOUBLEJUMP, FAST, SPINDASH, CLIMB, STOMP }
enum State { NORMAL, BRAKING, CHARGING, ROLLING, CLIMBING, STOMPING, HURT, DEAD}

# =========================
# CONSTANTES
# =========================

const MAX_SPEED = 250.0
const DECEL = 560.0
const JUMP_VELOCITY = -300.0

const ACCEL_GROUND = 280.0
const ACCEL_AIR = 300.0

const MAX_ROLL_SPEED = 800.0
const MIN_ROLL_SPEED = 80.0
const ROLL_FRICTION = 0.995
const MAX_CHARGE_TIME = 3.0

const STOMP_VELOCITY = 1000.0

const SLOPE_FORCE_RUN = 100.0

const SLOPE_ROLL_DOWN = 600.0
const SLOPE_ROLL_UP = 150.0
const MIN_WALL_SPEED = 250.0

const BRAKE_DECEL = 560.0
const STICK_FORCE = 20.0

const STEP_HEIGHT = 8.0

const WALL_DRAG = 150.0

const STOMP_ROLL_SPEED = 700.0

const FLAT_THRESHOLD = 0.98

const DEBUG := false # Para poder ver errores con la linea magica de _physics_process

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

var pre_land_velocity := Vector2.ZERO

var roll_airborne := false

var abilities := {
	ABILITIES.DOUBLEJUMP: true,
	ABILITIES.FAST: true,
	ABILITIES.SPINDASH: true,
	ABILITIES.CLIMB: false,
	ABILITIES.STOMP: true
}

# =========================
# GESTION DE VIDA/GOLPE
# =========================

signal player_died

const HURT_KNOCKBACK := Vector2(150.0, -250.0)
const HURT_MIN_TIME := 0.15          # temps minimum avant de pouvoir se relever
const HURT_INVULN_TIME := 2.0        # invincibilité après un coup
const DEATH_BOUNCE := -400.0
const MAX_SCATTER_RINGS := 20

var is_vulnerable := true
var invuln_timer := 0.0
var hurt_timer := 0.0

const RESPAWN_DELAY := 2.0
const DEATH_Y := 2000.0

var spawn_position := Vector2.ZERO
var original_collision_mask := 1

# =========================
# BUCLE PRINCIPAL
# =========================

func _ready() -> void:
	DonneesJoueur.empezar_nivel()
	spawn_position = global_position
	original_collision_mask = collision_mask

	floor_max_angle = deg_to_rad(60.0)
	safe_margin = 0.08
	floor_snap_length = 2.0
	floor_stop_on_slope = false
	floor_constant_speed = false
	floor_block_on_wall = true

	if not timerIn.timeout.is_connected(_on_timIn_timeout): # Waiting
		timerIn.timeout.connect(_on_timIn_timeout)

	if not timerIn2.timeout.is_connected(_on_timIn2_timeout):  # Dead for waiting 
		timerIn2.timeout.connect(_on_timIn2_timeout)

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
		State.HURT:     handle_hurting(delta)
		# No hace falta DEAD porque pos se muere xD

	controlar_timer_inactividad()

	if current_state == State.ROLLING:
		var normal_suelo := get_floor_normal()
		var subiendo_rampa := is_on_floor() and roll_speed * normal_suelo.x < 0.0 and normal_suelo.y > -FLAT_THRESHOLD
		if subiendo_rampa:
			floor_snap_length = 2.0
		else:
			floor_snap_length = clampf(abs(roll_speed) * delta * 1.5, 2.0, 16.0)
	else:
		floor_snap_length = 2.0

	move_and_slide()

	if global_position.y > DEATH_Y and current_state != State.DEAD: # C murio ! qwq
		die()

	update_vulnerability(delta) 
	update_floor_grace(delta)
	update_sprite_orientation(delta)
	update_animation()
	alternar_hitbox()
	if DEBUG: # La linea magica.
		print("floor=", is_on_floor(), " wall=", is_on_wall(), " n=", get_floor_normal(), " vel=", velocity.snapped(Vector2(0.1, 0.1)), " state=", current_state)
# =========================
# MANEJO DE ESTADOS
# =========================

func handle_normal(delta: float) -> void:
	if is_on_floor() and detach_timer <= 0.0:
		var venia_en_spin := es_salto_spin
		es_salto_spin = false
		if has_abilities(ABILITIES.DOUBLEJUMP):
			can_double_jump = true

		var n := get_floor_normal()

		if venia_en_spin and -n.y < FLAT_THRESHOLD:
			var tangente_aterrizaje := Vector2(-n.y, n.x)
			if abs(velocity.dot(tangente_aterrizaje)) >= MIN_ROLL_SPEED:
				enter_stomp_roll(n)
				return

		var tangent := Vector2(-n.y, n.x)
		var ground_speed := velocity.dot(tangent)

		# Superficie muy empinada y poca velocidad: te despegas y caes
		if n.y > -0.7 and abs(ground_speed) < MIN_WALL_SPEED:
			detach_timer = 0.2
			velocity = n * 80.0
			return

		# Escalón pequeño: si empujas contra una pared, intenta subirla
		if is_on_wall() and dir != 0:
			try_step_up(dir)

		var steep := n.y > -0.7   # pared, techo o curva muy inclinada

		var slope_force := tangent.y * SLOPE_FORCE_RUN
		if dir != 0:
			slope_force *= 0.15
		ground_speed += slope_force * delta

		# En superficies empinadas siempre pierdes velocidad
		if steep:
			ground_speed = move_toward(ground_speed, 0.0, WALL_DRAG * delta)

		# Salto
		if Input.is_action_just_pressed("jump"):
			velocity = tangent * ground_speed + n * (-JUMP_VELOCITY * salto)
			es_salto_spin = not Input.is_action_pressed("charge")
			if es_salto_spin:
				roll_speed = ground_speed
				roll_airborne = true
				pre_land_velocity = velocity
				current_state = State.ROLLING
			return

		# Agacharse / rodar
		if Input.is_action_pressed("ui_down"):
			if abs(ground_speed) > MIN_ROLL_SPEED:
				roll_speed = ground_speed
				velocity = tangent * roll_speed
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
		if Input.is_action_just_pressed("jump") and can_double_jump and detach_timer <= 0.0:
			velocity.y = JUMP_VELOCITY
			can_double_jump = false
			es_salto_spin = true

		if Input.is_action_just_pressed("charge") and has_abilities(ABILITIES.STOMP) and detach_timer <= 0.0:
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
	# En el aire
	if not is_on_floor():
		roll_airborne = true
		es_salto_spin = true

		# Doble salto
		if Input.is_action_just_pressed("jump") and can_double_jump:
			velocity.y = JUMP_VELOCITY
			can_double_jump = false

		# Stomp
		if Input.is_action_just_pressed("charge") and has_abilities(ABILITIES.STOMP):
			enter_stomp()
			return

		# Control aéreo
		var speed_modifier := 1.5 if has_abilities(ABILITIES.FAST) else 1.0
		if dir != 0:
			velocity.x = move_toward(velocity.x, dir * MAX_SPEED * speed_modifier, ACCEL_AIR * delta)

		# Guardamos la velocidad al final, para que incluya los cambios de arriba
		pre_land_velocity = velocity
		return

	# En el aire
	var n := get_floor_normal()
	var tangent := Vector2(-n.y, n.x)
	var plano := clampf(-n.y, 0.0, 1.0)

	# Justo al aterrizar
	if roll_airborne:
		roll_speed = pre_land_velocity.dot(tangent)
		roll_airborne = false

		# Suelo plano
		if plano >= FLAT_THRESHOLD:
			velocity = tangent * roll_speed
			es_salto_spin = false
			exit_roll()
			return

		# Pendiente sigue rodando
		if abs(roll_speed) > 1.0:
			facing_direction = signf(roll_speed)

	# Chocas con una pared y casi no avanzas: dejas de rodar
	elif is_on_wall() and absf(velocity.dot(tangent)) < absf(roll_speed) * 0.5:
		exit_roll()
		return

	# Fricción
	var friccion := lerpf(1.0, ROLL_FRICTION, plano)
	roll_speed *= pow(friccion, delta * 60.0)

	# Gravedad sobre la pendiente
	var subiendo := roll_speed * tangent.y < 0.0
	var pendiente := plano < FLAT_THRESHOLD
	var fuerza := SLOPE_ROLL_UP if subiendo else SLOPE_ROLL_DOWN
	roll_speed += tangent.y * fuerza * delta

	# Paredes muy inclinadas
	if n.y > -0.8:
		roll_speed = move_toward(roll_speed, 0.0, WALL_DRAG * delta)

	roll_speed = clampf(roll_speed, -MAX_ROLL_SPEED * 1.5, MAX_ROLL_SPEED * 1.5)

	# Subes una pendiente sin fuerza
	if pendiente and subiendo and abs(roll_speed) < MIN_ROLL_SPEED:
		detach_timer = 0.2
		velocity = tangent * roll_speed + n * 80.0
		pre_land_velocity = velocity
		es_salto_spin = true
		roll_airborne = true
		return

	# Sin velocidad en plano
	if not pendiente and abs(roll_speed) < MIN_ROLL_SPEED:
		exit_roll()
		return

	# Salto desde el suelo
	if Input.is_action_just_pressed("jump"):
		es_salto_spin = true
		can_double_jump = has_abilities(ABILITIES.DOUBLEJUMP)
		velocity = tangent * roll_speed + n * (-JUMP_VELOCITY * salto)
		pre_land_velocity = velocity
		roll_airborne = true
		return

	# Movimiento normal de rodar
	var pegado_fuerza := 0.0 if (subiendo and pendiente) else STICK_FORCE
	velocity = tangent * roll_speed - n * pegado_fuerza

func handle_stomping(_delta: float) -> void:
	velocity.x = 0.0
	velocity.y = STOMP_VELOCITY

	if not is_on_floor():
		return

	if camara and camara.has_method("apply_shake"):
		camara.apply_shake()

	var n := get_floor_normal()
	var flatness := clampf(-n.y, 0.0, 1.0)

	if flatness < FLAT_THRESHOLD:
		enter_stomp_roll(n)
	else:
		velocity = Vector2.ZERO
		exit_stomp()
	
func enter_stomp_roll(n: Vector2) -> void:
	var tangent := Vector2(-n.y, n.x)  

	roll_speed = clampf(velocity.dot(tangent), -MAX_ROLL_SPEED * 1.5, MAX_ROLL_SPEED * 1.5)
	velocity = tangent * roll_speed
	if absf(roll_speed) > 1.0:
		facing_direction = signf(roll_speed)

	current_state = State.ROLLING

	roll_airborne = false	

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

	roll_airborne = false

func exit_roll() -> void:
	current_state = State.NORMAL
	roll_speed = 0.0
	roll_airborne = false

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
	return current_state == State.ROLLING or current_state == State.STOMPING \
		or current_state == State.CHARGING or (es_salto_spin and not is_on_floor())

func controlar_timer_inactividad() -> void:
	if dir == 0 and velocity.length() < 25.0 and is_on_floor() and current_state == State.NORMAL:
		if timerIn.is_stopped():
			timerIn.start(60.0)
		if timerIn2.is_stopped():
			timerIn2.start(30.0)
	else:
		if not timerIn.is_stopped():
			timerIn.stop()
		if not timerIn2.is_stopped():
			timerIn2.stop();

func _on_timIn_timeout() -> void:
	if OS.has_feature("editor"):
		get_tree().quit()
	else: 
		set_anim("waiting")

func _on_timIn2_timeout() -> void:
	if OS.has_feature("editor"):
		get_tree().quit()
	else: 
		set_anim("dead")

func try_step_up(direction: float) -> void:
	if direction == 0.0:
		return

	var forward := Vector2(sign(direction) * 2.0, 0.0)

	var h := 1.0
	while h <= STEP_HEIGHT:
		var raised := global_transform.translated(Vector2(0, -h))
		# Libre arriba (no choca al subir) y libre al avanzar desde ahí
		if not test_move(global_transform, Vector2(0, -h)) and not test_move(raised, forward):
			global_position.y -= h
			return
		h += 1.0

func update_floor_grace(delta: float) -> void:
	if is_on_floor():
		floor_grace = 0.1
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
	if current_state == State.DEAD:
		return
	if current_state == State.ROLLING or current_state == State.STOMPING or (not is_on_floor() and es_salto_spin) or current_state == State.CHARGING:
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
# VULNERABILIDAD
# =========================

func update_vulnerability(delta: float) -> void:
	invuln_timer = max(invuln_timer - delta, 0.0)

	var saltando_spin := es_salto_spin and not is_on_floor()

	is_vulnerable = (current_state == State.NORMAL or current_state == State.BRAKING) \
		and not saltando_spin \
		and invuln_timer <= 0.0

	if invuln_timer > 0.0:
		animated_sprite.visible = int(invuln_timer * 20.0) % 2 == 0
	else:
		animated_sprite.visible = true

func get_hit(valeur: int = 1, source_position: Vector2 = Vector2.ZERO) -> void:
	if not is_vulnerable:
		return

	if DonneesJoueur.rings_nivel > 0:
		var lost := DonneesJoueur.quitar_rings_nivel(valeur)
		scatter_rings(lost)
		enter_hurt(source_position)
	else:
		die()

func enter_hurt(source_position: Vector2) -> void:
	current_state = State.HURT
	hurt_timer = HURT_MIN_TIME
	invuln_timer = HURT_INVULN_TIME
	is_vulnerable = false
	es_salto_spin = false
	roll_speed = 0.0
	charge_time = 0.0

	# Recul à l'opposé de la source du coup
	var push_dir := -facing_direction
	if source_position != Vector2.ZERO:
		push_dir = signf(global_position.x - source_position.x)
		if push_dir == 0.0:
			push_dir = -facing_direction
	velocity = Vector2(HURT_KNOCKBACK.x * push_dir, HURT_KNOCKBACK.y)
	up_direction = Vector2.UP

func handle_hurting(delta: float) -> void:
	hurt_timer -= delta
	if hurt_timer <= 0.0 and is_on_floor():
		velocity.x = 0.0
		current_state = State.NORMAL

func die() -> void:
	if current_state == State.DEAD:
		return

	current_state = State.DEAD
	is_vulnerable = false
	DonneesJoueur.change_vidas(-1)
	player_died.emit()

	velocity = Vector2(0.0, DEATH_BOUNCE)
	hitbox_normal.set_deferred("disabled", true)
	hitbox_spin.set_deferred("disabled", true)
	set_deferred("collision_mask", 0)

	await get_tree().create_timer(RESPAWN_DELAY).timeout

	if DonneesJoueur.vidasP > 0:
		respawn()
	else:
		game_over()

func respawn() -> void:
	collision_mask = original_collision_mask
	global_position = spawn_position
	velocity = Vector2.ZERO
	reset_physics_interpolation()

	DonneesJoueur.perder_rings_nivel()

	current_state = State.NORMAL
	invuln_timer = HURT_INVULN_TIME
	up_direction = Vector2.UP
	smooth_normal = Vector2.UP
	animated_sprite.rotation = 0.0
	es_salto_spin = false
	roll_speed = 0.0
	charge_time = 0.0
	detach_timer = 0.0
	floor_grace = 0.0

	if camara:
		camara.reset_smoothing()

func game_over() -> void:
	DonneesJoueur.reiniciar_vidas()
	DonneesJoueur.empezar_nivel()   # rings del nivel a 0
	get_tree().change_scene_to_file("res://scenes/game_over.tscn")

func scatter_rings(amount: int) -> void: # A IMPLEMENTAR
	#if ring_scene == null:
		return
	

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
	hitbox_normal.rotation = animated_sprite.rotation

	if current_state == State.BRAKING or current_state == State.HURT or current_state == State.ROLLING:
		pass
	elif dir > 0:
		facing_direction = 1.0
	elif dir < 0:
		facing_direction = -1.0
	animated_sprite.flip_h = facing_direction < 0

	if facing_direction < 0:
		hitbox_normal.position.x = -abs(hitbox_normal.position.x)
	else:
		hitbox_normal.position.x = abs(hitbox_normal.position.x)

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
		State.HURT:
			set_anim("hurt")
			return
		State.DEAD:
			set_anim("dead")
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
