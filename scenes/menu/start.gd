extends Control

func _ready() -> void:
	$TitleArea/TitleFrame/Margin/Content/Version.text = String(ProjectSettings.get_setting("application/config/release_label", "dev")).to_upper()

	var m = load("res://scenes/menu/menu.tscn").instantiate()
	add_child(m)
	m.set_mode(m.MENU_START)
	var menu_center: CenterContainer = m.get_node("Center")
	menu_center.offset_top = 148.0
	_animate_title()


func _animate_title() -> void:
	var frame := $TitleArea/TitleFrame
	var title := $TitleArea/TitleFrame/Margin/Content/LostWarden
	var tagline := $TitleArea/TitleFrame/Margin/Content/Tagline
	var line := $TitleArea/TitleFrame/Margin/Content/TitleLine
	frame.modulate.a = 0.0
	title.modulate.a = 0.0
	tagline.modulate.a = 0.0
	line.scale.x = 0.0
	await get_tree().process_frame
	line.pivot_offset = line.size * 0.5

	var entrance := create_tween().set_parallel(true)
	entrance.tween_property(frame, "modulate:a", 1.0, 0.25)
	entrance.tween_property(title, "modulate:a", 1.0, 0.35).set_delay(0.1)
	entrance.tween_property(line, "scale:x", 1.0, 0.5).set_delay(0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	entrance.tween_property(tagline, "modulate:a", 1.0, 0.4).set_delay(0.45)
