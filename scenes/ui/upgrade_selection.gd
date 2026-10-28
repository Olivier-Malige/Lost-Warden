class_name UpgradeSelection
extends CanvasLayer

signal closed()

const FONT := preload("res://assets/fonts/slkscr.ttf")
const MENU_ICONS := preload("res://assets/sprites/ui/upgrade_icons_64.png")
const MINI_ICONS := preload("res://assets/sprites/ui/upgrade_miniatures.png")
const PLAYER_STATS := preload("res://data/player/player_stats.tres")
const PROGRESSION: ProgressionConfig = preload("res://data/progression/progression_config.tres")
const MENU_ICON_IDS: Array[StringName] = [
	&"speed", &"damage", &"fire_rate", &"orb_magnet", &"side_shot", &"energy", &"shield", &"score",
	&"beam_capacity", &"beam_recharge",
	&"beam_piercing", &"critical_hits",
	&"energy_chains",
	&"micro_missiles",
	&"escort_drone",
	&"orbiting_satellites",
	&"impact_explosions",
	&"reactive_armor", &"retaliation_pulse",
	&"guard_blades",
]
const INK := Color("101522")
const WHITE := Color("f3ebdd")
const GOLD := Color("ffd35a")
const TEAM := [Color("ff5a4d"), Color("7ad9ff")]
const ICON_IDS: Array[StringName] = [
	&"speed", &"damage", &"fire_rate", &"orb_magnet", &"side_shot", &"energy", &"shield", &"score",
	&"piercing", &"critical_hits", &"micro_missiles", &"escort_drone", &"orbiting_satellites",
	&"impact_explosions", &"energy_chains", &"ricochet",
	&"beam_capacity", &"beam_recharge",
	&"beam_piercing",
	&"reactive_armor", &"retaliation_pulse",
	&"guard_blades",
]

var selection_id := 0
var participants := {}
var cursors := {}
var ready_players := {}
var opening_count := 0
var audio: UpgradeSelectionAudio
var suspended := false
var _root: Control
var _dim: ColorRect
var _flash: ColorRect
var _panels: Dictionary = {}
var _blocked: Dictionary = {}
var _pending := {}
var _bindings := {}
var _armed_at := 0
var _closing := false
var _tweens: Array[Tween] = []
var _title: Label
var _progress: Label
var _art: Texture2D

func _ready() -> void:
	_dim = ColorRect.new()
	_dim.name = "Dim"
	_dim.color = Color(0, 0, 0, 0)
	add_child(_dim)
	_root = Control.new()
	_root.name = "Core"
	_root.size = Vector2(640, 400)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_title = _label(_root, "LEVEL UP", Rect2(16, 10, 608, 22), 18, GOLD)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress = _label(_root, "", Rect2(16, 36, 608, 16), 10)
	_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_flash = ColorRect.new()
	_flash.name = "OpeningPulse"
	_flash.color = Color(GOLD, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)
	audio = UpgradeSelectionAudio.new()
	audio.name = "SelectionAudio"
	add_child(audio)
	if ResourceLoader.exists("res://assets/sprites/ui/phase_3_upgrade_ui.png"):
		_art = load("res://assets/sprites/ui/phase_3_upgrade_ui.png")
	Events.upgrade_choice_applied.connect(mark_ready)
	get_viewport().size_changed.connect(_layout)
	_layout()

func _layout() -> void:
	_root.position = Vector2(floorf((get_viewport().get_visible_rect().size.x - 640) * 0.5), 0)
	_dim.size = get_viewport().get_visible_rect().size
	_flash.size = _dim.size

