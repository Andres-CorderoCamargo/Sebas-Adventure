extends Area2D

@onready var ring_sprite: AnimatedSprite2D = $ringSprite

func _on_body_entered(body: Node2D) -> void:
	ring_sprite.visible = false
	pass # Replace with function body.
