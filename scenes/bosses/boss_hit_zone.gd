extends Area2D

signal hit()
signal critical_hit()
signal broken()

const Layers := preload("res://core/collision_layers.gd")
const EXPLOSION := preload("res://assets/sprites/effects/dread_ark_explosion_sheet.png")

@export var armored := false

var hitByPlayerShot := false
var last_player_hit_owner: StringName = &""
var destroyed := false
var life := 0.0
var max_life := 0.0
var _explosion_time := 0.0

func _ready() -> void:
	add_to_group("boss_hit_zone")
	collision_layer = Layers.ENEMY
	collision_mask = Layers.PLAYER
	area_entered.connect(get_parent()._on_area_entered)

func configure(health: float) -> void:
	life = health
	max_life = health

func get_combat_identity() -> StringName:
	return StringName("%s/%s" % [get_parent().get_combat_identity(), name])

func player_damage_group() -> Node:
	return get_parent()

func can_receive_player_hit() -> bool:
	return not armored and not destroyed and life > 0.0 and is_inside_tree() and get_parent().can_damage_parts()

func receive_player_hit(amount: float, owner_id: StringName = &"", feedback := true) -> bool:
	if not is_finite(amount) or amount <= 0.0 or not can_receive_player_hit():
		return false
	var before := life
	hitByPlayerShot = true
	last_player_hit_owner = owner_id
	_hit_something(amount, feedback)
	return life < before

func play_critical_feedback() -> void:
	if not destroyed and not armored:
		critical_hit.emit()

func _hit_something(damage: float = 0.0, _feedback := true) -> void:
	if armored or destroyed or damage <= 0.0 or not get_parent().can_damage_parts():
		return
	life = maxf(life - damage, 0.0)
	hit.emit()
	if life <= 0.0:
		destroyed = true
		disable_collision()
		broken.emit()
	queue_redraw()

func disable_collision() -> void:
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	for shape in get_children():
		if shape is CollisionShape2D or shape is CollisionPolygon2D:
			shape.set_deferred("disabled", true)

func _process(delta: float) -> void:
	if destroyed and _explosion_time < 0.56:
		_explosion_time += delta
		queue_redraw()

func _draw() -> void:
	if armored:
		return
	if destroyed:
		if _explosion_time < 0.56:
			var size := Vector2(EXPLOSION.get_width() / 14.0, EXPLOSION.get_height())
			var frame := mini(int(_explosion_time / 0.04), 13)
			draw_texture_rect_region(EXPLOSION, Rect2(-20, -15, 40, 30), Rect2(Vector2(frame * size.x, 0), size))
		return
	if life >= max_life or max_life <= 0.0:
		return
	draw_rect(Rect2(-10, -20, 20, 2), Color(0.04, 0.04, 0.06, 0.85))
	draw_rect(Rect2(-10, -20, 20 * life / max_life, 2), Color("ef7656"))
