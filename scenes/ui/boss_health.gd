extends VBoxContainer

func _ready() -> void:
	hide()
	Events.boss_started.connect(_on_started)
	Events.boss_phase_thresholds_changed.connect($Bar/Segments.set_thresholds)
	Events.boss_health_changed.connect(_on_health)
	Events.boss_defeated.connect(func(_id): hide())
	Events.game_over_requested.connect(hide)

func _on_started(_id: StringName, title: String, maximum: float) -> void:
	$Header/Title.text = title.to_upper()
	$Bar.max_value = maximum
	$Bar.value = maximum
	show()

func _on_health(health: float, maximum: float, _phase: int) -> void:
	$Bar.max_value = maximum
	$Bar.value = clampf(health, 0.0, maximum)
	if health <= 0.0:
		hide()
