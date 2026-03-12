# Soma — Changelog

All notable changes documented here. Source of truth: [agent repo](https://github.com/meetsoma/agent).

## [Unreleased]

### Added
- **AMPS distribution** — `scope: bundled|hub` on all content. Bundled protocols slimmed to 4 (breath-cycle, heat-tracking, session-checkpoints, pattern-evolution).
- **Scope-aware sync** — `sync-from-agent.sh` reads `scope: bundled` from community frontmatter.
- **`release.sh`** — full release workflow: sync, test, bump, changelog, publish, push.
- **Content CLI** — `soma content install|list`, `soma init --template`.
- **15 commands** — /pin, /kill, /exhale, /flush, /rest, /breathe, /auto-continue, /preload, /inhale, /soma, /install, /list, /guard-status, /status, /keepalive.

### Changed
- Bundled protocols reduced from all community protocols to 4 scope:bundled only.
- Changelog rewritten against verified codebase.

## [0.3.0] — 2026-03-10

### Added
- **Auto-init** — first `soma` run creates `.soma/` immediately, no interactive prompt.
- **`/inhale`** — load preload from last session into current conversation.
- **`/breathe` auto-rotate** — exhale + new session + preload injection.
- **Extension scaffolding** — `soma init` copies bundled extensions into `.soma/extensions/`.

### Fixed
- `/breathe` crash — `ctx.newSession is not a function` in event handlers.
- Stale Ctrl+N reference → `/auto-continue`.
- `.gitignore` blocking `.github/media/`.

## [0.2.2-beta.1] — 2026-03-10

### Changed
- Pre-release test of sync workflow before v0.3.0.

## [0.2.1] — 2026-03-09

### Added
- **Core modules** — 9 core modules bundled (discovery, identity, heat, muscles, protocols, etc.)
- **Scripts** — soma-scan, soma-search, soma-snapshot, soma-tldr, frontmatter date-hook.
- **Built-in protocols** — shipped in `.soma/protocols/`.
- `/breathe`, `/preload` commands.
- Context warnings at 50/70/80% usage, auto-exhale at 85%.

### Fixed
- `soma --version` works without pi-ai dependency at runtime.
- Package includes all runtime assets.

## [0.1.0] — 2026-03-08

### Initial Release
- `npm i -g meetsoma` — public CLI package.
- Pi-based agent with `.soma/` config directory.
- `soma` binary for fresh sessions, `soma -c` to continue with preload.
- Identity, memory, muscles, protocols, heat system.
- 9 core modules, 3 extensions, 4 built-in protocols.
