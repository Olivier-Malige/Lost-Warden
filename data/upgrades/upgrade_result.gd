class_name UpgradeResult
extends RefCounted

var applied: bool
var rank: int
var max_rank: int
var capped: bool

func _init(p_applied: bool, p_rank: int, p_max_rank: int, p_capped: bool) -> void:
	applied = p_applied
	rank = p_rank
	max_rank = p_max_rank
	capped = p_capped
