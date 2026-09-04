extends Area2D
const Layers := preload("res://core/collision_layers.gd")

var power = 0: set = _set_Power
var animPower

const POWER_ANIMS := ["", "_Smallest", "_Small", "_Normal", "_Big", "_Very_Big", "_Full"]


func _ready() -> void:
	collision_layer = Layers.PLAYER
	collision_mask = Layers.ENEMY_SHOT
	_set_AnimPower()

# Thrown-back shots must be able to hit the enemy that fired them.
func _on_shield_area_entered(shot: Shot) -> void:
	if shot.is_in_group("enemy_Shot") and power > 0 and not shot.trowbackByShield:
		shot.noDamageToGroup = ""
		$sound_trowback.playing = true
		shot.trowbackByShield = true
		shot.speedY = -shot.speedY
		shot.speedX = -shot.speedX
		if $AnimationPlayer.current_animation != get_parent().id_Player + animPower + "_Hit":
			$AnimationPlayer.play(get_parent().id_Player + animPower + "_Hit")

func _set_AnimPower() -> void:
	visible = power > 0
	if power > 0:
		animPower = POWER_ANIMS[power]

func _set_Power(up: int) -> void:
	power = clampi(power + up, 0, 6)
	_set_AnimPower()
	if power > 0:
		$AnimationPlayer.play(get_parent().id_Player + animPower)


func _on_AnimationPlayer_animation_finished(n: StringName) -> void:
	if n == get_parent().id_Player + animPower + "_Hit":
		self.power = -1
