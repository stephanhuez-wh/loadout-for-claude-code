# shellcheck shell=sh
# Shared helpers for loadout. POSIX sh only: macOS still ships Bash 3.2.

LOADOUT_VERSION="0.0.0"

info() { printf '%s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$*" >&2; exit 2; }

# Claude Code honours CLAUDE_CONFIG_DIR, and so does loadout, which lets tests
# run against a temporary directory instead of the real ~/.claude.
claude_config_dir() {
  if [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then
    printf '%s\n' "$CLAUDE_CONFIG_DIR"
  else
    printf '%s\n' "$HOME/.claude"
  fi
}

detect_os() {
  case "$(uname -s)" in
    Darwin) printf 'macos\n' ;;
    Linux)  printf 'linux\n' ;;
    *)      printf 'unsupported\n' ;;
  esac
}
