# Examples

All output below is real, captured from the scripts in this repo. The finished workspace from example 1 is in [`examples/workspace/`](../examples/workspace/).

Commands run from the workspace root. Long absolute paths are shortened to `…`.

## 1. Three handoffs on one project

### Claude starts a project

```console
$ _scripts/new-project.sh coffee-landing
Created …/Projects/coffee-landing
  main/
  Claude/v1/
  Codex/v1/
  Gemini/v1/
  Grok/v1/

$ _scripts/new-version.sh coffee-landing Claude
main/ is empty (nothing published yet), so Claude/v1 starts empty.

Work only in: …/Projects/coffee-landing/Claude/v1
When ready:   _scripts/publish-version.sh coffee-landing Claude v1
```

Claude writes `index.html`, `BRIEF.md`, `FEEDBACK.md` and a `README.md` whose first line is "Read BRIEF.md and FEEDBACK.md first." in `Claude/v1/`, then publishes:

```console
$ _scripts/publish-version.sh coffee-landing Claude v1
Publishing coffee-landing / Claude / v1 -> main/
Done.
  main/ now matches: Claude/v1
  …/Projects/coffee-landing/LAST-EDITED-BY.md updated
```

### Codex picks it up

```console
$ _scripts/new-version.sh coffee-landing Codex
Copied main/ into Codex/v1
```

Codex filled its empty `v1/` placeholder with the current `main/`, read `BRIEF.md`, added opening hours and a `style.css`, logged the user's request in `FEEDBACK.md`, and previewed the publish:

```console
$ _scripts/publish-version.sh --dry-run coffee-landing Codex v1
Dry run: coffee-landing / Codex / v1 -> main/ (nothing is changed)
>f.s..... index.html
>f+++++++ style.css

$ _scripts/publish-version.sh coffee-landing Codex v1
Publishing coffee-landing / Codex / v1 -> main/
Done.
  main/ now matches: Codex/v1
```

(`>f.s.....` = file changed, `>f+++++++` = new file, `*deleting` = removed from `main/`.)

### Claude comes back, and the dry run saves the day

The next day Claude is asked for an address section. It still has `Claude/v1/` from before, so it is tempting to edit that. A dry run shows why that is wrong:

```console
$ _scripts/publish-version.sh --dry-run coffee-landing Claude v1
Dry run: coffee-landing / Claude / v1 -> main/ (nothing is changed)
*deleting style.css
>f.s..... index.html
```

Publishing the old copy would delete Codex's stylesheet and revert its hours. The right move is a new version from `main/`:

```console
$ _scripts/new-version.sh coffee-landing Claude
Copied main/ into Claude/v2

Work only in: …/Projects/coffee-landing/Claude/v2
When ready:   _scripts/publish-version.sh coffee-landing Claude v2
```

Claude adds the address in `v2/`, logs the feedback, publishes `v2`. Result:

```
Projects/coffee-landing/
  LAST-EDITED-BY.md     Agent: Claude, Version: v2
  main/                 BRIEF.md FEEDBACK.md README.md index.html style.css
  Claude/v1/            the first draft (kept, never edited again)
  Claude/v2/            = main/
  Codex/v1/             the hours + styling version
  Gemini/v1/            empty placeholder
  Grok/v1/              empty placeholder
```

`main/FEEDBACK.md` now carries the whole history across both agents:

```markdown
| Date | Feedback (user's words) | Applies to | Interpretation | Action | Status |
|---|---|---|---|---|---|
| 2026-10-30 | "add the opening hours, Mon-Fri 7-18 and Sat 8-14" | hours section | new section under the tagline | added (Codex/v1) | done |
| 2026-10-31 | "people keep asking where we are" | new address section | add address with a map link | added (Claude/v2) | done |
```

## 2. The guard rails

