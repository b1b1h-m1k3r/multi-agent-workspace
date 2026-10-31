# FAQ and troubleshooting

**Two agents working at the same time on the same project?**
Don't. The convention assumes one agent at a time per project: work, publish, hand off. Different projects in parallel are fine. If one project truly needs concurrent work, put that project under git.

**I published and Codex's work disappeared from `main/`.**
You published from a stale copy. Nothing is lost: Codex's version is still in `Codex/vN/`. Run `new-version.sh <project> <you>` (it copies the current `main/`, which is your stale publish), copy Codex's missing files back in from `Codex/vN/`, redo your change, dry-run, publish. Next time, always start with `new-version.sh` and read the dry run.

**Someone hotfixed `main/` directly. How do I fix it?**
`check-workspace.sh` reports it as "main/ differs from <Agent>/<version>". Run `new-version.sh` (which captures the hand-edited `main/` into a proper version folder), check the change is wanted, and publish that version. `main/` and `LAST-EDITED-BY.md` are honest again.

**My agent app keeps creating `2026-10-25/<chat-title>/work/` folders.**
Some apps give every chat a dated folder by default. The global instructions forbid it, but the app's default may still win if a chat is not opened in a project folder. Open chats in the project or workspace folder, and if a dated folder appears, move its files into the project version or `Tasks/<Agent>/<task-name>/` folder they belong to (quit that app first if it may still be using the folder), then delete the empty dated folder. `check-workspace.sh` finds them.

**Can I name versions `v2-dark-mode`?**
No. Versions are `v1`, `v2`, `v3`. Put the description in `BRIEF.md`. The scripts reject other names so that "the latest version" is always unambiguous.

**What if I add a fifth agent later?**
Add its name to `_scripts/agents.txt` (or re-run `install.sh --agents "..."`), re-run `install.sh` to render its instructions, and create a `<Name>/v1/` placeholder in existing projects (`check-workspace.sh` tells you which ones are missing it).

**Does it work on Windows?**
Through WSL. The scripts are plain bash and rsync.

**Where do build artifacts go?**
They stay in the version folder where you built them and are never published. `main/` gets a fresh install and build before you deploy from it. Add your stack's folders to `_scripts/publish-excludes.txt`.

**Can I keep a version folder in git, or push it to GitHub?**
Yes. `publish-version.sh` never copies `.git` into `main/`.

**How do I update to a newer version of these scripts?**
`git pull` in your clone, then re-run `./install.sh <workspace>`. Scripts are replaced; any file you edited (AGENTS.md, instructions, config) is kept, and the new template is written next to it as `.new` for you to compare.

**I renamed the workspace folder and now my chats are gone.**
The apps bound them to the old path. Move the folder back to its old name first. Then do the move properly: quit every agent app, move with a script that also updates each tool's stored paths (Claude Code keeps them in plain JSON/JSONL under `~/.claude/projects/`), and re-add the folder through Codex's and Antigravity's own UI. Also update the workspace path inside `Agent Setup/instructions/*` (re-running `install.sh` with the new path writes fresh copies as `.new`).

**`check-workspace.sh` says a folder like `claude/` is not a listed agent.**
Someone used a different spelling. Move its contents into the correctly spelled agent's next version (`new-version.sh`, then copy), and remove the misspelled folder. On macOS the file system ignores case, so `claude/` and `Claude/` are the same folder there; the warning shows up on case-sensitive systems and for variants like `claude-v1/`.
