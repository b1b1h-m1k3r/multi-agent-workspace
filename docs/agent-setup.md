# Agent setup

Every agent needs two things: the **house rules** (so it knows the convention) and, ideally, the **skills** (so it knows the exact commands). This page shows how each tool gets both.

The tool-specific paths below are the ones this setup was built and used with. Tools change; if a path does not match your version, check that tool's docs for where it reads global instructions and skills, and point it at the same files.

## How the rules reach each agent

There are two layers, and you want both:

1. **Workspace layer**: `AGENTS.md` at the workspace root (and `CLAUDE.md` containing `@AGENTS.md`, which makes Claude Code import it). Agents opened inside the workspace pick these up from the folder.
2. **Global layer**: each agent's own global instructions contain a short version of the rules with its own name and your workspace path filled in. This catches the cases where an agent is opened somewhere else, or does not read `AGENTS.md` from parent folders.

`install.sh` writes the global layer for each agent into `Agent Setup/instructions/<agent>/`. `install.sh --link` links them into place when the tool has no global instructions file yet; when it does, it prints the one line to add.

| Agent | Global instructions | Skills folder | Notes |
|---|---|---|---|
| Claude Code | `~/.claude/CLAUDE.md` | `~/.claude/skills/<name>/` | Reads `CLAUDE.md` from the working folder and its parents, so the workspace `CLAUDE.md` (`@AGENTS.md`) applies anywhere inside the workspace. |
| Codex | `~/.codex/AGENTS.md` | `~/.codex/skills/<name>/` | Skills are linked one by one next to `.system` (Codex's built-in skills; leave `.system` alone). Generated images go to `~/.codex/generated_images/` by default: the rules tell Codex to copy them into its working folder. |
| Gemini (Antigravity) | `~/.gemini/config/AGENTS.md` | `~/.gemini/config/skills/<name>/` | Never edit `~/.gemini/config/config.json` while the app is running. Move workspaces only through Antigravity's UI. |
| Grok | `~/.grok/rules` (a folder; every `.md` in it loads as a rule) | reads `~/.claude/skills` | `install.sh --link` links `~/.grok/rules` to `Agent Setup/instructions/grok/`, so keep only rule files in that folder. If Grok also reads Claude's files and you do not want that, turn it off in `~/.grok/config.toml`. |
| Any other agent | wherever it reads global rules | wherever it reads skills | Add its name to `_scripts/agents.txt`; `install.sh` renders `Agent Setup/instructions/<name>/AGENTS.md` from a generic template. Point the tool at it. |

## Why `Agent Setup/` instead of editing each tool's folder

Four tools means four copies of every skill and four places to forget an update. With `Agent Setup/`, the real files live once in the workspace and each tool's path is a link:

```
~/.claude/skills/agents-workspace  ->  <workspace>/Agent Setup/skills/agents-workspace
~/.codex/skills/agents-workspace   ->  <workspace>/Agent Setup/skills/agents-workspace
~/.codex/AGENTS.md                 ->  <workspace>/Agent Setup/instructions/codex/AGENTS.md
```

Rules for this layer:

- Edit the real files in `Agent Setup/`, never through a link.
- Never replace a link in a home folder with a real file or folder (the other agents stop seeing your changes, and the next edit goes to the wrong copy).
- Create every new skill in `Agent Setup/skills/<name>/`, then link it (re-running `install.sh --link` links new skills too).
- Third-party skill packs you only want for reference go in `Agent Setup/External Skills/`, which nothing links to.

If you want to go all the way (as the original setup does), you can link a tool's entire skills folder (`~/.claude/skills -> <workspace>/Agent Setup/skills`) instead of individual skills. `install.sh` links per skill because it is safer when you already have skills of your own.

## What `install.sh --link` changes, exactly

- For each of `~/.claude`, `~/.codex`, `~/.gemini/config` that exists: creates its `skills/` folder if missing and adds one link per workspace skill. An existing real folder with the same name is left alone and reported.
- For each agent in `agents.txt` whose tool is installed: links its global instructions file if none exists. If one exists, it changes nothing and prints the line to add.
- Nothing else in your home folder is touched. Re-running it is safe.

## Starting a session

- Open the agent app at the workspace folder, or at a project folder inside it.
- Say what you want in plain words: "start a new version of coffee-landing and add a menu section", "publish it", "hand it off to Codex", "check the workspace".
- The `agents-workspace` skill turns those into the right commands. Without the skill, the agent still has `AGENTS.md`, which names every script.