```console
$ _scripts/publish-version.sh coffee-landing claude v1
ERROR: 'claude' is not listed in _scripts/agents.txt (names are case-sensitive). Known agents: Claude Codex Gemini Grok

$ _scripts/publish-version.sh coffee-landing Claude 2026-10-31
ERROR: '2026-10-31' is not a version folder name. Versions are v1, v2, v3, ... (never dates or descriptions).

$ _scripts/publish-version.sh coffee-landing Gemini v1
ERROR: …/Projects/coffee-landing/Gemini/v1 is empty. Publishing it would wipe main/.

$ _scripts/new-project.sh 2026-10-31-notes
ERROR: project names describe the work (landing-page, q3-report). Never name a folder after a date.

$ _scripts/publish-version.sh ../x Claude v1
ERROR: invalid project name '../x'.
```

## 3. Catching mistakes with `check-workspace.sh`

Here the workspace was broken on purpose the way real agents have broken it: a dated chat folder at the root (what one Codex setup did by default), a chat-named folder, a dated folder in `Tasks/`, a dated "version", a hotfix typed straight into `main/`, and a flat project.

```console
$ _scripts/check-workspace.sh
Workspace root
  WARN  2026-10-25/ is a date-named folder. Move its files into the project version or task folder they belong to (by name, never by date).
  WARN  open-this-notion-chat/ looks like an auto-created chat folder (work/ + outputs/). Move its files into the project version or task folder they belong to.
Tasks
  WARN  Tasks/Codex/2026-10-30/ is a date-named folder. Move its files into the project version or task folder they belong to (by name, never by date).
coffee-landing
  WARN  Gemini/2026-10-31/ is not a version folder. Versions are v1, v2, v3, ... (never dates or descriptions).
  WARN  main/ differs from Codex/v1 (main/ was hand-edited, or Codex/v1 changed after publishing)
old-flat-site
  WARN  flat project (no main/). Retrofit it before editing: see AGENTS.md.

2 project(s) checked, 6 warning(s).
```

It changes nothing and exits with status 1 when there are warnings, so you can also run it from a scheduled job.

## 4. Retrofitting a flat project

`Projects/old-flat-site/` held `index.html` and a `node_modules/` folder directly. Following `skills/agents-workspace/references/retrofit.md`:

```bash
cd "$ROOT/Projects/old-flat-site" && rm -rf node_modules dist build .next target .venv __pycache__
mkdir -p .retrofit && find . -mindepth 1 -maxdepth 1 ! -name .retrofit -exec mv {} .retrofit/ \;
mkdir -p main
while IFS= read -r a; do mkdir -p "$a/v1"; done < <(grep -v '^[[:space:]]*#' "$ROOT/_scripts/agents.txt" | grep -v '^[[:space:]]*$')
rmdir "Claude/v1" && mv .retrofit "Claude/v1"
"$ROOT/_scripts/publish-version.sh" old-flat-site Claude v1
```

Result:

```
Projects/old-flat-site/
  Claude/v1/index.html
  Codex/v1/
  Gemini/v1/
  Grok/v1/
  LAST-EDITED-BY.md
  main/index.html
```

## 5. A collection outside `Projects/`

Social posts live in `Marketing/Social Posts/` and should follow the same rules:

```console
$ echo 'posts=Marketing/Social Posts' >> _scripts/collections.txt
$ _scripts/new-project.sh posts:launch-teaser
$ _scripts/new-version.sh posts:launch-teaser Grok
main/ is empty (nothing published yet), so Grok/v1 starts empty.
$ _scripts/publish-version.sh posts:launch-teaser Grok v1
Publishing launch-teaser / Grok / v1 -> main/
Done.
```

## 6. A one-off task

Gemini is asked to compare website builders for the coffee shop. Nobody else will work on it, so it is not a project:

```
Tasks/Gemini/compare-coffee-shop-site-builders/notes.md
```

Named for what it is, not `Tasks/Gemini/2026-10-31/`. If Claude later turns the comparison into a site, it becomes a project with `new-project.sh`.

## 7. Deploying

Codex is asked to put the site live:

1. `publish-version.sh coffee-landing Codex v2` (the change is in `main/` now).
2. In `Projects/coffee-landing/main/`, run the project's install and build steps.
3. Stop anything still serving an older build from a version folder.
4. Deploy from `main/`.

Never point a server, a cron job or an installed app at `Codex/v2/`.
