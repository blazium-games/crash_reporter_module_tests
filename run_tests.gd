extends SceneTree

func _initialize() -> void:
	var failed := 0
	if not Engine.has_singleton("CrashReporter"):
		push_error("CrashReporter singleton is missing.")
		quit(1)
		return
	var cr: Object = Engine.get_singleton("CrashReporter")
	if cr == null:
		push_error("CrashReporter singleton is null.")
		quit(1)
		return
	print("CrashReporter present. breakpad=%s dir=%s" % [cr.is_breakpad_enabled(), cr.get_crash_directory()])
	if cr.is_breakpad_enabled():
		var path: String = cr.write_minidump()
		if path.is_empty():
			push_error("write_minidump() returned empty with Breakpad enabled.")
			failed += 1
		elif not FileAccess.file_exists(path):
			push_error("write_minidump() path does not exist: %s" % path)
			failed += 1
		else:
			var meta := path.get_basename() + ".json"
			if not FileAccess.file_exists(meta):
				push_error("sidecar JSON missing: %s" % meta)
				failed += 1
			else:
				print("Wrote dump %s and %s" % [path, meta])
	else:
		print("Breakpad disabled; skipped write_minidump file checks.")
	if failed == 0:
		print("All crash_reporter_module_test checks passed.")
	quit(failed)
