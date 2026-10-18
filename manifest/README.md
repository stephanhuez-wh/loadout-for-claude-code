# Manifest

The target state that `setup.sh` applies. Scripts read these files; they never hard-code values.

| File | Applied by | Effect |
|---|---|---|
| `user-settings.json` | `install` | Keys merged into `~/.claude/settings.json`. Existing keys are kept unless listed here |

See [architecture, section 6](../docs/architecture.md#6-setup-automation).
