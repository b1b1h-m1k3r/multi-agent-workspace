# Handoff notes: BRIEF.md and FEEDBACK.md

The next agent gets the folder, not your chat. These two files carry what the chat knew. `new-version.sh` copies them forward from `main/`, so they travel with every version.

## BRIEF.md

Create it in your version folder before producing anything, and update it as the work changes.

```markdown
# Brief: <project>

## Started from
- Previous version: Codex/v2 (published 2026-10-30)
- Source files: logo.svg, copy.md from the user

## What the user wants (requirements)
- One-page landing site for the spring launch
- Must work on phones

## My decisions and assumptions (not approved unless marked)
- Two-column hero on desktop (assumption)
- Green accent from the logo (approved by the user on 2026-10-31)

## Current state
- Deliverable: index.html, rendered preview hero.png
- Open questions: pricing section wording
- Next steps: add the FAQ section
```

## FEEDBACK.md

One entry per piece of feedback. Never delete or rewrite old entries; mark them superseded.

```markdown
| Date | Feedback (user's words) | Applies to | Interpretation | Action | Status |
|---|---|---|---|---|---|
| 2026-10-30 | "headline too long" | hero headline, variant B | cut to under 8 words | shortened to 6 words | done |
| 2026-10-31 | "go back to the old headline" | hero headline, variant B | revert the 2026-10-30 change | restored | done (supersedes row 1) |
```

## Before you stop

1. Update "Current state" in `BRIEF.md`.
2. Put `Read BRIEF.md and FEEDBACK.md first.` as the first line of the version's `README.md`.
3. Publish with `publish-version.sh`.
4. Never write that the user approved something unless they did.
