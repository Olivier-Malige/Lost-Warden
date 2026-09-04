extends Control


func _ready() -> void:
	if $music.stream:
		$music.stream.loop = true
	$TitleArea/Content/Version.text = String(ProjectSettings.get_setting("application/config/release_label", "dev")).to_upper()

	var m = load("res://scenes/menu/menu.tscn").instantiate()
	add_child(m)
	m.set_mode(m.MENU_START)
	_animate_title()


func _animate_title() -> void:
	var title := $TitleArea/Content/LostWarden
	var tagline := $TitleArea/Content/Tagline
	var line := $TitleArea/Content/TitleLine
	title.modulate.a = 0.0
	title.scale = Vector2(0.86, 0.86)
	tagline.modulate.a = 0.0
	line.scale.x = 0.0
	await get_tree().process_frame
	title.pivot_offset = title.size * 0.5
	line.pivot_offset = line.size * 0.5

	var entrance := create_tween().set_parallel(true)
	entrance.tween_property(title, "modulate:a", 1.0, 0.35)
	entrance.tween_property(title, "scale", Vector2.ONE, 0.65).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	entrance.tween_property(line, "scale:x", 1.0, 0.5).set_delay(0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	entrance.tween_property(tagline, "modulate:a", 1.0, 0.4).set_delay(0.45)
	await entrance.finished

	var pulse := create_tween().set_loops()
	pulse.tween_property(title, "scale", Vector2(1.015, 1.015), 1.2).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(title, "scale", Vector2.ONE, 1.2).set_trans(Tween.TRANS_SINE)
