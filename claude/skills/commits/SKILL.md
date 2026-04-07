---
name: commits
description: Analyze staged changes and generate a Conventional Commits message, then commit. Does NOT push.
model: haiku
allowed-tools: Bash, Read
argument-hint: [optional: scope or extra context for the commit message]
---

Generate a Conventional Commits message from the current diff and commit. Never push.

## Process

1. **Inspect changes**:
   ```bash
   git status
   git diff --staged
   ```
   If nothing is staged, check `git diff` and suggest what to stage. Do NOT auto-stage everything.

2. **Analyze the diff** and determine:
   - **Type**: What kind of change is this?
   - **Scope**: Which module/area is affected? (use `$ARGUMENTS` if provided)
   - **Summary**: One-line description of what changed and why

3. **Commit types** (Conventional Commits):
   - `feat`: New feature or capability
   - `fix`: Bug fix
   - `refactor`: Code restructuring without behavior change
   - `docs`: Documentation only
   - `test`: Adding or updating tests
   - `chore`: Build, CI, deps, tooling
   - `perf`: Performance improvement
   - `style`: Formatting, whitespace (no logic change)
   - `ci`: CI/CD pipeline changes

4. **Format**: `type(scope): summary`
   - Summary: imperative mood, lowercase, no period, under 72 chars
   - Add a body (blank line + details) only if the "why" isn't obvious from the summary
   - If there's a breaking change: add `!` after scope — `feat(api)!: remove v1 endpoints`

5. **Show the staged file list and proposed message** to the user, then commit:
   ```bash
   git commit -m "type(scope): summary"
   ```

## Rules

- Do NOT push. Committing and pushing are separate actions.
- Do NOT add a Co-Authored-By line.
- Do NOT stage files the user didn't ask to include.
- Do NOT stage meta files (HANDOFF.md, CLAUDE.md, todo.md) unless explicitly asked.
