---
name: agents-workspace-setup
description: Installs the multi-agent workspace, a shared folder where several AI agents (Claude, Codex, Gemini, Grok, ...) work on the same projects without overwriting each other (Projects/<project>/main/ plus one <Agent>/v1, v2... folder per agent, published with a script). Use when the user asks to set up, install or bootstrap the multi-agent workspace or shared agents folder, or shares the multi-agent-workspace repository link and asks you to follow it.
---

# Set up the multi-agent workspace

## 1. Ask two questions, in one message

1. Where should the workspace live? Suggest `~/agents-workspace`. Any path works, including one with spaces.
2. Which agents will work in it? Suggest `Claude Codex Gemini Grok`. Accept any subset or extra names. Names are case-sensitive and become folder names, so use one capitalized word each.

Wait for both answers before continuing.

## 2. Get the repository

If this SKILL.md is inside a clone of the repository, the repository folder is the one that contains `install.sh` (two levels above this file). Otherwise clone it next to, not inside, the future workspace:

```bash
git clone https://github.com/b1b1h-m1k3r/multi-agent-workspace.git ~/multi-agent-workspace
```

## 3. Install

Run from the repository folder, with the answers from step 1:

```bash
./install.sh --agents "Claude Codex Gemini Grok" "/path/to/workspace"
```

Read the whole output. Pass every line under "Notes:" on to the user. A `.new` file means the user already had that file: show them the difference with `diff "<file>" "<file>.new"` and ask which to keep.

## 4. Link skills and instructions into the tools (ask first)

Linking edits the user's home config folders (`~/.claude`, `~/.codex`, `~/.gemini/config`, `~/.grok`). Ask the user before running it, and say that it never replaces an existing real file or folder. On a yes:

```bash
./install.sh --link --agents "Claude Codex Gemini Grok" "/path/to/workspace"
```

When the output says a global instructions file already exists, offer to add the printed line to that file. Show the user the exact line and the file, and add it only on a yes.

## 5. Verify

```bash
"/path/to/workspace/_scripts/check-workspace.sh"
```

It must end with `0 warning(s)`. Fix anything it reports before you continue.

## 6. Offer a 30-second demo

Ask whether to create a throwaway project so the user can see the layout. On a yes, run these with your own agent name in place of `Claude`:

```bash
cd "/path/to/workspace"
_scripts/new-project.sh hello-world
_scripts/new-version.sh hello-world Claude
echo "Hello from Claude" > Projects/hello-world/Claude/v1/README.md
_scripts/publish-version.sh hello-world Claude v1
_scripts/check-workspace.sh
```

Then show the tree (`find Projects/hello-world | sort`) and offer to delete `Projects/hello-world`. Delete it only on a yes.

## 7. Tell the user how to use it

Give them these points, in your own words:

- Open each agent app at the workspace folder (or a project folder inside it). The rules load from `AGENTS.md` (and `CLAUDE.md` for Claude Code).
- Ask an agent to "start a new version of <project>", "publish it" or "hand it off". The `agents-workspace` skill covers every step.
- Only `publish-version.sh` writes `main/`. Install and deploy from `main/`.
- One-off work goes in `Tasks/<Agent>/<task-name>/`. No dated or chat-named folders anywhere.
- Run `_scripts/check-workspace.sh` whenever something looks off.
- The full guide, examples and do's and don'ts are in the repository's `docs/` folder.
