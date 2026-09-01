class_name WeaponDefinition
extends Resource

enum Kind { PRIMARY, SIDE }

@export var id: StringName
@export var kind: Kind = Kind.PRIMARY
@export var projectile: PackedScene
@export var damage: float = 1.0
@export var fire_delay: float = 0.18
