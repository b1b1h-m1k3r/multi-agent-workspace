#!/bin/bash
# Start a new working copy for an agent, seeded from the project's current main/.
#
# Usage:
#   new-version.sh <project> <agent>
#
# Example:
#   new-version.sh landing-page Codex
#
# - Picks the folder name: an empty placeholder (such as the v1 new-project.sh made) is
#   filled first, otherwise the next number (v2, v3, ...).
# - Copies main/ into it, so work starts from the latest canonical state and never from
#   your own last version, which another agent may have outdated since.
# - Prints the folder to work in.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

if [ -z "${1:-}" ] || [ -z "${2:-}" ]; then
  echo "Usage: new-version.sh <project> <agent>"
  echo "Example: new-version.sh landing-page Codex"
  exit 1
fi

resolve_project "$1"
AGENT="$2"
require_agent "$AGENT"

MAIN="$PROJECT_DIR/main"
[ -d "$MAIN" ] || die "$MAIN not found. Create the project first (new-project.sh), or retrofit it (AGENTS.md)."

AGENT_DIR="$PROJECT_DIR/$AGENT"
mkdir -p "$AGENT_DIR"

LATEST=0
for d in "$AGENT_DIR"/v[0-9]*; do
  [ -d "$d" ] || continue
  n="${d##*/v}"
  case "$n" in *[!0-9]*) continue ;; esac
  if [ "$n" -gt "$LATEST" ]; then LATEST="$n"; fi
done

if [ "$LATEST" -gt 0 ] && [ -z "$(ls -A "$AGENT_DIR/v$LATEST")" ]; then
  VERSION="v$LATEST"
else
  VERSION="v$((LATEST + 1))"
fi

DEST="$AGENT_DIR/$VERSION"
mkdir -p "$DEST"

if [ -z "$(ls -A "$MAIN")" ]; then
  echo "main/ is empty (nothing published yet), so $AGENT/$VERSION starts empty."
else
  rsync -a --exclude '.DS_Store' "$MAIN/" "$DEST/"
  echo "Copied main/ into $AGENT/$VERSION"
fi

echo
echo "Work only in: $DEST"
echo "When ready:   _scripts/publish-version.sh $1 $AGENT $VERSION"
