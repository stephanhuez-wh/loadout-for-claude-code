# Architecture and decisions

This document explains **how** loadout keeps Claude Code environments clean and **why** each choice was made. The behaviours described were checked against the official Claude Code documentation in October 2026.

## 1. Goals

| Goal | Success criterion |
|---|---|
| **Separate Claude Code from Claude (chat, Cowork)** | No claude.ai connector or synced skill in a Claude Code session |
| **Choose components per project** | A project loads only the plugins and rules it declares |
| **Reuse without duplication** | Each skill, agent or rule exists once |
| **Automate the setup, with nothing to install** | One command per step, idempotent, reversible, built-in tools only |

**Out of scope**: native Windows (planned later), multiple accounts, isolation through `CLAUDE_CONFIG_DIR` profiles, and Claude Code run from the Desktop app.

## 2. Three layers

```
USER      ~/.claude/            almost empty, loaded everywhere
   │
LIBRARY   loadout-for-claude-code/   versioned, nothing switches itself on
   │      + private overlay     optional, same layout
   │
PROJECT   project/.claude/      declares what it takes from the library
```

| Layer | Allowed | Not allowed |
|---|---|---|
| **User** | Language, writing style, separation settings | Domain skills, MCP servers, agents, rules |
| **Library** | Plugins (disabled by default), shared rules, templates, setup scripts | Client data, secrets |
| **Project** | `enabledPlugins`, `@` imports, project-specific rules | Copies of library skills |

**Why an empty user level**: everything in `~/.claude/` loads in every session. User files such as `~/.claude/rules/` apply to every project on the machine.

## 3. Separating Claude Code from Claude

### Leak channels into Claude Code

With one account, two claude.ai features reach Claude Code in the terminal:

| Channel | Mechanism | Fix |
|---|---|---|
| **Connectors** (Gmail, Drive, Notion…) | Loaded automatically in every session | `"disableClaudeAiConnectors": true` |
| **Account skills** | Downloaded into `~/.claude/skills/synced/` and resynced during the session | `"syncClaudeAiSkills": false` |

```json
// ~/.claude/settings.json
{
  "disableClaudeAiConnectors": true,
  "syncClaudeAiSkills": false
}
```

**`disableClaudeAiConnectors`** works in any settings scope, and `true` in any source wins over `false` elsewhere. A project cannot switch connectors back on by mistake.

**When a project needs a service** (Drive, Gmail), it declares an explicit MCP server in its `.mcp.json` or through a plugin, rather than re-enabling the sync.

### What stays shared

**Cowork reads `~/.claude/CLAUDE.md`**, but skips imports in that file that point outside the session folder. The user `CLAUDE.md` therefore holds only what suits both worlds.

**Cowork does not read `~/.claude/skills/`**: it loads the skills enabled on the claude.ai account. The two skill libraries are separate by design.

### Known limit

**Claude Code launched from the Desktop app** receives connectors in-process, and no MCP setting reaches them. loadout assumes terminal use only.

## 4. Plugins

### What a plugin can contain

| Component | Location | Used here |
|---|---|---|
| **Skills** | `skills/<name>/SKILL.md` | Yes |
| **Sub-agents** | `agents/*.md` | Yes |
| **Hooks** | `hooks/hooks.json` | Yes, Claude Code only |
| **MCP servers** | `.mcp.json` | Yes |
| **Output styles** | `output-styles/` | Possible |
| **Rules / CLAUDE.md** | none | **Not supported**, see section 5 |

A `CLAUDE.md` at a plugin root is not loaded, and `claude plugin validate` warns about it.

### Disabled by default

**`defaultEnabled` defaults to `true`.** Left unset, an installed plugin switches on everywhere. Every plugin in loadout therefore declares:

```json
// plugins/<name>/.claude-plugin/plugin.json
{
  "name": "dev",
  "version": "0.1.0",
  "description": "Skills, agents and MCP servers for development",
  "author": { "name": "Wiser Hare" },
  "defaultEnabled": false
}
```

### Building blocks and profiles

```
profile-dev ──depends on──► dev
            └─depends on──► writing

profile-coaching ──depends on──► coaching
                 └─depends on──► writing
```

**A building block** groups components from one domain. **A profile** is an empty plugin that declares `dependencies`. A plugin that an enabled plugin depends on starts enabled automatically.

**Benefit**: a project enables a single profile, and composition is managed in the library rather than in each project.

### Naming

