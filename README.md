# loadout for Claude Code

An unofficial, community-built modular setup for Claude Code: clean environments per project, reusable building blocks with no duplication, and a strict separation between Claude Code and Claude (chat, Cowork). A setup script applies and verifies the whole configuration, with nothing to install.

## Why

Claude Code loads everything at user level (`~/.claude/`) into **every** session. Over time, skills, MCP servers and instructions pile up and pollute projects that never needed them.

loadout applies one rule: **user level stays almost empty, and each project declares what it uses**, picking from a versioned library. Like a loadout, you choose the kit for the mission.

## Principles

| Principle | Implementation |
|---|---|
| **Separate Claude Code from chat and Cowork** | claude.ai connectors and synced skills switched off in Claude Code |
| **Per-project selection** | Plugins disabled by default, enabled in the project's `.claude/settings.json` |
| **No duplication** | One git marketplace for skills, sub-agents, hooks and MCP servers |
| **Shared rules** | Files in `rules/` imported with `@` from the project's `CLAUDE.md` |
| **Nothing to install** | POSIX `sh` plus tools the operating system already ships |
| **Automated and reversible** | `setup.sh` installs, configures projects, checks and restores |

## Repository layout

```
loadout-for-claude-code/
├── setup.sh                    entry point for every setup command
├── lib/                        sh modules, including the JSON helper
├── manifest/                   target state: settings to merge, blocks to insert
├── .claude-plugin/
│   └── marketplace.json        plugin catalogue
├── plugins/
│   ├── dev/                    block, code-only: development skills, agents, hooks
│   ├── writing/                block, shared: writing skills, also usable in Cowork
│   └── profile-dev/            profile: empty plugin that depends on blocks
├── rules/                      always-on instructions, imported with @
├── templates/
│   ├── user-CLAUDE.md          minimal user-level CLAUDE.md
│   └── project/                files copied into a project
├── tests/                      fixtures and script tests, run in CI
└── docs/
    ├── architecture.md
    └── plan.md
```

## Quick start

```bash
git clone https://github.com/stephanhuez-wh/loadout-for-claude-code.git ~/dev/loadout
cd ~/dev/loadout
./setup.sh install --dry-run   # show what would change
./setup.sh install             # apply, with a backup first
./setup.sh doctor              # check the result
```

Then, for each project:

```bash
./setup.sh project ~/code/my-app --profile dev
```

## Commands

| Command | What it does |
|---|---|
| `install` | Backs up user config, merges the separation settings, installs the minimal `CLAUDE.md`, registers the marketplace |
| `project <path> --profile <name>` | Adds the profile to the project's settings, installs it at project scope, writes the `@` imports |
| `doctor [<path>]` | Checks user level and, optionally, a project, and reports anything that leaks or is missing |
| `restore [<backup>]` | Restores a previous backup of user config |

Every command that writes accepts `--dry-run`, and none overwrites a file without asking.

## Using shared plugins in Cowork

Plugins marked `shared` also work in Cowork. Add the marketplace from **Customize → Plugins → Add marketplace** with `stephanhuez-wh/loadout-for-claude-code`, then install the blocks you want. Plugins marked `code-only` rely on hooks or scripts that Cowork does not run. See the [architecture](docs/architecture.md#8-cowork-compatibility).

## Private overlay

Keep client-specific or confidential rules and plugins out of this public repository. Point the setup at a private repository instead:

```bash
./setup.sh install --overlay ~/dev/my-private-loadout
```

The overlay follows the same layout (`plugins/`, `rules/`) and is registered as a second marketplace.

## Requirements

| System | Supported | What loadout uses |
|---|---|---|
| **macOS** | Yes | `sh`, `osascript` (built in) |
| **Linux, including WSL** | Yes | `sh`, `python3` (default on mainstream distributions) |
| **Windows (native)** | Planned | See the [roadmap](docs/plan.md#roadmap) |

You also need Claude Code used from the **terminal**, signed in with a claude.ai account, in a recent version (terminal skill sync arrived in v2.1.273).

## Documentation

- [Architecture and decisions](docs/architecture.md)
- [Delivery plan](docs/plan.md)

## Status

Work in progress. See the [plan](docs/plan.md).

## Names

| Item | Name |
|---|---|
| Repository | `loadout-for-claude-code` |
| Marketplace | `loadout` |
| Profiles | `profile-<name>@loadout` |

The repository name says what loadout is for. Technical names stay short and free of Anthropic's trademarks.

## Disclaimer

loadout is not affiliated with or endorsed by Anthropic. Claude and Claude Code are trademarks of Anthropic.

## Licence

MIT (to be confirmed before the first release).
