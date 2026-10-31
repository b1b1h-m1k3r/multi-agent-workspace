#!/bin/bash
# Install (or update) a multi-agent workspace.
#
# Usage:
#   ./install.sh [--agents "Claude Codex Gemini Grok"] [--link] [<workspace-path>]
#
# Examples:
#   ./install.sh                                    # ~/agents-workspace, all four agents
#   ./install.sh --agents "Claude Codex" ~/work/agents
#   ./install.sh --link ~/agents-workspace          # also link skills and instructions into your tools
#
# Safe to re-run. It never overwrites a file you may have edited: when your copy differs
# from the template it writes the template next to it as <file>.new and tells you.
# Scripts in _scripts/ (*.sh) are always updated to the latest version.
#
# --link touches your home config folders, non-destructively:
#   - links each skill into ~/.claude/skills, ~/.codex/skills and ~/.gemini/config/skills
#     (only for tools that are installed; an existing real folder is left alone)
#   - links an agent's global instructions file only where none exists yet; otherwise it
#     prints the one line to add to your existing file

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="$REPO/template"
AGENTS_ARG=""
LINK=0
WS=""

while [ $# -gt 0 ]; do
  case "$1" in
    --agents) AGENTS_ARG="${2:-}"; shift 2 ;;
    --link) LINK=1; shift ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    -*) echo "Unknown option: $1"; exit 1 ;;
    *) WS="$1"; shift ;;
  esac
done

WS="${WS:-$HOME/agents-workspace}"
mkdir -p "$WS"
WS="$(cd "$WS" && pwd)"

case "$WS" in
  "$REPO"|"$REPO"/*) echo "ERROR: install the workspace outside this repo clone."; exit 1 ;;
esac

command -v rsync >/dev/null 2>&1 || { echo "ERROR: rsync is required."; exit 1; }

NOTES=()
note() { NOTES+=("$1"); }

# copy_if_safe <src> <dest>: copy when dest is missing; write dest.new when it differs.
copy_if_safe() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ ! -e "$dest" ]; then
    cp "$src" "$dest"
  elif ! cmp -s "$src" "$dest"; then
    cp "$src" "$dest.new"
    note "Kept your ${dest#$WS/}; the template version is in ${dest#$WS/}.new"
  fi
}

# render <template> <dest> <agent>: fill {{WORKSPACE}} and {{AGENT}}, then copy_if_safe.
render() {
  local tmp
  tmp="$(mktemp "$WS/.render.XXXXXX")"
  sed -e "s|{{WORKSPACE}}|$WS|g" -e "s|{{AGENT}}|$3|g" "$1" > "$tmp"
  copy_if_safe "$tmp" "$2"
  rm -f "$tmp"
}

echo "Installing the multi-agent workspace into: $WS"

# 1. House rules
copy_if_safe "$TEMPLATE/AGENTS.md" "$WS/AGENTS.md"
copy_if_safe "$TEMPLATE/CLAUDE.md" "$WS/CLAUDE.md"

# 2. Scripts (always current) and their config (never overwritten)
mkdir -p "$WS/_scripts"
cp "$TEMPLATE/_scripts/"*.sh "$WS/_scripts/"
chmod +x "$WS/_scripts/"*.sh
copy_if_safe "$TEMPLATE/_scripts/publish-excludes.txt" "$WS/_scripts/publish-excludes.txt"
copy_if_safe "$TEMPLATE/_scripts/collections.txt" "$WS/_scripts/collections.txt"

if [ -n "$AGENTS_ARG" ]; then
  printf '%s\n' $AGENTS_ARG > "$WS/_scripts/agents.txt"
elif [ ! -f "$WS/_scripts/agents.txt" ]; then
  printf '%s\n' Claude Codex Gemini Grok > "$WS/_scripts/agents.txt"
fi
AGENTS="$(grep -v '^[[:space:]]*#' "$WS/_scripts/agents.txt" | sed 's/[[:space:]]*$//' | grep -v '^$')"

# 3. Folders
mkdir -p "$WS/Projects"
copy_if_safe "$TEMPLATE/Projects/README.md" "$WS/Projects/README.md"
copy_if_safe "$TEMPLATE/Tasks/README.md" "$WS/Tasks/README.md"
while IFS= read -r agent; do
  mkdir -p "$WS/Tasks/$agent" "$WS/Agent Setup/memory/$(echo "$agent" | tr '[:upper:]' '[:lower:]')"
done <<< "$AGENTS"

# 4. Agent Setup: readmes, per-agent instructions, skills
for f in README.md knowledge/README.md memory/shared/README.md "External Skills/README.md" automations/README.md; do
  copy_if_safe "$TEMPLATE/Agent Setup/$f" "$WS/Agent Setup/$f"
done

while IFS= read -r agent; do
  lower="$(echo "$agent" | tr '[:upper:]' '[:lower:]')"
  tdir="$TEMPLATE/Agent Setup/instructions/$lower"
  if [ -d "$tdir" ]; then
    for f in "$tdir"/*.md; do
      render "$f" "$WS/Agent Setup/instructions/$lower/$(basename "$f")" "$agent"
    done
  else
    render "$TEMPLATE/Agent Setup/instructions/_generic.md" "$WS/Agent Setup/instructions/$lower/AGENTS.md" "$agent"
  fi
done <<< "$AGENTS"

mkdir -p "$WS/Agent Setup/skills"
for s in "$REPO/skills"/*/; do
  name="$(basename "$s")"
  rsync -a --delete "$s" "$WS/Agent Setup/skills/$name/"
