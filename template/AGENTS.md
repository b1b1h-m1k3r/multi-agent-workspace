# Agents Workspace: shared house rules

This folder is the shared parent for several independent AI agents (the names in `_scripts/agents.txt`, by default Claude, Codex, Gemini and Grok). Every agent reads this file before working here. The rules are short, and each one exists because breaking it caused real damage.

```
<workspace>/
  AGENTS.md               <- this file
  CLAUDE.md               <- one line, "@AGENTS.md", so Claude Code loads this file too
  _scripts/
    publish-version.sh    <- the only way to update a project's main/
    new-project.sh        <- creates a project with the full structure
    new-version.sh        <- starts your next working copy from main/
    check-workspace.sh    <- read-only health check
    agents.txt            <- agent names, exact case, one per line
    collections.txt       <- other folders that use the same structure
    publish-excludes.txt  <- build artifacts that are never published
  Agent Setup/            <- every agent's instructions, skills and memory (see below)
  Projects/
    <project>/
      main/               <- canonical current state. Nobody edits this by hand.
      LAST-EDITED-BY.md   <- written by publish-version.sh. Nobody edits this by hand.
      Claude/v1/ v2/ ...  <- Claude's working copies
      Codex/v1/ ...       <- Codex's working copies
      Gemini/v1/ ...      <- Gemini's working copies
      Grok/v1/ ...        <- Grok's working copies
  Tasks/
    <Agent>/<task-name>/  <- one-off work that is not a shared project
```

## Your name

Use your agent name exactly as it appears in `_scripts/agents.txt` (`Claude`, not `claude` or `claude-code`). The scripts refuse any other spelling.

## The rule

Work only inside your own `<Agent>/<version>/` folder for a project.

- Never edit `main/` directly.
- Never edit another agent's folder. Read it freely; change nothing in it.
- When you start new work on a project, run `_scripts/new-version.sh <project> <Agent>`. It copies the current `main/` into your next version folder and prints its path. Never continue in your last version folder without checking: another agent may have published since, and your old copy would silently undo their work when you publish.
- When your work is ready to become the canonical state, run `_scripts/publish-version.sh <project> <Agent> <version>`. It mirrors your version folder into `main/` and stamps `LAST-EDITED-BY.md` with your name, version and time. Add `--dry-run` first to see exactly which files will change or be removed in `main/`.
- Start a new project with `_scripts/new-project.sh <project>`. It creates `main/` and an empty `v1/` placeholder for every agent.

## Naming: no dates, no chat titles

Every folder is named for what it holds.

- Version folders are `v1`, `v2`, `v3` and nothing else.
- Projects and tasks get a short descriptive name (`landing-page`, `q3-pricing-report`).
- Never create a folder named after a date (`2026-10-25/`), a timestamp, or a chat title (`open-this-notion-link/`), and never create `work/` + `outputs/` session folders. If your app gives each chat its own dated output folder by default, do not save there: put the files in the project version folder or task folder they belong to. Dates belong inside files and in `LAST-EDITED-BY.md`, not in folder names.

`_scripts/check-workspace.sh` flags any folder that breaks these rules.

## One-off tasks

Work that is not a shared project goes in `Tasks/<Agent>/<task-name>/`, one folder per task, named by what the task is. If a task grows into something another agent will also work on, promote it: `_scripts/new-project.sh <name>`, then copy the task files into your `<Agent>/v1/` and publish.

## Finding a project that does not have this structure yet

