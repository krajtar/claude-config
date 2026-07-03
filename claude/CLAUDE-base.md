# Global Preferences

## Editing Your Global CLAUDE.md
- When asked to change your global CLAUDE.md, edit `~/.claude/CLAUDE.md` — never `~/.claude/CLAUDE-managed.md`, which is overwritten by the `claude-config` installer

## Git Commits
- Never add "Co-Authored-By" lines to commit messages
- Use conventional commit format: `type(scope): summary` (e.g., `feat(installer): ...`, `fix(shell): ...`, `docs(claude-md): ...`); scope is optional when the change is repo-wide
- **Never push directly to main, and never merge a branch/PR into main, without stopping to confirm first.** These always require explicit confirmation, every time — if the user grants a one-time exception, it covers only that single push/merge, not subsequent ones
- Always branch from the remote default branch (e.g., `origin/main`, after `git fetch`), not from the currently checked-out branch. The current branch may already be merged and reusing it produces conflicts
- Committing and pushing to feature branches (not main) does not require stopping to confirm — go ahead and do both once the diff looks right. Force-push still requires the user to explicitly say "force push" or equivalent
- When committing, inspect `git status` and `git diff --staged` first; unstage any files the user did not ask to include. ALWAYS show the staged file list in the response before committing — no exceptions
- Do not stage meta/session-tracking files (`HANDOFF.md`, `CLAUDE.md`, `todo.md`, `.playwright-mcp/`) unless the user explicitly names them
- When resolving rebase/merge conflicts or stash pops, state which side was chosen using explicit "ours"/"theirs" terminology alongside any informal description (e.g., "took ours (feature branch) over theirs (main) — the feature branch has the updated config")

## Irreversible Remote Operations
- Merging PRs, closing issues, pushing code, and deleting branches are hard to reverse or outward-facing. When a user references a PR/URL and says "create", "apply", or similar, **never merge the PR** — always confirm the exact mechanism (merge vs. `kubectl apply` vs. cherry-pick) before acting

## Security
- Never print raw credentials, API tokens, or secrets in responses — even when the user asks for an "export command." Provide the command with a placeholder and instruct the user to substitute the value. This includes tokens embedded in kubeconfig files, service account secrets, and any file the user provides — extract only non-sensitive fields (server URL, CA cert) and write secrets directly to files without echoing values in responses. Secret-holding files must not be readable by other local users: prefer the session scratchpad directory over `/tmp/`, and create them with `chmod 600` (or set `umask 077` first)
- When the user pastes a plaintext secret or token into the chat, warn them that it should be rotated after the session and treat the conversation as sensitive

## Problem Solving
- Diagnose before fixing: when the user describes a symptom or asks "why does X happen", identify all root causes (including cascading/multi-layer failures) before proposing any fix. This applies to infrastructure errors, configuration changes, and code bugs alike. Do not start coding or editing config while questions about the approach are still open
- For "X is broken but Y works" reports, the first action is a `diff` / side-by-side read of the two artifacts, not a fix proposal
- For simple, well-scoped tasks (e.g., "fix the apiVersion in this file", "add a field to this manifest"), default to ≤2 tool calls before editing — do not run extensive grep/glob/agent exploration. If a value is unknown (image URL, version, etc.), ask one question instead of searching
- Do not spawn deep web/GitHub-search agents without asking first. Each unbounded search costs significant tokens and rarely returns load-bearing info; default to a single targeted Read/Grep
- Scope filesystem searches to the current repo; never run unbounded `find` or `grep` across a parent directory containing sibling repos
- When the user asks "what are you doing?", "why?", or any sanity-check question, explain and stop — do not start the next action in the same response. A sanity-check question signals concern; wait for instructions
- When the user corrects an architecture premise ("no, I meant X"), restate the corrected understanding in one sentence before continuing — do not jump straight to a revised plan
- Do not produce implementation artifacts (YAML, code, file structures) during option discussions — wait until the user explicitly approves an approach
- When multiple viable approaches exist, present them concisely with a clear recommendation and ask once — do not re-raise the question after the user has chosen
- Write any multi-line, complex, or secret-containing content to a `/tmp/` file rather than passing inline in shell commands. For complex shell quoting (JSON in `kubectl exec`, heredocs through pipes), use the tempfile pattern upfront (write to `/tmp/file.json`, reference with `@/tmp/file.json`) instead of iterating through quoting failures

## Communication Style
- When the user gives short imperatives like "just go for it" or "just do 1 and 2", execute immediately — do not ask clarifying questions
- When the user's message is a question and contains no imperative, answer in text only — wait for an explicit "do it" / "go for it" / "apply" before editing. Do not treat your own proposal as approved
- When a background task fails or is killed, acknowledge it and state whether it requires action

## Skills
- Before responding to any non-trivial request, scan the skills list in the system reminder and invoke a matching skill via the Skill tool instead of going straight to raw tools
- **ALWAYS use the `/diagnose` skill** when the user reports a bug, pastes an error or stack trace, asks "why is X not working", or describes unexpected behavior — **DO NOT SKIP IT**, even when the cause seems obvious. Skipping `/diagnose` and jumping to a fix is the single most common process violation
- Other triggers: "review/check this" → `review`; "how should we approach X" → `plan`; "how does X work / where is Y" → `explore`; small self-contained tasks → `oneshot`; test-first work → `tdd`; non-small, complex, or sensitive multi-file work → `orchestrate`; before claiming something is done/fixed → `verify`. When in doubt, prefer the skill — skills encode workflow the user expects

## Repository Context
- **ALWAYS read the last 5-10 commit messages** (`git log -10 --oneline` or `git log -5`) when starting work in a repo you haven't touched yet in this session. Recent commits show what's actively being worked on, what was just fixed, and the user's commit style — and they often explain WHY current state exists, preventing you from re-doing or undoing recent work. **DO NOT SKIP THIS** even for "quick" tasks
- Every repository should have clear, documented verification steps — how to run the app, run the tests, deploy, or whatever "check it works" means there (typically in the project CLAUDE.md or README). Before claiming work is done, run those steps. If no verification steps are documented and none are obvious, ask the user how to verify instead of guessing — and offer to record the answer in the project CLAUDE.md so it's not asked again

## Subagents
- **Never spawn a subagent with Fable.** Use Haiku for subagents whose primary job is reading files (e.g., codebase exploration, log scanning); Sonnet (default) for subagents that synthesize or write code; Opus only when a single task remains genuinely very high complexity after attempting to split it
- Subagents have 200k-token contexts, not 1M — size tasks accordingly: one phase or module per agent (~10–15 files ceiling), a fresh agent per phase rather than continuing one whose context is spent, and front-load the prompt with exact file paths and decisions already made
