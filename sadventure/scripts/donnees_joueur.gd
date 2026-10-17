# DonneesJoueur.gd (Autoload)
extends Node

signal nom_change(nouveau_nom)
signal rings_nivel_changed(nuevo_valor)
signal rings_totales_changed(nuevo_valor)
signal scoreTotal_changed(nuevo_valor)
signal vidasP_changed(nuevo_valor)

var nom_joueur := "Sebas"
var ringsTotales: int = 0      # los de la partida (para la tienda)
var scoreTotal: int = 0        # para scores jaja
var vidasP: int = 3

var rings_nivel: int = 0       # los del nivel actual
const MAX_VIDAS := 3

func set_nom(nouveau_nom: String) -> void:
	nom_joueur = nouveau_nom
	nom_change.emit(nouveau_nom)

func add_ring(cantidad: int = 1) -> void:
	rings_nivel += cantidad
	rings_nivel_changed.emit(rings_nivel)

func empezar_nivel() -> void:
	rings_nivel = 0
	rings_nivel_changed.emit(rings_nivel)

func terminar_nivel() -> void:
	ringsTotales += rings_nivel
	rings_totales_changed.emit(ringsTotales)
	rings_nivel = 0
	rings_nivel_changed.emit(rings_nivel)

func perder_rings_nivel() -> void:   # para cuando te golpeen
	rings_nivel = 0
	rings_nivel_changed.emit(rings_nivel)

func gastar_rings(cantidad: int) -> bool:   # para la tienda
	if ringsTotales < cantidad:
		return false
	ringsTotales -= cantidad
	rings_totales_changed.emit(ringsTotales)
	return true

func add_score(cantidad: int) -> void:
	scoreTotal += cantidad
	scoreTotal_changed.emit(scoreTotal)

func change_vidas(cantidad: int) -> void :
	vidasP += cantidad
	vidasP_changed.emit(vidasP)

# Quita hasta "cantidad" rings y devuelve cuántos se perdieron realmente
func quitar_rings_nivel(cantidad: int) -> int:
	var perdidos : int = min(cantidad, rings_nivel)
	rings_nivel -= perdidos
	rings_nivel_changed.emit(rings_nivel)
	return perdidos

func reiniciar_vidas() -> void:
	vidasP = MAX_VIDAS
	vidasP_changed.emit(vidasP)
