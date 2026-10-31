# Multi-Agent Workspace

A folder convention, four small scripts and two agent skills that let several AI agents (Claude Code, Codex, Gemini/Antigravity, Grok, or any other) work on the same projects **without overwriting each other's work**.

No git, no server, no database. Just folders you can inspect in Finder, and one script that is the only way anything becomes "the current version".

```
Projects/coffee-landing/
  main/                <- the current, trusted version. Only the publish script writes here.
  LAST-EDITED-BY.md    <- who published main/, which version, when
  Claude/v1/  v2/      <- Claude's working copies
  Codex/v1/            <- Codex's working copy
  Gemini/v1/           <- empty until Gemini works on it
  Grok/v1/
```

## Set it up in one line

Paste this into Claude Code, Codex, or any agent that can run shell commands:

```text
Set up the multi-agent workspace for me: clone https://github.com/b1b1h-m1k3r/multi-agent-workspace.git, read skills/agents-workspace-setup/SKILL.md in it, and follow it step by step.
```

The agent asks where to put the workspace and which agents you use, installs everything, optionally links the skills into your tools, and runs a health check.

Prefer doing it yourself?

```bash
git clone https://github.com/b1b1h-m1k3r/multi-agent-workspace.git
cd multi-agent-workspace
./install.sh --agents "Claude Codex Gemini Grok" ~/agents-workspace
./install.sh --link ~/agents-workspace     # optional: link skills + instructions into your tools
```

## How it works in 30 seconds

1. **Start**: `_scripts/new-version.sh coffee-landing Codex` copies the current `main/` into `Codex/v1/` (or the next free `vN`).
2. **Work**: the agent edits only its own `Codex/v1/` folder.
3. **Publish**: `_scripts/publish-version.sh coffee-landing Codex v1` mirrors that folder into `main/` and stamps `LAST-EDITED-BY.md`.
4. **Hand off**: the next agent runs `new-version.sh`, gets the latest `main/`, reads `BRIEF.md` and `FEEDBACK.md`, and continues.
5. **Deploy** anything that runs (a site, an app, a service) from `main/`, never from a working copy.

Everything else is guard rails: a dry run before publishing, refusing misspelled agent names, refusing dated folder names, and a read-only checker that catches hand-edits to `main/`, flat projects and stray dated or chat-named folders.

## What's in this repo

| Path | What it is |
|---|---|
| [`install.sh`](install.sh) | Creates or updates a workspace. Safe to re-run; never overwrites your edits. |
| [`template/AGENTS.md`](template/AGENTS.md) | The house rules every agent reads. Copied to the workspace root. |
| [`template/_scripts/`](template/_scripts/) | `publish-version.sh`, `new-project.sh`, `new-version.sh`, `check-workspace.sh` and their config files. |
| [`template/Agent Setup/`](template/Agent%20Setup/) | One place for every agent's global instructions, skills and memory, linked from each tool's home folder. |
| [`skills/agents-workspace-setup/`](skills/agents-workspace-setup/SKILL.md) | The skill the one-line prompt points to: installs and verifies the workspace. |
| [`skills/agents-workspace/`](skills/agents-workspace/SKILL.md) | The day-to-day skill: start, publish, hand off, retrofit, deploy, check. |
| [`examples/workspace/`](examples/workspace/) | A real workspace after Claude, then Codex, then Claude again worked on one project. |
| [`docs/`](docs/) | The full guide. |

## Docs

- [How it works](docs/how-it-works.md): the model, the lifecycle, and why each rule exists
- [Do's and don'ts](docs/dos-and-donts.md): the short list to give anyone (human or agent)
- [Examples](docs/examples.md): step-by-step walkthroughs with real script output
- [Agent setup](docs/agent-setup.md): how Claude Code, Codex, Gemini and Grok pick up the rules and skills
- [FAQ and troubleshooting](docs/faq.md)

## Requirements

macOS or Linux (Windows through WSL), `bash`, `rsync` and `git`. Nothing to install beyond that.

## License

MIT. See [LICENSE](LICENSE).
