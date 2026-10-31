#!/bin/bash
# Create a project with the multi-agent structure.
#
# Usage:
#   new-project.sh <project>
#
# Examples:
#   new-project.sh landing-page
#   new-project.sh "Client Sites/acme-landing"   # inside a group folder
#   new-project.sh posts:launch-teaser           # inside a collection (collections.txt)
#
# Creates main/ plus an empty v1/ placeholder for EVERY agent in _scripts/agents.txt,
# so whichever agent picks the project up next finds the structure already complete.
# LAST-EDITED-BY.md is not created here: publish-version.sh writes it on the first publish.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

if [ -z "${1:-}" ]; then
  echo "Usage: new-project.sh <project>"
  echo "Example: new-project.sh landing-page"
  exit 1
fi

resolve_project "$1"
case "$(basename "$PROJECT_NAME")" in
  [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]*) die "project names describe the work (landing-page, q3-report). Never name a folder after a date." ;;
esac
[ -e "$PROJECT_DIR" ] && die "$PROJECT_DIR already exists. If it is a flat project, retrofit it (AGENTS.md)."

mkdir -p "$PROJECT_DIR/main"
echo "Created $PROJECT_DIR"
echo "  main/"
while IFS= read -r agent; do
  mkdir -p "$PROJECT_DIR/$agent/v1"
  echo "  $agent/v1/"
done < <(list_agents)

echo
echo "Next: the agent starting the work builds in its own <Agent>/v1/ folder, then runs"
echo "  _scripts/publish-version.sh $1 <Agent> v1"
