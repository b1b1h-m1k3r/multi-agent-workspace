# Shared helpers for the workspace scripts. Sourced by them, never run on its own.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS="$ROOT/_scripts"
EXCLUDES="$SCRIPTS/publish-excludes.txt"
DEFAULT_PROJECTS_DIR="${PROJECTS_DIR:-$ROOT/Projects}"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

# One agent name per line, from _scripts/agents.txt (comments and blank lines skipped).
list_agents() {
  if [ -f "$SCRIPTS/agents.txt" ]; then
    grep -v '^[[:space:]]*#' "$SCRIPTS/agents.txt" | sed 's/[[:space:]]*$//' | grep -v '^$'
  else
    printf '%s\n' Claude Codex Gemini Grok
  fi
}

# "prefix=relative/folder" lines from _scripts/collections.txt.
list_collections() {
  [ -f "$SCRIPTS/collections.txt" ] || return 0
  grep -v '^[[:space:]]*#' "$SCRIPTS/collections.txt" | grep '=' || true
}

# resolve_project <name | prefix:name>
# Sets PROJECT_NAME and PROJECT_DIR. A "prefix:" maps to a folder listed in collections.txt,
# so the same structure works for collections that live outside Projects/.
resolve_project() {
  local arg="$1" base="$DEFAULT_PROJECTS_DIR" name="$1"
  case "$arg" in
    *:*)
      local prefix="${arg%%:*}" path
      name="${arg#*:}"
      path=$(list_collections | awk -F= -v p="$prefix" '$1==p { sub(/^[^=]*=/, ""); print; exit }')
      [ -n "$path" ] || die "unknown collection '$prefix'. Add a line '$prefix=<folder relative to the workspace>' to _scripts/collections.txt."
      base="$ROOT/$path"
      ;;
  esac
  case "$name" in
    ""|*..*|/*) die "invalid project name '$name'." ;;
  esac
  PROJECT_NAME="$name"
  PROJECT_DIR="$base/$name"
}

# require_agent <name>: exits unless the name is listed in agents.txt, exact case.
require_agent() {
  case "$1" in
    ""|*/*|*..*|main) die "'$1' is not a valid agent name." ;;
  esac
  if ! list_agents | grep -qx "$1"; then
    die "'$1' is not listed in _scripts/agents.txt (names are case-sensitive). Known agents: $(list_agents | tr '\n' ' ')"
  fi
}

# require_version <name>: version folders are always v1, v2, v3, ...
require_version() {
  case "$1" in
    v[1-9]|v[1-9][0-9]|v[1-9][0-9][0-9]) ;;
    *) die "'$1' is not a version folder name. Versions are v1, v2, v3, ... (never dates or descriptions)." ;;
  esac
}
