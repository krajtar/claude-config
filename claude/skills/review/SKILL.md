---
name: review
description: Code review — dispatches review agents on current diff, categorizes issues as Critical/Important/Minor. Read-only unless user asks for fixes.
allowed-tools: Read, Grep, Glob, Bash, Agent
argument-hint: [scope:local|pushed|commit] [feature:description] [commit:hash]
---

Review code changes and report issues. Read-only by default — do NOT fix anything unless the user explicitly asks.

## Process

1. **Detect scope** (from `$ARGUMENTS` or auto-detect):
   - `scope:local` → `git diff` (unstaged) + `git diff --staged`
   - `scope:pushed` → `git diff main...HEAD`
   - `scope:commit` → `git diff HEAD~1..HEAD` (or specific `commit:<hash>`)
   - Default: if there are staged/unstaged changes, use local; otherwise use pushed

2. **Read the full diff** and identify changed files

3. **Dispatch review agents** in parallel across the changed files:
   - Each agent reads the changed files in full (not just the diff) for context
   - Each agent focuses on its assigned files

4. **Categorize findings** into:

   **Critical** — Must fix before merge:
   - Bugs: logic errors, off-by-one, null derefs, race conditions
   - Security: injection, auth bypass, secrets in code, unsafe deserialization
   - Data loss: unhandled errors that silently drop data

   **Important** — Should fix, but not blocking:
   - Missing error handling at system boundaries
   - Performance issues (N+1 queries, unbounded loops, missing indexes)
   - API contract violations (breaking changes without versioning)

   **Minor** — Nice to have:
   - Naming clarity, code organization
   - Missing types or incomplete type narrowing
   - Stylistic issues not caught by linters

5. **Report** with:
   - Summary: one sentence on overall change quality
   - Issues grouped by severity, each with `file:line` reference and explanation
   - If no issues found, say so — don't manufacture feedback

## Rules

- **Read-only**: Do NOT modify files unless the user explicitly requests fixes
- **No sycophancy**: If the code is good, say so briefly. If it has problems, say so directly with technical substance. Do not pad feedback with compliments
- **No style nitpicks on unchanged code**: Only review what was actually changed
- **Context matters**: Read surrounding code to understand intent before flagging issues
