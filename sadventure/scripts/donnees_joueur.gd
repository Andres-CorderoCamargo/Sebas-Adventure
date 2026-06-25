# DonneesJoueur.gd (Autoload)
extends Node

signal nom_change(nouveau_nom)

var nom_joueur := "Sebas"

func set_nom(nouveau_nom):
	nom_joueur = nouveau_nom
	nom_change.emit(nouveau_nom)