func open(id: int, snapshots: Dictionary, progression: Dictionary, gameplay_music: AudioStreamPlayer = null) -> void:
	_kill_tweens()
	_closing = false
	selection_id = id
	participants = snapshots.duplicate(true)
	cursors.clear()
	ready_players.clear()
	_pending.clear()
	_blocked.clear()
	refresh_bindings()
	for player_id in participants:
		cursors[player_id] = 0
		ready_players[player_id] = false
		_pending[player_id] = false
	_progress.text = "LEVEL %d  /  XP %d / %d" % [progression.get("selection_level", progression.level), progression.xp, progression.next_threshold]
	if progression.get("selection_level", progression.level) != progression.level:
		_progress.text = "LEVEL %d CHOICE / RUN LEVEL %d / %d QUEUED" % [progression.selection_level, progression.level, progression.get("pending_count", 0)]
	var initial := opening_count == 0
	_armed_at = Time.get_ticks_msec() + (300 if initial else 120)
	var old_panels := _panels.values()
	_panels.clear()
	for index in 2:
		var player_id := StringName("player%d" % (index + 1))
		if participants.has(player_id):
			_build_panel(player_id, index, participants.size() == 1)
	if initial:
		opening_count += 1
		audio.begin(gameplay_music)
		_dim.color.a = 0
		_flash.color.a = 0.18
		var effect := _tween().set_parallel(true)
		effect.tween_property(_dim, "color:a", 0.65, 0.14)
		effect.tween_property(_flash, "color:a", 0.0, 0.18)
		for panel in _panels.values():
			panel.scale = Vector2(0.96, 0.96)
			panel.modulate.a = 0
			effect.tween_property(panel, "scale", Vector2.ONE, 0.18)
			effect.tween_property(panel, "modulate:a", 1.0, 0.18)
			var cards: Array = panel.get_meta("cards")
			for card_index in cards.size():
				cards[card_index].modulate.a = 0
				effect.tween_property(cards[card_index], "modulate:a", 1.0, 0.18).set_delay(card_index * 0.04)
	else:
		var transition := _tween().set_parallel(true)
		for panel in old_panels:
			transition.tween_property(panel, "modulate:a", 0.0, 0.12)
		for panel in _panels.values():
			panel.modulate.a = 0
			transition.tween_property(panel, "modulate:a", 1.0, 0.12)
		transition.finished.connect(func():
			for panel in old_panels:
				if is_instance_valid(panel): panel.queue_free()
		)

func refresh_bindings() -> void:
	for player_id in participants:
		_bindings[player_id] = String(global.saveData.config.player1 if player_id == &"player1" else global.saveData.config.player2) if global.coop else "all"
		_blocked[player_id] = []
		for suffix in ["upgrade_confirm", "up", "down", "left", "right"]:
			var action := StringName(_bindings[player_id] + "_" + suffix)
			if Input.is_action_pressed(action):
				_blocked[player_id].append(action)
		if _panels.has(player_id):
			var hint := _panels[player_id].get_node_or_null("ControlsHint") as Label
			if hint: hint.text = _controls_hint(player_id)

func _controls_hint(player_id: StringName) -> String:
	if _bindings[player_id] == "all": return "ARROWS / ENTER\nD-PAD / START"
	return "D-PAD / START" if _bindings[player_id].begins_with("gamepad") else "ARROWS / ENTER"

# An unassigned controller must not turn a confirmation press into a nested pause menu.
func is_confirmation_event(event: InputEvent) -> bool:
	for prefix in ["all", "keyboard", "gamepad1", "gamepad2"]:
		if event.is_action_pressed(prefix + "_upgrade_confirm"):
			return true
	return false

func set_suspended(value: bool, menu_open := false) -> void:
	suspended = value
	visible = not menu_open

func handle_input(event: InputEvent) -> void:
	if suspended or _closing or event.is_echo():
		return
	for player_id in participants:
		for action in _blocked[player_id].duplicate():
			if event.is_action_released(action):
				_blocked[player_id].erase(action)
		if not _can_interact(player_id):
			continue
		var prefix: String = _bindings[player_id]
		if event.is_action_pressed(prefix + "_up") or event.is_action_pressed(prefix + "_left"):
			select_card(player_id, posmod(int(cursors[player_id]) - 1, participants[player_id].offers.size()))
		elif event.is_action_pressed(prefix + "_down") or event.is_action_pressed(prefix + "_right"):
			select_card(player_id, posmod(int(cursors[player_id]) + 1, participants[player_id].offers.size()))
		elif event.is_action_pressed(prefix + "_upgrade_confirm"):
			confirm_choice(selection_id, player_id, participants[player_id].offers[cursors[player_id]].id)

func _can_interact(player_id: StringName) -> bool:
	return participants.has(player_id) and not suspended and not _closing and not ready_players.get(player_id, false) and not _pending.get(player_id, false) and Time.get_ticks_msec() >= _armed_at and _blocked.get(player_id, []).is_empty() and not participants[player_id].offers.is_empty()

