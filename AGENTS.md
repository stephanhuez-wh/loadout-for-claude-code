# AGENTS.md

Instructions for any coding agent working on this repository. Claude Code reads them through `CLAUDE.md`.

## What this project is

loadout is a public, unofficial setup for Claude Code: a near-empty user level, a plugin marketplace of reusable blocks, and `setup.sh`, which applies and checks the configuration on macOS and Linux with nothing to install.

- `docs/architecture.md` is the source of truth for design. Decisions are numbered D1, D2…
- `docs/plan.md` defines the phases. Work on the current phase only.

## Commands

```sh
for f in setup.sh lib/*.sh; do sh -n "$f" && dash -n "$f"; done   # POSIX syntax, after every script edit
./setup.sh --help                                      # smoke test of the dispatcher
claude plugin validate . --strict                      # marketplace; warns while it lists no plugins
claude plugin validate plugins/<name> --strict         # each plugin you add or change
python3 -m json.tool <file>.json >/dev/null            # any JSON you edit
```

Run the setup only against a throwaway config, never the real `~/.claude`:

```sh
CLAUDE_CONFIG_DIR="$(mktemp -d)" ./setup.sh install --dry-run
```

## Hard constraints

These follow from the decisions in `docs/architecture.md`. Do not relax one without adding or updating a decision there first.

- **POSIX `sh` only** in `setup.sh` and `lib/`. No arrays, `[[ ]]`, `local`, `function`, `$'…'`, process substitution or `echo -e`. Use `printf`. macOS ships Bash 3.2 (D7).
- **No new dependency.** Allowed: `sh`, POSIX utilities, `claude`, `osascript` on macOS, `python3` on Linux. `jq` is not allowed.
- **JSON is read and written only through `lib/json.sh`**, which has one backend per OS. Never edit JSON with `sed` or string concatenation.
- **No hard-coded target state.** Settings, blocks and plugin lists live in `manifest/`.
- **Every write is safe**: idempotent, supports `--dry-run`, backs up user config first, shows a diff before overwriting, and stays inside `<!-- loadout:start -->` / `<!-- loadout:end -->` markers in `CLAUDE.md` files.
- **Honour `CLAUDE_CONFIG_DIR`** everywhere, through `claude_config_dir` in `lib/common.sh`.
- **Exit codes**: 0 success or clean, 1 warnings, 2 errors.

## Plugin rules

- `.claude-plugin/plugin.json` sets `"defaultEnabled": false` and `metadata.loadout.target` to `code-only` or `shared` (D3, D12).
- `shared` plugins contain no `bin/`, no hooks and no `!` command lines in skills, because Cowork does not run them.
- Names are kebab-case and never contain "claude" or "anthropic".
- No `CLAUDE.md` inside a plugin: it is not loaded. Shared rules go in `rules/`.
- Register every plugin in `.claude-plugin/marketplace.json`.

## Portability pitfalls

| Avoid | Use instead |
|---|---|
| `sed -i` (differs between BSD and GNU) | Write to a temp file, then `mv` |
| `readlink -f` | `cd -- "$dir" && pwd` |
| `grep -P` | `grep -E` |
| GNU-only flags of `date`, `stat`, `mktemp` | Portable forms, or branch on `detect_os` |

## Content rules

- **Public repository**: generic content only. No client names, personal data, secrets or private paths. Personal material belongs in a private overlay.
- Docs and messages in **British English**. No em-dashes.
- Claude Code changes fast. When behaviour matters, check https://code.claude.com/docs and note the version a feature requires.

## Definition of done

- The checks under **Commands** pass.
- The matching boxes in `docs/plan.md` are ticked.
- `CHANGELOG.md` has an entry under **Unreleased**.
- A design change adds or updates a decision in `docs/architecture.md`.
