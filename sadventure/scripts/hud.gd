# hud.gd
extends CanvasLayer

@onready var rings_label: Label = $Control/vcontainer/RingsL
@onready var score_label: Label = $Control/vcontainer/scoreL

@onready var name_l: Label = $Control/hcontainer/VBoxContainer/nameL
@onready var vida_l: Label = $Control/hcontainer/VBoxContainer/vidaL


func _ready() -> void:
	name_l.text = DonneesJoueur.nom_joueur

	DonneesJoueur.rings_nivel_changed.connect(_on_rings_changed)
	_on_rings_changed(DonneesJoueur.rings_nivel)

	DonneesJoueur.scoreTotal_changed.connect(_on_score_changed)
	_on_score_changed(DonneesJoueur.scoreTotal)

	DonneesJoueur.vidasP_changed.connect(_on_vida_changed)
	_on_vida_changed(DonneesJoueur.vidasP)

func _on_rings_changed(valor: int) -> void:
	rings_label.text = "RINGS : %d" % valor

func _on_score_changed(valor: int) -> void:
	score_label.text = "SCORE : %d" % valor

func _on_vida_changed(valor:int) -> void:
	vida_l.text = "x %d" % valor
