@AGENTS.md

## Claude Code

- Use plan mode before any change that touches a decision in `docs/architecture.md`, and ask before changing one.
- Never run `setup.sh` without `CLAUDE_CONFIG_DIR` pointing at a temporary directory. This session's own `~/.claude` is not a test fixture.
- Before stating how Claude Code behaves (settings keys, plugin fields, loading rules), check the official docs rather than memory, and cite the page in the change.
- At the start of a task, read the current phase in `docs/plan.md` and say which checkbox you are working on.
- Keep commits small, one checkbox or one fix each, with a message that says why.
