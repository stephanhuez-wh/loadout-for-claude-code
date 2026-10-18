# Contributing

Thanks for your interest in loadout. Read the [architecture](docs/architecture.md) first: most rules below follow from its decisions.

## Ground rules

| Rule | Why |
|---|---|
| **POSIX `sh` only** in `setup.sh` and `lib/` | macOS ships Bash 3.2, and loadout installs nothing |
| **No new runtime dependency** | Only `sh`, base utilities, `osascript` (macOS) and `python3` (Linux) |
| **Every plugin has `"defaultEnabled": false`** | Otherwise it switches on in every project |
| **Every plugin declares its target** in `metadata.loadout.target` | `code-only` or `shared`, see architecture section 8 |
| **`shared` plugins have no `bin/`, hooks or `!` commands** | Cowork does not run them |
| **No "claude" in plugin names** | The validator rejects or warns about it |
| **Generic content only** | Personal or client material belongs in a private overlay |

## Before opening a pull request

```bash
sh -n setup.sh lib/*.sh                         # syntax
claude plugin validate . --strict               # marketplace (warns while it has no plugins)
claude plugin validate plugins/<name> --strict  # each plugin you touched
```

Install the secret scan once with `pre-commit install`.

## Commits

Small, focused commits with a message that says why. Update `CHANGELOG.md` under **Unreleased**.
