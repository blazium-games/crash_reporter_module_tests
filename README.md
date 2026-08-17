# Crash Reporter Module Tests

A test suite and example project for the **CrashReporter** module built for the [Blazium Engine](https://github.com/blazium-games/blazium).

## Features

- Headless `run_tests.gd` checks that the singleton exists and, when Breakpad is compiled in, that `write_minidump()` writes a `.dmp` and sidecar `.json`.
- Interactive scene with Write minidump, Open sidecar, and Crash now.

Do **not** call `induce_crash()` from headless tests.

## Requirements

- A Blazium editor built with `editor_crash_reporter=yes`, or an export template built with `crash_reporter=yes`.
- Optional full loop: [example_crash_reporter_project](https://github.com/blazium-games/example_crash_reporter_project) and [example_crash_reporter_server](https://github.com/blazium-games/example_crash_reporter_server).

Set `application/crash_reporter/endpoint` and `application/crash_reporter/app_id` in Project Settings before using Open sidecar against a local ingest server.

## Running Tests

```bash
blazium --headless --path . -s run_tests.gd
```

## License

MIT — see [LICENSE](LICENSE).
