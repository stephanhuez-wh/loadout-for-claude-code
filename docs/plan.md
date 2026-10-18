# Delivery plan

Seven short phases leading to a first public release, `v0.1.0`, for macOS and Linux. Each phase ends with a check you can verify. **Rule of thumb**: do not start a phase until the previous one passes.

```
P0 Prepare ─► P1 Skeleton ─► P2 install ─► P3 Plugins
                                                │
P6 Release ◄── P5 doctor & CI ◄── P4 project ◄──┘
```

| Phase | Estimate | Deliverable |
|---|---|---|
| P0 Prepare | 1 h | Baseline, backup, technical spikes |
| P1 Skeleton | 1 h | Public repository with layout, licence, empty marketplace |
| P2 `install` | 4 h | User-level setup automated, with dry run, backup and restore |
| P3 Plugins | 2 h | Generic blocks `dev` and `writing`, profile `profile-dev` |
| P4 `project` | 3 h | Project setup automated, tested on a real project |
| P5 `doctor` and CI | 3 h | Checks, script tests, CI on macOS and Linux |
| P6 Release | 1 h | `v0.1.0` tagged, installable from GitHub |

## P0. Prepare

- [ ] Update Claude Code (`claude update`) and record the version
- [ ] Back up `~/.claude/` and `~/.claude.json` by hand
- [ ] List current user-level skills, agents, rules, MCP servers and plugins
- [ ] Sort each item: **user level**, **public block**, **private overlay**, or **delete**
- [ ] **Spike**: check whether the `claude` CLI can write settings itself. If so, the JSON helper shrinks or disappears
- [ ] **Spike**: prove a key-by-key JSON merge with `osascript -l JavaScript` and with `python3`, on the same input
- [ ] Check that `loadout-for-claude-code` is free on the `stephanhuez-wh` account

**Done when**: a sorted inventory exists (kept private, never committed) and both spikes have a written conclusion.

## P1. Repository skeleton

- [ ] Create the public GitHub repository `loadout-for-claude-code`
- [ ] Add the description, the topics `claude-code` and `claude-code-plugins`, and the non-affiliation notice
- [x] Add the layout from the [README](../README.md)
- [x] Add `LICENSE` (MIT), `.gitignore`, `.gitattributes` (`*.sh` in LF), `CONTRIBUTING.md`
- [x] Write `.claude-plugin/marketplace.json`:
  ```json
  {
    "name": "loadout",
    "owner": { "name": "Wiser Hare" },
    "plugins": []
  }
  ```
- [x] Add `manifest/` with the user settings to merge and `templates/user-CLAUDE.md`
- [x] Add a pre-commit secret scan (for example `gitleaks`, a contributor tool, not a user requirement)

**Done when**: the repository is pushed and `claude plugin marketplace add ./` succeeds locally.

## P2. `install` command

- [ ] `setup.sh` dispatcher in POSIX `sh`, with `--help`, `--dry-run`, `--overlay`
- [ ] OS detection and prerequisite checks: `claude` on `PATH`, minimum Claude Code version, `osascript` or `python3`
- [ ] `lib/json.sh`: one interface, two backends (macOS, Linux)
- [ ] Timestamped backup of user config
- [ ] Key-by-key merge of the manifest settings into `settings.json`
- [ ] Marked block in `~/.claude/CLAUDE.md`, with a diff before any change
- [ ] Marketplace registration, skipped if already present
- [ ] Optional overlay registration
- [ ] `restore` command
- [ ] Honour `CLAUDE_CONFIG_DIR` for testing

**Done when**:
- [ ] Running `install` twice changes nothing the second time
- [ ] `restore` returns user config to its previous state
- [ ] In a session, `/mcp` lists no "claude.ai …" server and `/skills` shows no `claude.ai sync` section
- [ ] Same result on macOS and on Linux

## P3. Generic plugins

- [ ] Block `plugins/dev/` with `"defaultEnabled": false` and target `code-only`
- [ ] Block `plugins/writing/` with `"defaultEnabled": false` and target `shared`
- [ ] Profile `plugins/profile-dev/`:
  ```json
  {
    "name": "profile-dev",
    "defaultEnabled": false,
    "dependencies": ["dev", "writing"]
  }
  ```
- [ ] Declare the three plugins in `marketplace.json`
- [ ] First shared rules in `rules/`, generic only
- [ ] README per plugin
- [ ] `claude plugin validate plugins/<name> --strict` passes for each

**Done when**:
- [ ] In a folder with no project settings, no skill from `dev` appears
- [ ] `writing` installs and works in Cowork from the local marketplace

## P4. `project` command

- [ ] Copy `templates/project/` without overwriting existing files
- [ ] Merge `enabledPlugins` into the project's `.claude/settings.json`
- [ ] Run `claude plugin install profile-<name>@loadout --scope project`
- [ ] Write the marked `@` import block with the resolved clone path
- [ ] Support rules from the overlay
- [ ] Dogfood on one real project for a week, log friction

**Done when**:
- [ ] `/context` in the project lists exactly the expected items
- [ ] A second folder with no settings stays clean
- [ ] Running `project` twice changes nothing the second time

## P5. `doctor` and CI

- [ ] `doctor` user-level checks (see [architecture](architecture.md#what-doctor-checks))
- [ ] `doctor <path>` project checks
- [ ] Target check: a `shared` plugin with `bin/`, hooks or `!` commands fails
- [ ] Clear exit codes: 0 clean, 1 warnings, 2 errors
- [ ] JSON fixtures: input settings and expected output, shared by both backends
- [ ] Script tests against a temporary `CLAUDE_CONFIG_DIR`
- [ ] `shellcheck` in POSIX mode on every script
- [ ] GitHub Actions matrix `macos-latest` and `ubuntu-latest`: `shellcheck`, tests, `claude plugin validate --strict` on every plugin

**Done when**: CI is green on both systems, and a deliberately broken plugin or fixture turns it red.

## P6. Release

- [ ] Privacy review: no client data, no secrets, no revealing private paths
- [ ] Complete the README: requirements, install, commands, overlay, status
- [ ] `CHANGELOG.md`
- [ ] Tag `v0.1.0` and publish a GitHub release
- [ ] Fresh-machine test on macOS and on Linux:
  ```bash
  git clone https://github.com/stephanhuez-wh/loadout-for-claude-code.git
  cd loadout-for-claude-code
  ./setup.sh install && ./setup.sh doctor
  ```

**Done when**: a fresh machine on each system reaches a clean `doctor` report from the GitHub release alone.

## Roadmap

| Item | Notes |
|---|---|
| **Native Windows** | `setup.ps1` in Windows PowerShell 5.1, executing the same manifest and fixtures. Watch for execution policy, `ConvertTo-Json -Depth`, and CRLF line endings |
| **`setup.sh update`** | Upgrade path for existing users |
| **One-line installer** | Optional, once the setup is stable |

## Open questions

| Question | Decide before |
|---|---|
