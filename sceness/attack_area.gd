extends Area2D

func _ready():
	area_entered.connect(_on_area_entered)

func _on_area_entered(body):
	if "PLAYER" in body.name:
		body.take_damage(40)  # same as ATTACK_DAMAGE
