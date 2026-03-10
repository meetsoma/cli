# Soma — Changelog

All notable changes documented here. See [agent changelog](https://github.com/meetsoma/agent/blob/dev/CHANGELOG.md) for full details.

## [0.3.0] — 2026-03-10

### Added

- **Auto-init** — first `soma` run creates `.soma/` immediately, no interactive prompt (works around Pi TUI timing)
- **`/inhale`** — load preload from last session into current conversation (was just a status message before)
- **`/breathe` auto-rotate** — exhale + new session + preload injection, fully working end-to-end
- **Extension scaffolding** — `soma init` copies bundled extensions into `.soma/extensions/` (preserves user customizations)
- **BREATHE COMPLETE detection** — flush watcher catches both "FLUSH COMPLETE" and "BREATHE COMPLETE"

### Fixed

- **`/breathe` crash** — `ctx.newSession is not a function` in `turn_end` (command context not available in event handlers)
- **Stale Ctrl+N reference** — flush notification now says `/auto-continue`
- **`.gitignore` blocking `.github/media/`** — changed `/media` pattern instead of `media`

### Changed

- README overhauled — mascot PNG at 144px (Fibonacci), badges, hub/docs links
- SVG brand assets committed to `.github/media/`

## [0.2.1] — 2026-03-09

### Added

- **Core modules** — 9 core modules bundled (discovery, identity, heat, muscles, protocols, etc.)
- **Scripts** — 5 bash tools: search, scan, snapshot, tldr, frontmatter date-hook
- **Built-in protocols** — 4 protocols + templates shipped in `.soma/`
- `/breathe` command — save state + auto-continue seamlessly
- `/preload` command — inspect what carries to next session
- Context warnings at 50/70/80% usage, auto-exhale at 85%

### Fixed

- `soma --version` now works without requiring pi-ai dependency at runtime
- Package includes all runtime assets (core, scripts, .soma were missing in 0.1.0)

### Changed

- `files` array updated to include `core/`, `scripts/`, `.soma/`
- README updated with full command reference

## [0.1.0] — 2026-03-08

### Initial Release

- `npm i -g meetsoma` — public CLI package
- Pi-based agent with `.soma/` config directory
- `soma` binary for fresh sessions, `soma -c` to continue with preload
- Identity, memory, muscles, protocols, heat system
- 9 core modules, 3 extensions, 4 built-in protocols
- [soma.gravicity.ai](https://soma.gravicity.ai) — docs, blog, ecosystem