| Item | Name | Reason |
|---|---|---|
| **Repository** | `loadout-for-claude-code` | States the link with Claude Code where people search for it. "for" marks a third-party project |
| **Marketplace** | `loadout` | Short in every command: `profile-dev@loadout` |
| **Plugins** | kebab-case, no "claude" | The validator rejects names starting with `claude-`, `anthropic-` or `cc-plugin-`, and warns when "claude" appears as a whole word |

GitHub topics `claude-code` and `claude-code-plugins` add discoverability without touching technical names.

## 5. Rules

Since plugins cannot carry rules, loadout relies on native mechanisms:

| Mechanism | Scope | Verdict |
|---|---|---|
| **`@` imports in the project `CLAUDE.md`** | Explicit choice per project | **Chosen for shared rules** |
| **Project `.claude/rules/`** | Project, with optional `paths` targeting | **Chosen for project-specific rules** |
| `~/.claude/rules/` | Every project | Rejected, pollutes everything |
| Symlinks in `.claude/rules/` | Project | Rejected, see below |
| `SessionStart` hook injecting text | Plugin | Rejected, opaque and absent from Cowork |

**Imports**: an import outside the working directory triggers an approval dialog, once per project. Imports can nest up to four levels deep.

**Context cost**: imports organise rules but do not reduce their cost, because imported files load at launch. Keep rules short, under 200 lines per `CLAUDE.md`.

**Why not symlinks**: a rule linked from outside the project loads only after approval, and only if it has no `paths` field. Path-targeted rules must live in the project.

**Import paths**: the `project` command writes imports with the actual clone location, so the repository can live anywhere.

## 6. Setup automation

### Runtime: nothing to install

```
setup.sh (POSIX sh)
   ├── orchestration, backups, diffs     → sh and base utilities
   ├── plugins, marketplace, MCP         → claude CLI (already required)
   └── JSON merge (lib/json.sh, small and isolated)
          ├── macOS  → osascript -l JavaScript
          └── Linux  → python3
```

| Choice | Reason |
|---|---|
| **POSIX `sh`, not Bash 4** | macOS still ships Bash 3.2 |
| **A dedicated JSON helper** | Merging `settings.json` in plain shell breaks on the first non-trivial file |
| **`osascript` on macOS** | JavaScript engine shipped with every macOS |
| **`python3` on Linux** | Installed by default on mainstream distributions |

**Unsupported case**: a minimal Linux image without `python3`. `setup.sh` stops with a clear message before changing anything.

### Manifest

The target state lives in `manifest/`: settings keys to merge, text blocks to insert, plugins to register. `setup.sh` only executes it. This keeps the logic declarative, and a future Windows script can execute the same manifest.

### Commands

| Command | Reads | Writes |
|---|---|---|
| `install` | `~/.claude/settings.json`, `~/.claude/CLAUDE.md` | Backup, merged settings, minimal `CLAUDE.md`, marketplace registration |
| `project <path> --profile <name>` | Project settings and `CLAUDE.md` | `enabledPlugins`, project-scope plugin install, `@` import block |
| `doctor [<path>]` | User and project config | Nothing, report only |
| `restore [<backup>]` | Backup folder | User config |

### Design rules

| Rule | Implementation |
|---|---|
| **Idempotent** | Running a command twice gives the same result |
| **Non-destructive** | Backup before any change to user config, timestamped under `~/.claude/backups/loadout/` |
| **Merge, never replace** | JSON settings merged key by key, existing keys kept |
| **Ask before overwriting** | Any existing file that would change is shown as a diff first |
| **Dry run everywhere** | `--dry-run` prints the plan without writing |
| **Marked blocks** | Text added to `CLAUDE.md` sits between `<!-- loadout:start -->` and `<!-- loadout:end -->`, so it can be updated or removed cleanly |
| **Testable** | Scripts honour `CLAUDE_CONFIG_DIR`, so tests run against a temporary directory |

### What `doctor` checks

| Check | Method |
|---|---|
| Separation settings present | Read `settings.json` |
| No user-level skills, agents or rules beyond the allowed ones | List `~/.claude/` |
| No user-scope MCP servers | `claude mcp list` |
| Marketplace registered | `claude plugin marketplace list` |
| Plugins valid | `claude plugin validate --strict` |
| Every library plugin has `defaultEnabled: false` | Read each `plugin.json` |
| `shared` plugins have no `bin/`, no hooks, no `!` commands | Inspect plugin files |
| Project: profile enabled and installed, imports resolve | Read project files |

Interactive checks stay manual, as Claude Code offers no CLI equivalent: `/mcp`, `/skills` and `/context` inside a session.

