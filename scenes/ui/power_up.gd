extends Area2D
const SPEED = 100
const TABLE: UpgradeTable = preload("res://data/upgrades/upgrade_table.tres")
const Layers := preload("res://core/collision_layers.gd")

var _upgrade: UpgradeDefinition

func _ready() -> void:
	add_to_group("powersUp")
	collision_layer = Layers.PICKUP
	collision_mask = Layers.PLAYER
	_upgrade = TABLE.pick()
	if _upgrade:
		$anim.play(String(_upgrade.anim))
		$Sprite2D.modulate = _pickup_color(_upgrade.effect)
		$Sprite2D.visible = _upgrade.effect != UpgradeDefinition.Effect.BEAM
		$BeamIcon.visible = _upgrade.effect == UpgradeDefinition.Effect.BEAM
	else:
		$anim.play("speedUp")

func _physics_process(delta: float) -> void:
	translate(Vector2(0, SPEED) * delta)

func _on_screen_exited() -> void:
	queue_free()

func _on_powerUp_area_entered(area: Area2D) -> void:
	if not area.is_in_group("player"):
		return
	if area.has_method("apply_upgrade"):
		area.apply_upgrade(_upgrade)
	_play_pickup_sound()
	Events.powerup_collected.emit(_upgrade)
	$anim.queue_free()
	$Sprite2D.queue_free()
	$BeamIcon.queue_free()
	$CollisionShape2D.set_deferred("disabled", true)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

func _play_pickup_sound() -> void:
	if _upgrade == null:
		return
	var sounds: Dictionary[int, AudioStreamPlayer2D] = {
		UpgradeDefinition.Effect.SPEED: $sound_Speed_Up,
		UpgradeDefinition.Effect.ENERGY: $sound_Energy_Up,
		UpgradeDefinition.Effect.SIDE_SHOT: $sound_Lateral_Shot,
		UpgradeDefinition.Effect.DAMAGE: $sound_Shot_Up,
		UpgradeDefinition.Effect.SHIELD: $sound_Shield,
		UpgradeDefinition.Effect.FIRE_RATE: $sound_Shot_Up,
		UpgradeDefinition.Effect.BEAM: $sound_Shot_Up,
	}
	if sounds.has(_upgrade.effect):
		sounds[_upgrade.effect].playing = true

func _pickup_color(effect: int) -> Color:
	match effect:
		UpgradeDefinition.Effect.FIRE_RATE:
			return Color(0.9, 0.78, 0.2)
		UpgradeDefinition.Effect.BEAM:
			return Color(0.74, 0.59, 0.9)
		_:
			return Color.WHITE

func _on_audio_finished() -> void:
	queue_free()
