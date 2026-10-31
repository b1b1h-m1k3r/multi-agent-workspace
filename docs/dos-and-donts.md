# Do's and don'ts

The short list. Every "don't" here happened at least once.

## Do

- **Do start every piece of work with `new-version.sh <project> <Agent>`.** It copies the latest `main/` into your next version folder.
- **Do work only inside your own `<Agent>/vN/` folder.** Read other folders freely.
- **Do run `publish-version.sh --dry-run` before publishing.** Read every `*deleting` line.
- **Do publish only with `publish-version.sh`.** It is the one thing allowed to write `main/` and `LAST-EDITED-BY.md`.
- **Do use your agent name exactly as in `_scripts/agents.txt`** (`Claude`, `Codex`, `Gemini`, `Grok`).
- **Do name folders for what they hold:** `coffee-landing`, `q3-pricing-report`, `v1`, `v2`.
- **Do keep `BRIEF.md` and `FEEDBACK.md`** in your version folder, and point to them from `README.md` before you hand off.
- **Do save everything you produce inside the workspace:** your version folder for projects, `Tasks/<Agent>/<task-name>/` for one-offs. Copy files out of a tool's default output folder right away.
- **Do deploy and install from `main/`,** after a fresh install and build there, and stop any old instance first.
- **Do retrofit a flat project before editing it,** with placeholders for every agent, not just yours.
- **Do run `check-workspace.sh`** after a retrofit, a handoff, or whenever something looks off.
- **Do edit agent config in `Agent Setup/`,** the real files, never through the links in your home folder.

## Don't

- **Don't edit `main/` by hand.** Not even a one-line hotfix. Make the fix in a version folder and publish it. (`check-workspace.sh` reports a hand-edited `main/`.)
- **Don't edit another agent's folder.** Copy what you need into your own version instead.
- **Don't keep working in an old version folder** after someone else has published. Publishing it would delete their work from `main/`. Run `new-version.sh` again.
- **Don't hand-edit or hand-create `LAST-EDITED-BY.md`.** It must reflect what the script last did.
- **Don't create dated or chat-named folders.** No `2026-10-25/`, no `20261025-1430/`, no `open-this-notion-link/`, no `work/` + `outputs/` session folders, anywhere. If your app saves each chat to a dated folder by default, save into the project or task folder instead.
- **Don't name versions anything but `vN`.** No `v2-final`, no `2026-10-31`, no `claude-v3`.
- **Don't create `claude/` next to `Claude/`,** or `claude-v1/` instead of `Claude/v1/`. One spelling per agent.
- **Don't deploy from a working copy.** Your half-finished edit goes live and `main/` stops matching what runs.
- **Don't publish build artifacts or rely on them in `main/`.** `node_modules`, `dist`, `.venv` and friends are excluded on purpose; rebuild them.
- **Don't move or rename workspace folders casually.** Agent apps bind chat history to paths and break silently. Quit the apps and use a dedicated script, or the app's own UI.
- **Don't save work to `/tmp`, a scratchpad outside the workspace, or a home config folder.** The next agent will never find it.
- **Don't replace a link in `~/.claude`, `~/.codex`, `~/.gemini` or `~/.grok` with a real file.** The other agents stop seeing your changes.
- **Don't record a proposal as approved** in `BRIEF.md` or `FEEDBACK.md` unless the user actually approved it.

## The two questions to ask before any write

1. Is this path inside my own `<Agent>/vN/` (or my `Tasks/<Agent>/<task>/`)? If not, stop.
2. Is this folder named for what it holds? If its name is a date or a chat title, stop.
