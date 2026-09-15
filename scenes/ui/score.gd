extends Node2D

const DESTROY_DELAY = 1
var setScore := 0
var combo := 1
var multiplier := 1.0
var player := 1

func _ready() -> void:
	add_to_group("score_popup")
	_refresh_display()
	$anim.play("player" + str(player))
	$destroyDelay.set_wait_time(DESTROY_DELAY)

func add_score(points: int, current_combo: int, current_multiplier: float, target_position: Vector2) -> void:
	setScore += points
	combo = current_combo
	multiplier = current_multiplier
	position = position.lerp(target_position, 0.35)
	_refresh_display()
	$destroyDelay.start(DESTROY_DELAY)

func _refresh_display() -> void:
	$Label.scale = Vector2.ONE
	$Label.set_text("+" + str(setScore))
	if combo >= 2:
		$MultiplierLabel.set_text("x" + str(snapped(multiplier, 0.1)))
		$MultiplierLabel.show()
		$Label.offset_left = 1.0
		$Label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	else:
		$MultiplierLabel.hide()
		$Label.offset_left = -45.0
		$Label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _on_destroyDelay_timeout() -> void:
	queue_free()
