#!/bin/bash
# Publish an agent's working version into a project's canonical main/ folder.
# This script is the only thing that ever writes main/ or LAST-EDITED-BY.md.
#
# Usage:
#   publish-version.sh [--dry-run] <project> <agent> <version>
#
# Examples:
#   publish-version.sh landing-page Claude v2
#   publish-version.sh --dry-run landing-page Claude v2   # list what would change, touch nothing
#   publish-version.sh posts:launch-teaser Codex v1        # a project in a collection (collections.txt)
#
# It mirrors <project>/<agent>/<version>/ into <project>/main/ (files that are not in
# the version are removed from main/) and stamps <project>/LAST-EDITED-BY.md.
# Paths listed in _scripts/publish-excludes.txt (node_modules, dist, .git, ...) are never copied.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

DRY=0
if [ "${1:-}" = "--dry-run" ] || [ "${1:-}" = "-n" ]; then
  DRY=1
  shift
fi

if [ -z "${1:-}" ] || [ -z "${2:-}" ] || [ -z "${3:-}" ]; then
  echo "Usage: publish-version.sh [--dry-run] <project> <agent> <version>"
  echo "Example: publish-version.sh landing-page Claude v2"
  exit 1
fi

resolve_project "$1"
AGENT="$2"
VERSION="$3"
require_agent "$AGENT"
require_version "$VERSION"
command -v rsync >/dev/null 2>&1 || die "rsync is required (macOS and most Linux distributions include it)."

SRC="$PROJECT_DIR/$AGENT/$VERSION"
MAIN="$PROJECT_DIR/main"
LOG="$PROJECT_DIR/LAST-EDITED-BY.md"

[ -d "$SRC" ] || die "source folder not found: $SRC"
[ -d "$MAIN" ] || die "main/ not found for '$PROJECT_NAME': $MAIN. Create the project with new-project.sh, or retrofit it (AGENTS.md)."
[ -n "$(ls -A "$SRC")" ] || die "$SRC is empty. Publishing it would wipe main/."

RSYNC_ARGS=(-a --delete --exclude-from="$EXCLUDES")

if [ "$DRY" -eq 1 ]; then
  echo "Dry run: $PROJECT_NAME / $AGENT / $VERSION -> main/ (nothing is changed)"
  CHANGES=$(rsync "${RSYNC_ARGS[@]}" --dry-run --itemize-changes "$SRC/" "$MAIN/" | grep -v '^\.' || true)
  if [ -n "$CHANGES" ]; then
    echo "$CHANGES"
  else
    echo "main/ already matches $AGENT/$VERSION."
  fi
  exit 0
fi

echo "Publishing $PROJECT_NAME / $AGENT / $VERSION -> main/"
rsync "${RSYNC_ARGS[@]}" "$SRC/" "$MAIN/"

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S %Z")
{
  echo "# Last edited by"
  echo ""
  echo "- **Agent:** $AGENT"
  echo "- **Version:** $VERSION"
  echo "- **When:** $TIMESTAMP"
} > "$LOG"

echo "Done."
echo "  main/ now matches: $AGENT/$VERSION"
echo "  $LOG updated"
