extends SceneTree

const CONFIG: ProgressionConfig = preload("res://data/progression/progression_config.tres")

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func run() -> void:
	check(CONFIG.validation_errors().is_empty(), "authored progression configuration must validate")
	var progression := RunProgression.new(CONFIG)
	check(progression.snapshot() == {"level": 1, "xp": 0, "next_threshold": 10, "pending_count": 0}, "fresh runs must begin at level one without XP or choices")
	check(progression.take_selection_level() == 0, "an empty selection queue must have no level")
	check(progression.add_xp(0).is_empty() and progression.add_xp(-9).is_empty(), "nonpositive intake must not change progression")
	check(progression.add_xp(9).is_empty() and progression.xp == 9, "XP below a threshold must remain available")
	check(progression.add_xp(1) == [2], "exact threshold must earn level two")
	check(progression.xp == 0 and progression.next_threshold() == 13, "threshold consumption must advance the rounded cost")
	check(progression.take_selection_level() == 2 and progression.pending_count() == 0, "earned choices must be removable independently from XP")
	progression.reset()
	var earned := progression.add_xp(100)
	check(earned == [2, 3, 4, 5, 6], "one grant must queue every crossed level in order")
	check(progression.level == 6 and progression.xp == 13 and progression.next_threshold() == 34, "multi-level intake must retain the exact excess")
	earned.clear()
	var view := progression.snapshot()
	view.level = 99
	check(progression.level == 6 and progression.pending_count() == 5, "returned snapshots and earned arrays must not mutate the model")
	for level in range(2, 7):
		check(progression.take_selection_level() == level, "selection levels must remain FIFO")
	check(progression.take_selection_level() == 0, "drained queues must remain empty")
	progression.add_xp(100)
	progression.reset()
	check(progression.level == 1 and progression.xp == 0 and progression.pending_count() == 0, "reset must clear excess XP and queued selections")
	var split := RunProgression.new(CONFIG)
	var combined := RunProgression.new(CONFIG)
	var random := RandomNumberGenerator.new()
	random.seed = 3102
	var total := 0
	for index in 400:
		var amount := random.randi_range(1, 25)
		total += amount
		split.add_xp(amount)
	combined.add_xp(total)
	check(split.snapshot() == combined.snapshot(), "partitioning XP grants must not change final progression")
	while split.pending_count() > 0:
		check(split.take_selection_level() == combined.take_selection_level(), "partitioning must preserve the same choice queue")
	for level in range(1, 61):
		check(CONFIG.threshold_for_level(level) == roundi(10 * pow(1.28, level - 1)), "thresholds must use the exact rounded contract formula")
	var invalid := CONFIG.duplicate() as ProgressionConfig
	invalid.xp_growth = NAN
	check(not invalid.validation_errors().is_empty(), "nonfinite XP growth must be rejected")
	var rejected := RunProgression.new(invalid)
	check(rejected.add_xp(100).is_empty() and rejected.xp == 0, "invalid configuration must not consume intake or loop")
	invalid = CONFIG.duplicate() as ProgressionConfig
	invalid.xp_base = 0
	invalid.utility_slots = 0
	invalid.manual_delay_min = 0.3
	check(invalid.validation_errors().size() == 3, "invalid thresholds, capacities and limits must be diagnosed")
	print("Run progression: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
