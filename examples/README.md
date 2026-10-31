# Example workspace

`workspace/` is a real workspace (minus the scripts and `Agent Setup/`), produced by running the scripts in this repo. It shows the state after three handoffs on one project, plus a one-off task:

1. Claude created `coffee-landing` and published `Claude/v1` (a first draft).
2. Codex ran `new-version.sh`, got `main/` in its `Codex/v1/`, added opening hours and styling, published.
3. Claude ran `new-version.sh` again, got `Claude/v2/` seeded from `main/` (with Codex's work), added the address, published.
4. Gemini did a one-off comparison in `Tasks/Gemini/compare-coffee-shop-site-builders/`.

Things to look at:

- `Projects/coffee-landing/LAST-EDITED-BY.md`: Claude, v2.
- `Projects/coffee-landing/main/` equals `Claude/v2/`.
- `main/BRIEF.md` and `main/FEEDBACK.md`: the history both agents kept.
- `Gemini/v1/` and `Grok/v1/`: empty placeholders (the `.gitkeep` files only exist so git keeps the empty folders).
- No dated folders anywhere.

The step-by-step version with real script output is in [`docs/examples.md`](../docs/examples.md).
