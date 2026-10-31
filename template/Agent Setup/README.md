# Agent Setup

Every agent's instructions, skills and memory live here. Each tool's home config path is a link into this folder, so the files stay in the workspace and every agent sees the same skills. The folder table is in `../AGENTS.md`, section "Agent Setup: instructions, skills, memory".

| Folder | Holds | Linked from (typical) |
|---|---|---|
| `skills/<name>/` | custom skills, shared by all agents | `~/.claude/skills/<name>`, `~/.codex/skills/<name>`, `~/.gemini/config/skills/<name>` |
| `instructions/claude/CLAUDE.md` | Claude's global instructions | `~/.claude/CLAUDE.md` (or one line in it) |
| `instructions/codex/AGENTS.md` | Codex's global rules | `~/.codex/AGENTS.md` |
| `instructions/gemini/AGENTS.md` | Antigravity's global rules | `~/.gemini/config/AGENTS.md` |
| `instructions/grok/AGENTS.md` | Grok's global rules (every `.md` here loads as a rule) | `~/.grok/rules` |
| `memory/<agent>/`, `memory/shared/` | per-agent memory and shared notes | the tool's memory folder |
| `knowledge/` | reference material any agent reads | nothing |
| `automations/` | prompts of scheduled agent runs | the automation itself |
| `External Skills/` | third-party skill packs kept for reference, not installed | nothing |

Edit files here, never through a home config folder, and never replace one of those links with a real file.
