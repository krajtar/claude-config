# Changelog

All notable changes to this project are documented here.

## [Unreleased] - 2026-08-30

### Added
- `--remote-control` flag applied to all real `claude` invocations from the shell wrapper (menu choices, `ch`, `cs`)
- `CLAUDE-base.md` rule: always commit at the end of any work that produced artifacts (code, config, docs), without pushing/merging past what's already confirmed

### Changed
- Renamed the interactive shell wrapper from `claude()` to `c()` so it never shadows the real `claude` binary — plain `claude` invocations (scripts, muscle memory, other tools) now always run the actual command untouched
- `ch`/`cs` are now plain aliases straight to the real `claude` binary instead of routing through the wrapper function

### Removed
- SafeClaw container integration entirely: `sc`, `scg`, `dashboard` functions, the `SAFECLAW_DIR` variable, and the container-related menu options in `c`