func select_card(player_id: StringName, index: int) -> void:
	if not _can_interact(player_id) or index < 0 or index >= participants[player_id].offers.size():
		return
	cursors[player_id] = index
	_refresh_panel(player_id)
	audio.navigate()

func confirm_choice(id: int, player_id: StringName, upgrade_id: StringName) -> bool:
	if id != selection_id or not _can_interact(player_id):
		return false
	var found := false
	for offer in participants[player_id].offers:
		found = found or offer.id == upgrade_id
	if not found:
		return false
	_pending[player_id] = true
	Events.upgrade_choice_requested.emit(id, player_id, upgrade_id)
	return true

func mark_ready(id: int, player_id: StringName) -> void:
	if id != selection_id or not participants.has(player_id) or ready_players[player_id]:
		return
	ready_players[player_id] = true
	audio.confirm()
	_refresh_panel(player_id)

func close() -> void:
	if _closing:
		return
	_closing = true
	_kill_tweens()
	audio.finish()
	var effect := _tween().set_parallel(true)
	effect.tween_property(_root, "modulate:a", 0.0, 0.15)
	effect.tween_property(_dim, "color:a", 0.0, 0.15)
	effect.finished.connect(func(): closed.emit())

func cancel() -> void:
	_closing = true
	_kill_tweens()
	audio.finish(false)