## 7. Private overlay

The public repository holds generic plugins and rules only. Personal or client material lives in a private repository with the same layout. `install --overlay <path>` registers it as a second marketplace, and `project` can import rules from both.

## 8. Cowork compatibility

Cowork installs plugins from a marketplace, in the same format as Claude Code. loadout uses this to avoid duplicating skills between the two, while keeping development plugins free of Cowork's limits.

### Two targets

| Target | For | Allowed |
|---|---|---|
| **`code-only`** | Claude Code | Everything: hooks, `bin/`, `!` commands in skills |
| **`shared`** | Claude Code and Cowork | Skills and agents, within the constraints below |

Each plugin declares its target in the free-form `metadata` field of `plugin.json`, which Claude Code stores without acting on it:

```json
{
  "name": "writing",
  "defaultEnabled": false,
  "metadata": { "loadout": { "target": "shared" } }
}
```

A plugin without a declared target is treated as `code-only`.

### Constraints on shared plugins

| Constraint | Reason |
|---|---|
| **No `bin/` folder** at the plugin root | claude.ai and Cowork refuse to install such a plugin |
| **No hooks** | Plugin `SessionStart` hooks do not fire in Cowork |
| **No `!` commands in skills** | In Cowork, dynamic context lines are replaced with a placeholder instead of running |

`doctor` and CI enforce these rules on every `shared` plugin.

### Installing in Cowork

Shared plugins are installed one by one in Cowork, from **Customize → Plugins → Add marketplace**, using `stephanhuez-wh/loadout-for-claude-code`. Profiles remain a Claude Code concept in loadout.

**Separation stays intact**: each side installs the plugin separately and keeps its own configuration. Sharing a plugin creates no bridge between them.

## 9. Decisions

| # | Decision | Rejected alternative | Reason |
|---|---|---|---|
| D1 | Native configuration, no third-party manager | clenv, claudeup, claude-use | One account, need fully covered natively, third-party tools break on updates |
| D2 | Near-empty user level | Rich user level with exclusions | User level loads everywhere, and partly in Cowork |
| D3 | Plugins with `defaultEnabled: false` | Default value | Otherwise every plugin is active in every project |
| D4 | Building blocks and profiles via `dependencies` | Listing every block in every project | Composition stays central |
| D5 | Shared rules through `@` imports | Symlinks, hooks | Visible, native, works for always-on rules |
| D6 | Terminal only | Desktop app | Only context where connector separation is guaranteed |
| D7 | POSIX `sh` with built-in JSON engines | Bash 4 with `jq`, Python only | Nothing to install on macOS or mainstream Linux |
| D8 | Declarative manifest | Logic embedded in the script | Testable, and reusable by a future Windows script |
| D9 | macOS and Linux first, Windows later | All three at once | Smaller first release, Windows needs its own PowerShell script |
| D10 | Public library plus private overlay | One private repository | Shareable core, confidential material kept apart |
| D11 | Repository `loadout-for-claude-code`, marketplace `loadout` | `claude-loadout`, one name everywhere | Explicit link with Claude Code, clearly unofficial, technical names clear of validator rules |
| D12 | Hybrid targets: `code-only` and `shared` plugins | All Code-only, or all shared | No duplication for simple skills, full power kept for development plugins |

## 10. Limits and risks

| Risk | Impact | Mitigation |
|---|---|---|
| Enabled in project settings but not installed | Plugin reported as not installed | `project` runs `claude plugin install <name>@loadout --scope project` |
| `skillOverrides` ignores plugin skills | A plugin skill cannot be hidden that way | Manage through `/plugin`, or split the block |
| Two JSON backends | Behaviour drift between macOS and Linux | Same fixtures run on both in CI |
| Fast-moving Claude Code | Settings keys renamed or added | `doctor` reports unknown state, docs reviewed at each major update |
| Public repository | Client data or secrets leaked | Private overlay, pre-commit secret scan, review before each push |
| Script edits user config | Broken configuration | Backup, dry run, `restore` |

## 11. References

- [Settings](https://code.claude.com/docs/en/settings)
- [Plugin manifest reference](https://code.claude.com/docs/en/plugins-reference)
- [How Claude remembers your project](https://code.claude.com/docs/en/memory)
- [Skills](https://code.claude.com/docs/en/skills)
- [MCP](https://code.claude.com/docs/en/mcp)
- [Plugins for an organisation](https://code.claude.com/docs/en/plugins/org)
