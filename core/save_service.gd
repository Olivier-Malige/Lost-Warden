class_name SaveService
extends RefCounted

const PATH := "user://data.json"
const TEMP_PATH := "user://data.json.tmp"
const SCHEMA_KEY := "_schema_version"
const SCHEMA_VERSION := 1

static func load_data(default_data: Dictionary) -> Dictionary:
	var defaults := default_data.duplicate(true)
	defaults[SCHEMA_KEY] = SCHEMA_VERSION
	if not FileAccess.file_exists(PATH):
		save_data(defaults)
		return defaults
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		push_warning("Save data could not be opened; defaults will be used.")
		return defaults
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		return _merge(defaults, parsed)
	push_warning("Save data is invalid; defaults will be used.")
	return defaults

static func save_data(data: Dictionary) -> void:
	var output := data.duplicate(true)
	output[SCHEMA_KEY] = SCHEMA_VERSION
	var f := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if f == null:
		push_error("Save data temporary file could not be opened.")
		return
	f.store_line(JSON.stringify(output))
	f.flush()
	f.close()
	var rename_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(TEMP_PATH),
		ProjectSettings.globalize_path(PATH)
	)
	if rename_error != OK:
		push_error("Save data could not replace the previous file (error %d)." % rename_error)

static func _merge(base: Dictionary, overlay: Dictionary) -> Dictionary:
	var out := base.duplicate(true)
	for key in base:
		if not overlay.has(key):
			continue
		if base[key] is Dictionary and overlay[key] is Dictionary:
			out[key] = _merge(out[key], overlay[key])
		elif base[key] is int and (overlay[key] is int or overlay[key] is float):
			out[key] = int(overlay[key])
		elif base[key] is float and (overlay[key] is int or overlay[key] is float):
			out[key] = float(overlay[key])
		elif typeof(base[key]) == typeof(overlay[key]):
			out[key] = overlay[key]
	return out
