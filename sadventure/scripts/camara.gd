extends Camera2D

@export var randomStrength : float = 15.0
@export var shakeFade: float = 5.0

var rng = RandomNumberGenerator.new()
var shake_strength: float = 0.0

func apply_shake(custom_strength: float = -1.0) -> void:
	if custom_strength > 0:
		shake_strength = custom_strength
	else:
		shake_strength = randomStrength

func _process (delta):
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength, 0.0, shakeFade * delta)
		offset = randomOffset()
	else:
		offset = Vector2.ZERO

func randomOffset() -> Vector2:
	return Vector2(rng.randf_range(-shake_strength, shake_strength),rng.randf_range(-shake_strength, shake_strength))
