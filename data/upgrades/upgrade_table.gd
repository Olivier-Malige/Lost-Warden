class_name UpgradeTable
extends Resource

@export var upgrades: Array[UpgradeDefinition] = []

func pick(rng: RandomNumberGenerator = null) -> UpgradeDefinition:
	if upgrades.is_empty():
		return null
	var total_weight := 0
	for upgrade in upgrades:
		total_weight += maxi(upgrade.weight, 0)
	if total_weight <= 0:
		return upgrades.front()
	var roll := rng.randi_range(1, total_weight) if rng else randi_range(1, total_weight)
	for upgrade in upgrades:
		roll -= maxi(upgrade.weight, 0)
		if roll <= 0:
			return upgrade
	return upgrades.back()

func foundation_errors(config: ProgressionConfig) -> PackedStringArray:
	var errors := config.validation_errors() if config != null else PackedStringArray(["Missing progression configuration."])
	var ids: Dictionary = {}
	var effects: Dictionary = {}
	var fallback_count := 0
	for upgrade in upgrades:
		if upgrade == null:
			errors.append("Null foundation upgrade.")
			continue
		errors.append_array(upgrade.foundation_errors())
		if ids.has(upgrade.id):
			errors.append("Duplicate foundation ID: %s" % upgrade.id)
		ids[upgrade.id] = true
		if effects.has(upgrade.effect):
			errors.append("Duplicate foundation effect: %s" % upgrade.effect)
		effects[upgrade.effect] = true
		if upgrade.category == UpgradeDefinition.Category.FALLBACK:
			fallback_count += 1
		elif config != null:
			var expected := config.family_weight if upgrade.is_family() else config.reward_weight
			if upgrade.weight != expected:
				errors.append("Foundation offer weight differs from configuration: %s" % upgrade.id)
	if fallback_count != 1:
		errors.append("Foundation catalogs require exactly one automatic score fallback.")
	return errors

func generate_offers(build: Dictionary, vitals: Dictionary, rng: RandomNumberGenerator, config: ProgressionConfig, _first_selection := false) -> Dictionary:
	var offers: Array[Dictionary] = []
	var errors := foundation_errors(config)
	if rng == null:
		errors.append("Foundation offers require the run's explicit offer RNG.")
	if not errors.is_empty():
		return {"offers": offers, "fallback_score": 0, "errors": errors}
	var candidates: Array[UpgradeDefinition] = []
	var acquired: Array[UpgradeDefinition] = []
	var new_families: Array[UpgradeDefinition] = []
	var offensive: Array[UpgradeDefinition] = []
	var utility: Array[UpgradeDefinition] = []
	var ranks: Dictionary = build.get("ranks", {})
	var fallback_score := 0
	for upgrade in upgrades:
		if upgrade.category == UpgradeDefinition.Category.FALLBACK:
			fallback_score = int(upgrade.rank_value(1))
			continue
		if not upgrade.is_eligible(build, vitals, config):
			continue
		candidates.append(upgrade)
		if upgrade.is_family():
			if int(ranks.get(upgrade.id, 0)) > 0:
				acquired.append(upgrade)
			else:
				new_families.append(upgrade)
			if upgrade.category == UpgradeDefinition.Category.OFFENSIVE:
				offensive.append(upgrade)
			else:
				utility.append(upgrade)
	if candidates.is_empty():
		return {"offers": offers, "fallback_score": fallback_score}
	var selected: Array[UpgradeDefinition] = []
	if not offensive.is_empty() and not utility.is_empty():
		_reserve_offer(offensive, selected, rng)
		_reserve_offer(utility, selected, rng)
	if not acquired.is_empty() and not new_families.is_empty():
		_reserve_offer(acquired, selected, rng)
		_reserve_offer(new_families, selected, rng)
	while selected.size() < mini(3, candidates.size()):
		_reserve_offer(candidates, selected, rng, false)
	for upgrade in selected:
		offers.append(upgrade.offer_snapshot(int(ranks.get(upgrade.id, 0))))
	return {"offers": offers, "fallback_score": 0}

# Snapshot both participants before generating either hand; callers cannot reorder the stream.
func generate_player_offers(participants: Dictionary, rng: RandomNumberGenerator, config: ProgressionConfig, first_selection := false) -> Dictionary:
	var snapshots := participants.duplicate(true)
	var result := {}
	for player_id in [&"player1", &"player2"]:
		if snapshots.has(player_id):
			var participant: Dictionary = snapshots[player_id]
			result[player_id] = generate_offers(participant["build"], participant["vitals"], rng, config, first_selection)
	return result

func _reserve_offer(group: Array[UpgradeDefinition], selected: Array[UpgradeDefinition], rng: RandomNumberGenerator, only_if_missing := true) -> void:
	if selected.size() >= 3:
		return
	var available: Array[UpgradeDefinition] = []
	var total := 0
	for upgrade in group:
		if selected.has(upgrade):
			if only_if_missing:
				return
		else:
			available.append(upgrade)
			total += upgrade.weight
	if available.is_empty():
		return
	var roll := rng.randi_range(1, total)
	for upgrade in available:
		roll -= upgrade.weight
		if roll <= 0:
			selected.append(upgrade)
			return