done

# 5. Optional: link skills and instructions into the tools
resolve() { (cd -P "$1" 2>/dev/null && pwd) || true; }

link_skills_into() {
  local tooldir="$1" toolhome="$2" src name target
  [ -d "$toolhome" ] || return 0
  mkdir -p "$tooldir"
  if [ "$(resolve "$tooldir")" = "$(resolve "$WS/Agent Setup/skills")" ]; then
    echo "  $tooldir already is the workspace skills folder"
    return 0
  fi
  for src in "$WS/Agent Setup/skills"/*/; do
    name="$(basename "$src")"
    target="$tooldir/$name"
    if [ -L "$target" ]; then
      ln -sfn "${src%/}" "$target"
    elif [ -e "$target" ]; then
      note "Skipped $target: a real folder is there. Remove it if you want the workspace copy linked."
      continue
    else
      ln -s "${src%/}" "$target"
    fi
    echo "  linked $target"
  done
}

link_instructions() {
  local agent="$1" lower src target toolhome
  lower="$(echo "$agent" | tr '[:upper:]' '[:lower:]')"
  case "$lower" in
    claude) toolhome="$HOME/.claude";        target="$HOME/.claude/CLAUDE.md";          src="$WS/Agent Setup/instructions/claude/CLAUDE.md" ;;
    codex)  toolhome="$HOME/.codex";         target="$HOME/.codex/AGENTS.md";           src="$WS/Agent Setup/instructions/codex/AGENTS.md" ;;
    gemini) toolhome="$HOME/.gemini/config"; target="$HOME/.gemini/config/AGENTS.md";   src="$WS/Agent Setup/instructions/gemini/AGENTS.md" ;;
    grok)   toolhome="$HOME/.grok";          target="$HOME/.grok/rules";                src="$WS/Agent Setup/instructions/grok" ;;
    *) note "No known config location for '$agent': point its global instructions at $WS/Agent Setup/instructions/$lower/AGENTS.md by hand."; return 0 ;;
  esac
  [ -d "$toolhome" ] || { note "$agent does not look installed ($toolhome missing); skipped linking its instructions."; return 0; }
  if [ -L "$target" ] && [ "$(readlink "$target")" = "$src" ]; then
    echo "  $target already linked"
  elif [ -e "$target" ] || [ -L "$target" ]; then
    note "$target already exists. Add this line to it: Read and follow $src (multi-agent workspace rules)."
  else
    ln -s "$src" "$target"
    echo "  linked $target"
  fi
}

if [ "$LINK" -eq 1 ]; then
  echo "Linking skills and instructions into your tools:"
  link_skills_into "$HOME/.claude/skills" "$HOME/.claude"
  link_skills_into "$HOME/.codex/skills" "$HOME/.codex"
  link_skills_into "$HOME/.gemini/config/skills" "$HOME/.gemini/config"
  while IFS= read -r agent; do
    link_instructions "$agent"
  done <<< "$AGENTS"
fi

# 6. Report
echo
echo "Installed:"
echo "  $WS/AGENTS.md              house rules every agent reads"
echo "  $WS/_scripts/              publish-version, new-project, new-version, check-workspace"
echo "  $WS/Agent Setup/           instructions, skills, memory"
echo "  $WS/Projects/  $WS/Tasks/"
echo "  Agents: $(echo "$AGENTS" | tr '\n' ' ')"

if [ ${#NOTES[@]} -gt 0 ]; then
  echo
  echo "Notes:"
  for n in "${NOTES[@]}"; do echo "  - $n"; done
fi

if [ "$LINK" -eq 0 ]; then
  echo
  echo "Skills and instructions are not linked into your tools yet. Re-run with --link to do it."
fi

echo
"$WS/_scripts/check-workspace.sh" >/dev/null && echo "Workspace check: OK" || echo "Workspace check reported warnings: run $WS/_scripts/check-workspace.sh"
