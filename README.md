# meetsoma

> σῶμα — the body. The vessel that grows around you.

An AI coding agent with self-growing memory. Identity, protocols, and muscles that evolve with use.

Built on [Pi](https://github.com/badlogic/pi-mono). Made by [Gravicity](https://gravicity.ai).

## Install

```bash
npm install -g meetsoma
```

## Quick Start

```bash
cd your-project
soma
```

On first run, Soma creates `.soma/` — detecting your project stack, parent workspaces, and `CLAUDE.md` automatically. She writes her own identity based on what she finds. Next session, she picks up where she left off.

### Session Modes

```bash
soma                # Fresh session — identity + protocols, clean slate
soma --continue     # Resume — picks up where you left off
soma --resume       # Select a previous session to resume
```

## What Grows Over Time

**Session 1:** Empty. Soma discovers her identity. Protocols load by default heat.

**Session 5:** Preloads carry context between sessions. Muscles start forming from repeated patterns.

**Session 20:** Hot protocols stay loaded, cold ones fade. Muscles auto-surface when relevant. Your `.soma/` is shaped by your work.

## The Breath Cycle

Sessions are breaths. **Exhale** writes what Soma learned. **Inhale** picks it up.

```
Session 1 (inhale) → work → exhale (preload written)
                                    ↓
Session 2 (inhale) ← picks up preload → work → exhale
                                                      ↓
Session 3 (inhale) ← ...and so on
```

At 85% context, Soma auto-exhales and continues seamlessly. No context is lost.

## Commands

| Command | What it does |
|---------|-------------|
| `/breathe` | Save state + auto-continue into a fresh session |
| `/exhale` | Save state, write preload, end session (alias: `/flush`) |
| `/rest` | Disable keepalive + exhale — for when you're done for the night |
| `/inhale` | Start fresh — reload identity + protocols |
| `/pin <name>` | Pin a protocol/muscle to hot (stays loaded) |
| `/kill <name>` | Drop a protocol/muscle's heat to zero |
| `/soma` | Show memory status — identity, heat states, context |
| `/soma prompt` | Preview compiled system prompt with token estimate |
| `/keepalive` | Toggle cache keepalive (`on`/`off`/`status`) |
| `/auto-continue` | Create new session and inject last preload as continuation |
| `/install <type> <name>` | Install protocol/muscle/skill/template from hub |
| `/list local\|remote` | Browse installed or available content |

### CLI Commands (non-interactive)

```bash
soma content install <type> <name>   # Install from hub (protocol, muscle, skill, template)
soma content list --remote           # List available content on hub
soma content list --local            # List installed content
soma init --template <name>          # Scaffold .soma/ from a template
```
| `/preload` | Show current preload content |

## Memory Structure

```
.soma/
├── identity.md          ← who Soma becomes (discovered, not configured)
├── STATE.md             ← project architecture truth
├── protocols/           ← behavioral rules (heat-tracked)
├── memory/
│   ├── muscles/         ← patterns learned from experience
│   ├── preload-*.md     ← session-scoped continuations
│   └── sessions/        ← daily logs
├── settings.json        ← thresholds, inheritance, persona, system prompt toggles
├── scripts/             ← dev tooling (search, scan, snapshot, tldr)
└── templates/           ← starter protocols + identity templates
```

## Philosophy

- **Identity is discovered, not configured.** Soma writes who she is after she's worked, not before.
- **Structure is earned, not imposed.** Starts minimal. Grows where needed.
- **Memory is cultivated, not stored.** Patterns emerge from use.
- **Sessions are breaths.** Each exhale writes what was learned. Each inhale picks it up.

## Provider Setup

```bash
export ANTHROPIC_API_KEY=sk-...    # Anthropic (Claude)
export GOOGLE_API_KEY=...          # Google (Gemini)
export OPENAI_API_KEY=sk-...       # OpenAI
```

## Documentation

Full docs at [soma.gravicity.ai](https://soma.gravicity.ai) and [GitHub](https://github.com/meetsoma/soma-agent).

## License

[MIT](LICENSE) — [Gravicity](https://gravicity.ai)
