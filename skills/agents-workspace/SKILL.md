---
name: agents-workspace
description: Day-to-day rules and commands for the multi-agent workspace (Projects/<project>/main/ plus <Agent>/v1, v2... folders, published with _scripts/publish-version.sh). Use whenever you start, continue, hand off, publish, retrofit, deploy or check a project inside a folder that has AGENTS.md and _scripts/publish-version.sh at its root, and when asked to "start a new version", "publish to main", "hand this off", "retrofit this project" or "check the workspace".
---

# Working in the multi-agent workspace

## Find the workspace root and your name

```bash
ROOT="$(d="$PWD"; while [ "$d" != / ] && [ ! -f "$d/_scripts/publish-version.sh" ]; do d="$(dirname "$d")"; done; echo "$d")"
cat "$ROOT/_scripts/agents.txt"
```

Your agent name is your own line in `agents.txt`, exact case (`Claude`, `Codex`, `Gemini`, `Grok`). Every command below uses it as `<Agent>`. If `ROOT` printed `/`, you are not inside a workspace: ask the user where it is.

## Start or continue work on a project

1. If the project does not exist yet:
   ```bash
   "$ROOT/_scripts/new-project.sh" <project>
   ```
   Name it for what it is (`landing-page`), never a date.
2. If `Projects/<project>/` exists but has no `main/` folder, it is flat: follow `references/retrofit.md` before touching anything.
3. Start your working copy from the current `main/`:
   ```bash
   "$ROOT/_scripts/new-version.sh" <project> <Agent>
   ```
   It prints the folder to work in (`Projects/<project>/<Agent>/vN`). Do this at the start of every new piece of work, even if you have an earlier version folder: another agent may have published since.
4. If the new folder contains `BRIEF.md` or `FEEDBACK.md`, read both before doing anything else, and read `LAST-EDITED-BY.md` in the project folder to see who published last.

## While working

- Create and change files only inside your own `Projects/<project>/<Agent>/vN/`. Read `main/` and other agents' folders freely; never write to them.
- Save every file you produce there too: scratch renders, screenshots, downloads, generated images. When a tool saves to its own default folder (for example `~/.codex/generated_images/`), copy the file into your version folder right away.
- Never create a folder named after a date, a timestamp or a chat title, and never create `work/` + `outputs/` session folders. Version folders are `v1`, `v2`, `v3` only.
- One-off work that belongs to no project goes in `"$ROOT/Tasks/<Agent>/<task-name>/"`, named for what the task is.
- Keep `BRIEF.md` (what you started from, what the user wants, your decisions and assumptions kept apart from the user's requirements) and `FEEDBACK.md` (dated user feedback, what it applies to, action taken, status) in your version folder. Details: `references/handoff.md`.

## Publish

1. Preview exactly what will change or be deleted in `main/`:
   ```bash
   "$ROOT/_scripts/publish-version.sh" --dry-run <project> <Agent> vN
   ```
   If the preview deletes files you did not mean to remove, another agent published after you started. Run `new-version.sh` again, redo your change on top of the new copy, and preview again.
2. Publish:
   ```bash
   "$ROOT/_scripts/publish-version.sh" <project> <Agent> vN
   ```
   Never edit `main/` or `LAST-EDITED-BY.md` any other way.

## Hand off

Before you stop: add the current deliverable, open assumptions and next steps to `BRIEF.md`, put "Read BRIEF.md and FEEDBACK.md first" at the top of the version's `README.md`, publish, and tell the user which version is now in `main/`.

## Install or deploy

Build, install and deploy anything persistent (an app, a site, a service, a background job) from `Projects/<project>/main/`, never from a version folder:

1. Publish your version.
2. In `main/`, run the project's fresh install and build (`npm install`, `pip install -r requirements.txt`, ...). Build artifacts are never published, so `main/` starts without them.
3. Find and stop any instance still running from an old location (`ps aux | grep <name>`) before relying on the new one.
4. Deploy or install from `main/`.

## Check the workspace

```bash
"$ROOT/_scripts/check-workspace.sh"            # everything
"$ROOT/_scripts/check-workspace.sh" <project>  # one project
```

Run it after a retrofit, after publishing, and whenever something looks off. Fix what it reports, or tell the user when the fix needs their decision (for example moving files out of a dated folder).

## Moving or renaming folders

Never move or rename a folder in the workspace yourself. Agent apps bind chat history to folder paths, and a move breaks it silently. Tell the user what you would move and why, and point them to the "Moving or renaming a folder" section of `"$ROOT/AGENTS.md"`.
