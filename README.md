# DevP — Ruby Developer Productivity CLI

A terminal tool for tracking work sessions, logging daily notes, and exporting summaries. Built with plain Ruby + RSpec — no runtime gem dependencies.

```
$ devp start -p api -d "refactor auth"
▶ Timer started for project 'api'

$ devp stop
■ Timer stopped.
  Project:  api
  Duration: 1h 12m 5s
  Session ID: 9f3c8e6a12bb

$ devp summary
📊 Productivity Summary
────────────────────────────────────────
Total sessions: 3
Total time:     2h 40m 12s
Log entries:    7

By project:
  api                  1h 12m 5s (45.1%)
  frontend             0h 48m 0s (30.2%)
  general              0h 40m 7s (24.7%)
```

---

## Features

- ⏱️ **Start/stop timers** with per-project attribution.
- 📝 **Daily logs** with categories: `note`, `blocker`, `win`, `todo`, `idea`.
- 📅 **Today view** combining sessions and log entries.
- 📊 **Summary** with total time and per-project breakdown.
- 📤 **Exports** to **JSON**, **CSV**, and **Markdown**.
- 💾 **Zero runtime deps** — all data stored as JSON in `~/.devp/`.
- ✅ **Fully tested** with RSpec (unit + CLI integration).

---

## Installation

```bash
git clone https://github.com/mefaisalraheem/ruby-dev-productivity-cli.git
cd ruby-dev-productivity-cli
bundle install
chmod +x bin/devp

# Optional: link into PATH
ln -s "$(pwd)/bin/devp" /usr/local/bin/devp
```

Requires **Ruby ≥ 3.0**.

---

## Commands

| Command | Description |
|---------|-------------|
| `devp start [-p project] [-d description]` | Start a timer |
| `devp stop` | Stop the timer and save a session |
| `devp status` | Show the running timer |
| `devp log <msg> [-c cat] [--date YYYY-MM-DD]` | Add a daily log entry |
| `devp logs [--date YYYY-MM-DD]` | List logs for a date |
| `devp today` | Show today's sessions + logs |
| `devp sessions [-p project] [-n limit]` | List recent sessions |
| `devp summary` | Show per-project totals |
| `devp export <json\|csv\|markdown> [-o path]` | Export data |
| `devp clear <sessions\|logs\|all>` | Clear stored data |
| `devp version` / `devp help` | Info commands |

### Log categories

`note` · `blocker` · `win` · `todo` · `idea`

---

## Data storage

All data lives in `~/.devp/` by default (override with `DEVP_HOME`):

```
~/.devp/
├── sessions.json
├── logs.json
├── timer.json
└── config.yml
```

Example `sessions.json` record:

```json
{
  "id": "9f3c8e6a12bb",
  "project": "api",
  "description": "refactor auth",
  "started_at": "2024-06-01T09:00:00+00:00",
  "ended_at":   "2024-06-01T10:12:05+00:00",
  "duration_seconds": 4325
}
```

---

## Development

Install dev dependencies and run the suite:

```bash
bundle install
bundle exec rspec
```

With coverage:

```bash
COVERAGE=1 bundle exec rspec
```

### Project layout

```
lib/devp.rb              # Loads everything
lib/devp/config.rb       # Directory + settings handling
lib/devp/storage.rb      # JSON file persistence
lib/devp/session.rb      # Session entity
lib/devp/log_entry.rb    # Log entry entity
lib/devp/timer.rb        # Start/stop coordination
lib/devp/formatter.rb    # Table + duration formatting
lib/devp/exporter.rb     # JSON / CSV / Markdown exports
lib/devp/cli.rb          # Command dispatch
spec/                    # RSpec suites
```

### Running the CLI locally

```bash
ruby -Ilib bin/devp help
```

---

## Design notes

- **No runtime gems.** Uses only Ruby's stdlib (`json`, `yaml`, `time`, `securerandom`, `fileutils`).
- **Entity classes (`Session`, `LogEntry`)** own their serialization via `to_h` / `from_h`, keeping the storage layer dumb.
- **`Storage`** is intentionally generic — one JSON file per collection.
- **`Timer`** composes `Storage` for timer state and session persistence.
- **`CLI`** is injected with `config`, `out`, and `err` so it is trivially unit-testable without touching the real filesystem or `$stdout`.

---

## License

MIT © Ruby Dev Productivity