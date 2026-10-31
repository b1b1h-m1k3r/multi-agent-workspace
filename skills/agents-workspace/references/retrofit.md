# Retrofit a flat project

A project is flat when `Projects/<project>/` holds its files directly, with no `main/` and no `<Agent>/vN/` folders. Retrofit it before any other edit. Replace `<project>` and `<Agent>` throughout.

1. Show the user what is in the folder and what you will do, and wait for a yes:
   ```bash
   ls -la "$ROOT/Projects/<project>"
   ```
2. Delete regenerable build artifacts (only these; ask about anything else that looks generated):
   ```bash
   cd "$ROOT/Projects/<project>" && rm -rf node_modules dist build .next target .venv __pycache__
   ```
3. Create `main/` and a `v1/` placeholder for every agent, then move every remaining file into your own `v1/`:
   ```bash
   cd "$ROOT/Projects/<project>"
   mkdir -p .retrofit && find . -mindepth 1 -maxdepth 1 ! -name .retrofit -exec mv {} .retrofit/ \;
   mkdir -p main
   while IFS= read -r a; do mkdir -p "$a/v1"; done < <(grep -v '^[[:space:]]*#' "$ROOT/_scripts/agents.txt" | grep -v '^[[:space:]]*$')
   rmdir "<Agent>/v1" && mv .retrofit "<Agent>/v1"
   ```
4. Publish to create `main/` and `LAST-EDITED-BY.md`:
   ```bash
   "$ROOT/_scripts/publish-version.sh" <project> <Agent> v1
   ```
5. Search for the old absolute path and update every hit to the new `<Agent>/v1/` path (scripts, configs, launch files, services):
   ```bash
   grep -rn "Projects/<project>/" "$ROOT/Projects/<project>/<Agent>/v1" --exclude-dir=node_modules | grep -v "/<Agent>/v1"
   ```
   If something running (a service, a cron job) still points at the old path, tell the user, rebuild it from `main/` and stop the old instance.
6. Check:
   ```bash
   "$ROOT/_scripts/check-workspace.sh" <project>
   ```

For a folder another person or tool may still be reading, copy instead of moving in step 3 (`cp -R` into `<Agent>/v1/`), and leave the original until the user confirms nothing points at it.
