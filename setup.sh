#!/bin/sh
# loadout: clean, per-project Claude Code environments.
# Entry point for every setup command. POSIX sh, nothing to install.

set -eu

LOADOUT_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=lib/common.sh
. "$LOADOUT_ROOT/lib/common.sh"

usage() {
  cat <<EOF
loadout $LOADOUT_VERSION

Usage: ./setup.sh <command> [options]

Commands:
  install                         Set up user level: separation settings,
                                  minimal CLAUDE.md, marketplace registration
  project <path> --profile <name> Enable a profile in a project
  doctor [<path>]                 Check user level and, optionally, a project
  restore [<backup>]              Restore a previous backup of user config

Options:
  --dry-run                       Show what would change, write nothing
  --overlay <path>                Also register a private overlay (install)
  -h, --help                      Show this help
  -V, --version                   Show the version

Docs: https://github.com/stephanhuez-wh/loadout-for-claude-code
EOF
}

not_yet() {
  # Placeholders until each phase lands. See docs/plan.md.
  die "'$1' is not implemented yet (planned in phase $2, see docs/plan.md)"
}

main() {
  [ $# -gt 0 ] || { usage; exit 0; }

  case "$(detect_os)" in
    unsupported) die "unsupported system: $(uname -s). loadout supports macOS and Linux." ;;
  esac

  cmd=$1
  shift
  case "$cmd" in
    install) not_yet install P2 ;;
    project) not_yet project P4 ;;
    doctor)  not_yet doctor P5 ;;
    restore) not_yet restore P2 ;;
    -h|--help|help) usage ;;
    -V|--version) info "loadout $LOADOUT_VERSION" ;;
    *) usage >&2; die "unknown command: $cmd" ;;
  esac
}

main "$@"