If `Projects/<name>/` exists but is flat (no `main/`, no `<Agent>/<version>/` folders, just the project's files), it predates this convention. Retrofit it before making any further edit:

1. Delete regenerable build artifacts first (`node_modules/`, `dist/`, `.venv/` or your stack's equivalent). They get reinstalled or rebuilt.
2. Create `main/` and a `v1/` folder for every agent in `agents.txt`, including the agents that are not you, so the structure is complete for whoever picks the project up next.
3. Move (not copy) the flat files into your own `<Agent>/v1/`. This is your working copy from now on.
4. Run `_scripts/publish-version.sh <name> <Agent> v1` to establish `main/` and `LAST-EDITED-BY.md`. Never hand-create either.
5. If anything in the project hardcodes its own absolute path (a service that finds a sibling folder, a config file, a launch script), update it to the new path before relying on the project again. A retrofit is a folder move.

For a folder another tool or person may still be using (a collection of posts, for example), copy instead of moving in step 3, and leave the original until you have confirmed nothing points at it.

## Installed and deployed builds always run from main/

Anything that runs somewhere persistent (an installed app, a deployed site or service, a background process, a cron job) is built and installed or deployed from `main/`, never from an agent's working copy. Finish and verify the change in your working copy, publish it, then build and deploy from `main/`.

`<Agent>/<version>/` answers "what am I changing right now" and may be half broken mid-edit. `main/` answers "what is the last known-good state", the one place everyone can trust. Deploying from a working copy makes your unfinished edit live and lets `main/` drift away from what is actually running.

`publish-version.sh` never copies the paths in `_scripts/publish-excludes.txt` (`node_modules`, `dist`, `build`, `.next`, `target`, `.venv`, `__pycache__`, `.git`, ...). So `main/` needs its own fresh install and build (`npm install`, `pip install -r requirements.txt`, ...) before you package or deploy from it.

A background process can outlive whatever started it: quitting or rebuilding the parent app does not necessarily stop it. Before relying on a fresh build from `main/`, find and stop any instance still running from an old location.

## Handoff notes

The next agent has none of your chat history, only the folder. Keep two files in your version folder:

- `BRIEF.md`: what you started from (source files, the previous version), what the user wants, and how you are delivering it. Keep the user's requirements separate from your own decisions and assumptions.
- `FEEDBACK.md`: every piece of user feedback with its date, the user's wording where practical, what it applies to (in plain words, so it makes sense without the chat), the action taken and its status. Keep superseded entries; never silently replace them.

Before you stop, add the current deliverable, open assumptions and next steps to `BRIEF.md`, and put a one-line "read BRIEF.md and FEEDBACK.md first" pointer at the top of the version's `README.md`. `new-version.sh` copies both files forward from `main/`, so the next agent reads them first and keeps them updated. Never record a proposal as approved unless the user approved it.

## Collections outside Projects/

Any other folder of items can use the same structure (for example `Marketing/Social Posts/<post>/` with `main/`, `<Agent>/vN/` and `LAST-EDITED-BY.md`). List it in `_scripts/collections.txt` as `<prefix>=<folder>`, then use `<prefix>:<name>` with every script: `_scripts/publish-version.sh posts:launch-teaser Codex v1`.

## Agent Setup: instructions, skills, memory

Everything that configures an agent lives in `Agent Setup/`, and each tool's home config path is a link into it:

| Folder | Holds |
|---|---|
| `skills/` | every custom skill, shared by all agents |
| `External Skills/` | third-party skill packs kept for reference, not installed |
| `instructions/<agent>/` | each agent's global instructions (linked from the tool's home config) |
| `memory/<agent>/`, `memory/shared/` | per-agent memory, and notes shared across agents |
| `knowledge/` | reference material any agent may read |
| `automations/` | prompts of scheduled or automated agent runs |

Edit these files in `Agent Setup/`, never through a home config folder, and never replace a link in a home config folder with a real file or folder. Create a new skill directly in `Agent Setup/skills/<name>/` so every agent can use it.

## Everything stays in this workspace

Every file an agent creates, including scratch renders, test frames, screenshots, downloaded references and generated images, goes inside this workspace: in your own `<Agent>/<version>/` folder for a project, or in your `Tasks/<Agent>/<task-name>/` folder. Never save work to a temp folder, a scratchpad outside the workspace, or a home config folder. When a tool saves to its own folder by default (Codex saves generated images to `~/.codex/generated_images/`), copy each file into your working folder right away.

## Moving or renaming a folder

Agent apps bind chat history and project state to the exact absolute path of a folder. Moving or renaming a folder breaks that binding, differently for each tool, and often silently.

- Never `mv` or rename a workspace folder casually. Quit the affected desktop apps first, and move it with a script written for that specific move, with a dry run.
- Claude Code keeps sessions in plain JSON/JSONL under `~/.claude/projects/`, so its moves can be scripted.
- Codex keeps path state in plain files too (`~/.codex/config.toml`, `sessions/**/*.jsonl`), but prefer re-adding the workspace through Codex's own UI until a scripted move is verified.
- Antigravity (Gemini) keeps project state in SQLite with binary columns. Move an Antigravity workspace only through its own UI, and never edit its config files while the app is running.

## Why folders instead of git

Work here is sequential: one agent works, publishes, then another picks up. A copy-and-stamp is simpler to inspect (just look in Finder) and never asks an agent to resolve a merge conflict it might get wrong. If the work ever becomes truly concurrent, introduce git per project without restructuring anything.

## Checking the workspace

Run `_scripts/check-workspace.sh` (read-only) after a retrofit, after a handoff, or whenever something looks off. It reports flat projects, missing placeholders, misnamed agent or version folders, date- or chat-named folders, a `main/` that was edited by hand, and build artifacts in `main/`.
