extends CanvasLayer

class_name CombatManager

@onready var player: AnimatedSprite2D = $Player

@onready var panel_combate: Control = $InterfaceCombate 
@onready var label_rings_combate: Label = $InterfaceCombate/Panel/RingsInfo

@onready var boton_doble_salto: Button = $InterfaceCombate/Panel/Habilidades/DoubleJump
@onready var boton_spindash: Button = $InterfaceCombate/Panel/Habilidades/Spindash
@onready var boton_stomp: Button = $InterfaceCombate/Panel/Habilidades/Stomp
@onready var boton_fast_shoe: Button = $InterfaceCombate/Panel/Habilidades/FastShoe



func _ready() -> void:
	if player:
		player.combate_iniciado.connect(_on_player_combate_iniciado)
	else:
		push_warning("CombatManager: No se ha asignado la referencia del Player.")

	if panel_combate:
		panel_combate.visible = false

func _on_player_combate_iniciado(habilidades_jugador: Dictionary, rings_actuales: int) -> void:
	if panel_combate:
		panel_combate.visible = true

	if label_rings_combate:
		label_rings_combate.text = "Rings para defensa: " + str(rings_actuales)

	if boton_doble_salto:
		boton_doble_salto.disabled = not habilidades_jugador.get(Player.ABILITIES.DOUBLEJUMP, false)

	if boton_spindash:
		boton_spindash.disabled = not habilidades_jugador.get(Player.ABILITIES.SPINDASH, false)

	if boton_fast_shoe:
		boton_spindash.disabled = not habilidades_jugador.get(Player.ABILITIES.FAST, false)

	if boton_stomp:
		boton_stomp.disabled = not habilidades_jugador.get(Player.ABILITIES.STOMP, false)

	_configurar_turno_enemigo()

func _configurar_turno_enemigo():
	# Aquí comenzará la lógica de las fases de ataque y defensa del duelo
	pass

func finalizar_combate():
	if panel_combate:
		panel_combate.visible = false
	player.current_state = player.State.NORMAL