func _build_panel(player_id: StringName, team: int, solo: bool) -> void:
	var panel_selection_id := selection_id
	var panel := Panel.new()
	panel.name = "Player%dPanel" % (team + 1)
	panel.position = Vector2(16 if solo else 16 + team * 310, 60)
	panel.size = Vector2(608 if solo else 298, 328)
	panel.pivot_offset = panel.size * 0.5
	panel.add_theme_stylebox_override("panel", _style(team, 0))
	_root.add_child(panel)
	_panels[player_id] = panel
	_label(panel, "PLAYER %d" % (team + 1), Rect2(12, 8, 180, 16), 12, TEAM[team])
	_label(panel, "NOMAD", Rect2(panel.size.x - 58, 10, 50, 12), 10)
	var build: Dictionary = participants[player_id].get("build", {})
	var family_ranks: Dictionary = build.get("ranks", {})
	var slot_index := 0
	for category in [UpgradeDefinition.Category.OFFENSIVE, UpgradeDefinition.Category.UTILITY]:
		var capacity: int = build.get("offensive_capacity", PROGRESSION.offensive_slots) if category == UpgradeDefinition.Category.OFFENSIVE else build.get("utility_capacity", PROGRESSION.utility_slots)
		var equipped := []
		for family in build.get("families", []):
			if family.category == category:
				equipped.append(family.id)
		for cell in capacity:
			var x := 12 + slot_index * 20 + (6 if category == UpgradeDefinition.Category.UTILITY else 0)
			var slot := Panel.new()
			slot.name = "BuildSlot%d" % slot_index
			slot.position = Vector2(x, 30)
			slot.size = Vector2(18, 22)
			slot.add_theme_stylebox_override("panel", _style(team, 0))
			panel.add_child(slot)
			if cell < equipped.size():
				_icon(slot, equipped[cell], Rect2(1, 0, 16, 16), false, team)
				_label(slot, str(family_ranks[equipped[cell]]), Rect2(6, 12, 12, 10), 8, GOLD)
			slot_index += 1
	_label(panel, "OFF", Rect2(12, 54, 78, 10), 8)
	_label(panel, "UTIL", Rect2(18 + int(build.get("offensive_capacity", PROGRESSION.offensive_slots)) * 20, 54, 66, 10), 8)
	var cards: Array[Button] = []
	var offers: Array = participants[player_id].offers
	for index in offers.size():
		var offer: Dictionary = offers[index]
		var card := Button.new()
		card.name = "Card%d" % (index + 1)
		card.focus_mode = Control.FOCUS_NONE
		card.position = Vector2(12 + index * 196, 70) if solo else Vector2(12, 70 + index * 74)
		card.size = Vector2(188, 196) if solo else Vector2(274, 66)
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		panel.add_child(card)
		card.pressed.connect(func():
			if selection_id == panel_selection_id: select_card(player_id, index)
		)
		_icon(card, offer.id, Rect2(62, 12, 64, 64) if solo else Rect2(6, 1, 64, 64), true, team)
		var title_width := 170 if solo else 132
		var title_size := 10 if FONT.get_string_size(offer.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x > title_width else 12
		_label(card, offer.display_name, Rect2(12 if solo else 76, 88 if solo else 5, title_width, 18), title_size)
		var rank_text := "NEW" if offer.current_rank == 0 else "%d > %d" % [offer.current_rank, offer.next_rank]
		if offer.repeatable: rank_text = ""
		var category_color: Color = GOLD if offer.category == UpgradeDefinition.Category.OFFENSIVE else TEAM[team] if offer.category == UpgradeDefinition.Category.UTILITY else WHITE
		var category := _label(card, _category_text(offer.category), Rect2(12 if solo else 76, 110 if solo else 51, 166 if solo else 188, 12), 8, category_color)
		category.name = "Category"
		category.size = Vector2(166 if solo else 188, 12)
		_label(card, rank_text, Rect2(12 if solo else 212, 126 if solo else 6, 170 if solo else 60, 14), 10, GOLD)
		_label(card, _effect_lines(offer), Rect2(12 if solo else 76, 149 if solo else 26, 166 if solo else 188, 38), 10)
		cards.append(card)
	panel.set_meta("cards", cards)
	var confirm := Button.new()
	confirm.name = "Confirm"
	confirm.text = "CONFIRM"
	confirm.position = Vector2(panel.size.x - 96, 290)
	confirm.size = Vector2(84, 26)
	confirm.focus_mode = Control.FOCUS_NONE
	confirm.add_theme_font_override("font", FONT)
	confirm.add_theme_font_size_override("font_size", 10)
	confirm.add_theme_stylebox_override("normal", _style(team, 1))
	panel.add_child(confirm)
	confirm.pressed.connect(func():
		if not offers.is_empty(): confirm_choice(panel_selection_id, player_id, offers[cursors[player_id]].id)
	)
	var hint := _label(panel, _controls_hint(player_id), Rect2(12, 282, panel.size.x - 112, 36), 10)
	hint.name = "ControlsHint"
	_refresh_panel(player_id)

func _refresh_panel(player_id: StringName) -> void:
	var team := 0 if player_id == &"player1" else 1
	var panel: Panel = _panels[player_id]
	var cards: Array = panel.get_meta("cards")
	for index in cards.size():
		var selected: bool = cursors[player_id] == index
		var style := _style(team, (2 if ready_players[player_id] else 1) if selected else 0)
		for state in ["normal", "hover", "pressed", "disabled"]:
			cards[index].add_theme_stylebox_override(state, style)
		cards[index].disabled = ready_players[player_id]
	panel.get_node("Confirm").text = "READY" if ready_players[player_id] else "CONFIRM"
	panel.get_node("Confirm").disabled = ready_players[player_id]

func _category_text(category: UpgradeDefinition.Category) -> String:
	match category:
		UpgradeDefinition.Category.OFFENSIVE: return "OFFENSIVE"
		UpgradeDefinition.Category.UTILITY: return "UTILITY"
		UpgradeDefinition.Category.REWARD: return "RECOVERY"
	return "BONUS"

func _effect_lines(offer: Dictionary) -> String:
	match offer.id:
		&"speed": return "+15 MOVEMENT SPEED\n%d PX/S" % (180 + offer.next_value)
		&"damage": return "+25%% DIRECT DAMAGE\nx%.2f DAMAGE" % (1.0 + offer.next_value)
		&"fire_rate": return "DELAY -0.016 SEC\n%.3f SEC / SHOT" % (0.2 - offer.next_value)
		&"orb_magnet": return "+24 PX ATTRACTION\n%d PX RADIUS" % (24 + offer.next_value)
		&"side_shot": return "PAIR DAMAGE %.2f\n%s" % [offer.next_value, "ADD OUTER PAIR" if offer.next_rank == 4 else "PAIRED SIDE CANNONS"]
		&"energy": return "RESTORE 2 ENERGY\nUP TO 12 ENERGY"
		&"shield": return "PROJECTILES ONLY / %d SHOTS\nBODY BREAKS / %.0fS RELOAD" % [roundi(offer.next_value), offer.next_recharge]
		&"reactive_armor": return "HULL HIT: REPAIR 1 HP\nAFTER %.0fS WITHOUT DAMAGE" % offer.next_interval
		&"retaliation_pulse": return "BODY CONTACT / %.1fS SAFE\n%.0f DMG / %.0fPX / %.0fS CD" % [offer.protection_duration, offer.next_value, offer.next_range, offer.next_recharge]
		&"beam_capacity": return "+25 RESERVE\n%d MAX PLASMA" % roundi(PLAYER_STATS.beam_charge_max + offer.next_value)
		&"beam_recharge": return "+25%% CELL CHARGE\nx%.2f PER CELL" % (1.0 + offer.next_value)
		&"piercing": return "%d EXTRA TARGETS\n80%% DAMAGE RETAINED" % roundi(offer.next_value)
		&"beam_piercing": return "%d EXTRA TARGETS\n+%d%% DAMAGE / +%s%% WIDTH" % [roundi(offer.next_value), roundi(offer.next_damage_bonus * 100.0), str(snappedf(offer.next_width_bonus * 100.0, 0.1)).trim_suffix(".0")]
		&"critical_hits": return "%d%% CRITICAL CHANCE\nx2 DIRECT DAMAGE" % roundi(offer.next_value * 100.0)
		&"energy_chains": return "MAIN: %d JUMPS / %d PX\n%d%% DAMAGE / %.1f SEC" % [roundi(offer.next_value), roundi(offer.next_range), roundi(offer.secondary_damage_scale * 100.0), offer.proc_cooldown]
		&"micro_missiles": return "%d MISSILES / VOLLEY\n%.1f DMG / %.2f SEC" % [offer.next_projectile_count, offer.next_value, offer.next_interval]
		&"escort_drone": return "%d FORWARD ESCORT%s\n%.2f DMG / %.2f SEC" % [offer.next_support_count, "S" if offer.next_support_count > 1 else "", offer.next_value, offer.next_interval]
		&"guard_blades": return "%d DMG / %.1f SEC\nREACH +%d%% / CLEAR SHOTS" % [roundi(offer.next_value), offer.next_interval, roundi(offer.next_range_bonus * 100)]
		&"orbiting_satellites": return "%d CONTACT SATELLITE%s\n%.2f DMG / %.2f SEC" % [offer.next_support_count, "S" if offer.next_support_count > 1 else "", offer.next_value, offer.contact_cooldown]
		&"impact_explosions":
			var radius_text := "+%d%% RADIUS" % roundi(offer.next_range_bonus * 100.0) if offer.next_range_bonus > 0.0 else "BASE BLAST"
			return "%s / AREA\n%d%% DAMAGE / %.2f SEC" % [radius_text, roundi(offer.next_value * 100.0), offer.proc_cooldown]
	return offer.description

func _icon(parent: Control, id: StringName, rect: Rect2, menu_icon := false, team := 0) -> void:
	var index := ICON_IDS.find(id)
	if _art == null or index < 0:
		return
	var texture := AtlasTexture.new()
	var menu_index := MENU_ICON_IDS.find(id)
	var cell_size := 64 if menu_icon and menu_index >= 0 else 16
	if menu_index >= 0:
		texture.atlas = MENU_ICONS if menu_icon else MINI_ICONS
		texture.region = Rect2(menu_index * cell_size, team * cell_size, cell_size, cell_size)
	else:
		texture.atlas = _art
		texture.region = Rect2((index % 8) * 16, floori(index / 8.0) * 16, 16, 16)
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.position = rect.position
	icon.size = rect.size
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(icon)

func _style(team: int, state: int) -> StyleBox:
	if _art:
		var textured_skin := StyleBoxTexture.new()
		textured_skin.texture = _art
		textured_skin.region_rect = Rect2((team * 3 + state) * 16, 32, 16, 16)
		for edge in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]: textured_skin.set_texture_margin(edge, 4)
		return textured_skin
	var skin := StyleBoxFlat.new()
	skin.bg_color = INK
	skin.border_color = GOLD if state > 0 else Color("323846")
	skin.set_border_width_all(2 if state > 0 else 1)
	return skin

func _label(parent: Control, text: String, rect: Rect2, font_size: int = 12, color: Color = WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _tween() -> Tween:
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tweens.append(tween)
	return tween

func _kill_tweens() -> void:
	for tween in _tweens:
		if tween.is_valid(): tween.kill()
	_tweens.clear()

func _exit_tree() -> void:
	_kill_tweens()
