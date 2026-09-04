class_name UpgradeTable
extends Resource

@export var upgrades: Array[UpgradeDefinition] = []

func pick() -> UpgradeDefinition:
	if upgrades.is_empty():
		return null
	var total_weight := 0
	for upgrade in upgrades:
		total_weight += maxi(upgrade.weight, 0)
	if total_weight <= 0:
		return upgrades.front()
	var roll := randi_range(1, total_weight)
	for upgrade in upgrades:
		roll -= maxi(upgrade.weight, 0)
		if roll <= 0:
			return upgrade
	return upgrades.back()
