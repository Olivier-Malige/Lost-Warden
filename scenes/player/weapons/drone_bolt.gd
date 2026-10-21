extends "res://scenes/player/player_shot.gd"

var age := 0.0

func prepare() -> void:
	super.prepare()
	age = 0.0

func setPowerAnim() -> void:
	$Sprite2D.frame = (4 if player_Id == "player2" else 0) + int(age / 0.06) % 4
	rotation = Vector2.UP.angle_to(Vector2(speedX, speedY))

func _physics_process(delta: float) -> void:
	age += delta
	setPowerAnim()
	super._physics_process(delta)
