extends Control

@onready var status: Label = $Margin/VBox/Status
@onready var pending_list: ItemList = $Margin/VBox/Pending


func _ready() -> void:
	$Margin/VBox/Buttons/WriteMinidump.pressed.connect(_on_write_minidump)
	$Margin/VBox/Buttons/OpenSidecar.pressed.connect(_on_open_sidecar)
	$Margin/VBox/Buttons/CrashNow.pressed.connect(_on_crash_now)
	$Margin/VBox/Buttons/Refresh.pressed.connect(_refresh)
	_refresh()
	if OS.get_cmdline_args().has("--write-minidump-and-quit") or OS.get_cmdline_user_args().has("--write-minidump-and-quit"):
		_on_write_minidump()
		var cr := _crash_reporter()
		if cr:
			print("DUMP_PATH=%s" % cr.get_last_dump_path())
		get_tree().quit()


func _crash_reporter() -> Object:
	if Engine.has_singleton("CrashReporter"):
		return Engine.get_singleton("CrashReporter")
	return null


func _refresh() -> void:
	var cr := _crash_reporter()
	if cr == null:
		status.text = "CrashReporter singleton is missing."
		return
	var pending: Array = cr.get_pending_reports()
	pending_list.clear()
	for row in pending:
		if typeof(row) == TYPE_DICTIONARY:
			pending_list.add_item("%s (%s)" % [String(row.get("id", "")), String(row.get("state", "pending"))])
	if pending_list.item_count > 0 and pending_list.get_selected_items().is_empty():
		pending_list.select(0)
	status.text = "Breakpad: %s\nCrash dir: %s\nPending: %d\nLast dump: %s" % [
		str(cr.is_breakpad_enabled()),
		cr.get_crash_directory(),
		pending.size(),
		cr.get_last_dump_path(),
	]


func _on_write_minidump() -> void:
	var cr := _crash_reporter()
	if cr == null:
		status.text = "CrashReporter singleton is missing."
		return
	push_error("e2e gdscript error: write_minidump test")
	var path: String = cr.write_minidump()
	if path.is_empty():
		status.text = "write_minidump() returned empty (Breakpad off?)."
		return
	_refresh()
	status.text += "\nWrote %s" % path


func _selected_report_id() -> String:
	var cr := _crash_reporter()
	if cr == null:
		return ""
	var pending: Array = cr.get_pending_reports()
	var selected := pending_list.get_selected_items()
	if not selected.is_empty() and selected[0] < pending.size() and typeof(pending[selected[0]]) == TYPE_DICTIONARY:
		return String(pending[selected[0]].get("id", ""))
	if not pending.is_empty() and typeof(pending[0]) == TYPE_DICTIONARY:
		return String(pending[0].get("id", ""))
	var last: String = cr.get_last_dump_path()
	if not last.is_empty():
		return last.get_file().get_basename()
	return ""


func _resolve_reporter_path() -> String:
	var rel := String(ProjectSettings.get_setting("application/crash_reporter/reporter_path", "bin/crash_reporter.exe"))
	if rel.is_empty():
		rel = "bin/crash_reporter.exe"
	if rel.is_absolute_path() and FileAccess.file_exists(rel):
		return rel
	var candidates: PackedStringArray = PackedStringArray([
		OS.get_executable_path().get_base_dir().path_join(rel),
		ProjectSettings.globalize_path("res://").path_join(rel),
		OS.get_executable_path().get_base_dir().path_join("crash_reporter.exe"),
	])
	for path in candidates:
		if FileAccess.file_exists(path):
			return path
	return candidates[0]


func _on_open_sidecar() -> void:
	var cr := _crash_reporter()
	if cr == null:
		status.text = "CrashReporter singleton is missing."
		return
	var reporter := _resolve_reporter_path()
	if not FileAccess.file_exists(reporter):
		status.text = "Sidecar not found: %s" % reporter
		return
	var report_id := _selected_report_id()
	var endpoint := String(ProjectSettings.get_setting("application/crash_reporter/endpoint", ""))
	var app_id := String(ProjectSettings.get_setting("application/crash_reporter/app_id", ""))
	if app_id.is_empty():
		app_id = String(cr.get_app_id())
	var args := PackedStringArray([
		"--crash-dir", cr.get_crash_directory(),
		"--report-id", report_id,
	])
	if not endpoint.is_empty():
		args.append_array(PackedStringArray(["--endpoint", endpoint]))
	if not app_id.is_empty():
		args.append_array(PackedStringArray(["--app-id", app_id]))
	var pid := OS.create_process(reporter, args)
	if pid < 0:
		status.text = "Failed to spawn sidecar: %s" % reporter
		return
	status.text = "Spawned sidecar pid %d\n%s" % [pid, reporter]


func _on_crash_now() -> void:
	var cr := _crash_reporter()
	if cr == null:
		status.text = "CrashReporter singleton is missing."
		return
	cr.induce_crash()
