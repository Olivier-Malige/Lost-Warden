class_name PlayerHitSnapshot
extends RefCounted

enum Kind { GUN, PLASMA, REFLECTED, SECONDARY, MISSILE, DRONE }

var _values: Dictionary

func _init(owner: StringName, sequence: int, base_damage: float, pre_critical: float, modifiers: Dictionary = {}, hit_kind: Kind = Kind.GUN, critical := false, generation := 0) -> void:
	_values = {"owner": owner, "sequence": sequence, "base": base_damage,
		"pre_critical": pre_critical, "modifiers": modifiers.duplicate(true),
		"kind": hit_kind, "critical": critical, "generation": generation}

func owner_id() -> StringName:
	return _values.owner

func source_sequence() -> int:
	return _values.sequence

func root_id() -> StringName:
	return StringName("%s/%d/%d" % [_values.owner, _values.generation, _values.sequence])

func authored_base() -> float:
	return _values.base

func pre_critical_damage() -> float:
	return _values.pre_critical

func damage() -> float:
	return _values.pre_critical * (2.0 if _values.critical else 1.0)

func kind() -> Kind:
	return _values.kind

func is_direct() -> bool:
	return kind() in [Kind.GUN, Kind.MISSILE, Kind.DRONE]

func is_critical() -> bool:
	return _values.critical

func modifier_rank(id: StringName) -> int:
	return int(_values.modifiers.get(id, 0))

func snapshot() -> Dictionary:
	return _values.duplicate(true)

func copy() -> PlayerHitSnapshot:
	return PlayerHitSnapshot.new(_values.owner, _values.sequence, _values.base,
		_values.pre_critical, _values.modifiers, _values.kind, _values.critical, _values.generation)

# Each contact derives its decay without changing the emission's critical result or root.
func scaled_direct(multiplier: float) -> PlayerHitSnapshot:
	return PlayerHitSnapshot.new(_values.owner, _values.sequence, _values.base,
		_values.pre_critical * multiplier, _values.modifiers, _values.kind, _values.critical, _values.generation)

func secondary_hit(amount: float) -> PlayerHitSnapshot:
	return PlayerHitSnapshot.new(_values.owner, _values.sequence, _values.base,
		amount, {}, Kind.SECONDARY, false, _values.generation)
