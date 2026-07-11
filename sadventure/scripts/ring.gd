extends Area2D

signal ring_collected

@onready var ring_sprite: AnimatedSprite2D = $ringSprite
@onready var ring_sound: AudioStreamPlayer2D = $ringSound

func _on_body_entered(body: Node2D) -> void:
	if not body is Player:         
		return
	
	print("I'm ok")
	ring_sprite.visible = false
	ring_sound.play()
	set_deferred("monitoring", false)
	ring_collected.emit()
 
func _on_ring_sound_finished() -> void:
	queue_free()
