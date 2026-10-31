#!/bin/bash
# Read-only health check for the multi-agent workspace. Changes nothing.
#
# Usage:
#   check-workspace.sh              # whole workspace
#   check-workspace.sh <project>    # one project (name or prefix:name)
#
# Warns about:
#   - date-named folders (2026-10-25/...) or chat-named folders with work/ and outputs/
#     inside, anywhere at the structure level: workspace root, Projects/, collections,
#     project folders, agent folders, Tasks/
#   - flat projects (no main/), which need a retrofit
#   - agents from agents.txt with no folder, and folders that are not listed agents
#   - version folders not named v1, v2, v3, ...
#   - a non-empty main/ without LAST-EDITED-BY.md
#   - build artifacts inside main/
#   - main/ differing from the version LAST-EDITED-BY.md names (main was hand-edited,
#     or that version changed after it was published)
#
# Exit code: 0 when there are no warnings, 1 otherwise.

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

AGENTS="$(list_agents)"
WARNINGS=0
PROJECTS=0

warn() {
  echo "  WARN  $1"
  WARNINGS=$((WARNINGS + 1))
}

is_dated() {
  case "$1" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]*|[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]*) return 0 ;;
  esac
  return 1
}

# Flags dated folders, and chat-output folders (work/ + outputs/), directly inside $1.
check_no_dated_children() {
  local parent="$1" label="$2" d base
  for d in "$parent"/*/; do
    [ -d "$d" ] || continue
    base="$(basename "$d")"
    if [ "$base" = "main" ] || grep -qx "$base" <<< "$AGENTS"; then
      continue
    fi
    if is_dated "$base"; then
      warn "$label$base/ is a date-named folder. Move its files into the project version or task folder they belong to (by name, never by date)."
    elif [ -d "$d/work" ] && [ -d "$d/outputs" ]; then
      warn "$label$base/ looks like an auto-created chat folder (work/ + outputs/). Move its files into the project version or task folder they belong to."
    fi
  done
}

check_project() {
  local dir="$1" name="$2"
  PROJECTS=$((PROJECTS + 1))
  echo "$name"

  if [ ! -d "$dir/main" ]; then
    warn "flat project (no main/). Retrofit it before editing: see AGENTS.md."
    return
  fi

  check_no_dated_children "$dir" ""

  local agent d base
  while IFS= read -r agent; do
    if [ ! -d "$dir/$agent" ]; then
      warn "no $agent/ folder (create an empty $agent/v1/ placeholder)"
      continue
    fi
    if ! ls -d "$dir/$agent"/v[0-9]* >/dev/null 2>&1; then
      warn "$agent/ has no vN folder"
    fi
    for d in "$dir/$agent"/*/; do
      [ -d "$d" ] || continue
      base="$(basename "$d")"
      case "$base" in
        v[1-9]|v[1-9][0-9]|v[1-9][0-9][0-9]) ;;
        *) warn "$agent/$base/ is not a version folder. Versions are v1, v2, v3, ... (never dates or descriptions)." ;;
      esac
    done
  done <<< "$AGENTS"

  for d in "$dir"/*/; do
    [ -d "$d" ] || continue
    base="$(basename "$d")"
    [ "$base" = "main" ] && continue
    is_dated "$base" && continue
    if ! grep -qx "$base" <<< "$AGENTS"; then
      warn "$base/ is not a listed agent (a typo such as 'claude' for 'Claude', or a flat layout such as claude-v1)"
    fi
  done

  if [ -n "$(ls -A "$dir/main")" ]; then
    if [ ! -f "$dir/LAST-EDITED-BY.md" ]; then
      warn "main/ has files but no LAST-EDITED-BY.md (main/ was not filled by publish-version.sh)"
    else
      local last_agent last_version changes
      last_agent=$(sed -n 's/^- \*\*Agent:\*\* //p' "$dir/LAST-EDITED-BY.md")
      last_version=$(sed -n 's/^- \*\*Version:\*\* //p' "$dir/LAST-EDITED-BY.md")
      if [ -d "$dir/$last_agent/$last_version" ]; then
        changes=$(rsync -a --delete --dry-run --itemize-changes --exclude-from="$EXCLUDES" \
          "$dir/$last_agent/$last_version/" "$dir/main/" | grep -v '^\.' || true)
        if [ -n "$changes" ]; then
          warn "main/ differs from $last_agent/$last_version (main/ was hand-edited, or $last_agent/$last_version changed after publishing)"
        fi
      else
        warn "LAST-EDITED-BY.md names $last_agent/$last_version, which does not exist"
      fi
    fi

    if [ -n "$(find "$dir/main" -maxdepth 2 -type d \( -name node_modules -o -name dist -o -name .next -o -name .venv -o -name __pycache__ \) 2>/dev/null | head -1)" ]; then
      warn "build artifacts in main/ (publish-version.sh never copies them, so something wrote here directly)"
    fi
  fi
}

# check_projects_dir <folder> <label prefix>: every child is a project or a group of projects.
check_projects_dir() {
  local base="$1" prefix="$2" dir name c children group_ok
  check_no_dated_children "$base" "$prefix"
  for dir in "$base"/*/; do
    [ -d "$dir" ] || continue
    name="$(basename "$dir")"
    is_dated "$name" && continue
    if [ -d "$dir/main" ]; then
      check_project "${dir%/}" "$prefix$name"
      continue
    fi
    children=0
    group_ok=1
    for c in "$dir"*/; do
      [ -d "$c" ] || continue
      children=$((children + 1))
      [ -d "$c/main" ] || group_ok=0
    done
    if [ "$children" -gt 0 ] && [ "$group_ok" -eq 1 ]; then
      for c in "$dir"*/; do
        check_project "${c%/}" "$prefix$name/$(basename "$c")"
      done
    else
      check_project "${dir%/}" "$prefix$name"
    fi
  done
}

if [ -n "${1:-}" ]; then
  resolve_project "$1"
  [ -d "$PROJECT_DIR" ] || die "project not found: $PROJECT_DIR"
  check_project "$PROJECT_DIR" "$1"
else
  echo "Workspace root"
  check_no_dated_children "$ROOT" ""

  if [ -d "$ROOT/Tasks" ]; then
    echo "Tasks"
    check_no_dated_children "$ROOT/Tasks" "Tasks/"
    for d in "$ROOT/Tasks"/*/; do
      [ -d "$d" ] || continue
      check_no_dated_children "${d%/}" "Tasks/$(basename "$d")/"
    done
  fi

  if [ -d "$DEFAULT_PROJECTS_DIR" ]; then
    check_projects_dir "$DEFAULT_PROJECTS_DIR" ""
  else
    echo "No Projects folder at $DEFAULT_PROJECTS_DIR"
  fi

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    prefix="${line%%=*}"
    path="${line#*=}"
    if [ -d "$ROOT/$path" ]; then
      check_projects_dir "$ROOT/$path" "$prefix:"
    else
      echo "$prefix:"
      warn "collection folder not found: $path"
    fi
  done < <(list_collections)
fi

echo
echo "$PROJECTS project(s) checked, $WARNINGS warning(s)."
[ "$WARNINGS" -eq 0 ]
