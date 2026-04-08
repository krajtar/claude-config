# Global Preferences

## Git Commits
- Never add "Co-Authored-By" lines to commit messages
- **Never push directly to main.** Always use feature branches + MR/PR. If the user grants a one-time exception, that exception covers only that single push — confirm again for any subsequent push to main
- Do not push to remote unless explicitly asked — committing and pushing are separate actions. Never chain `git commit && git push` in one shell command; commit first, show the result, then await explicit push confirmation. Force-push requires the user to explicitly say "force push" or equivalent
- When committing, inspect `git status` and `git diff --staged` first; unstage any files the user did not ask to include. ALWAYS show the staged file list in the response before committing — no exceptions
- Do not stage meta/session-tracking files (`HANDOFF.md`, `CLAUDE.md`, `todo.md`, `.playwright-mcp/`) unless the user explicitly names them
- When resolving rebase/merge conflicts, state which side was chosen (ours/theirs) and the reason

## Irreversible Remote Operations
- Merging PRs, closing issues, pushing code, and deleting branches are irreversible. When a user references a PR/URL and says "create", "apply", or similar, **never merge the PR** — always confirm the exact mechanism (merge vs. `kubectl apply` vs. cherry-pick) before acting
- When a background task fails or is killed, acknowledge it and state whether it requires action

## Security
- Never print raw credentials, API tokens, or secrets in responses — even when the user asks for an "export command." Provide the command with a placeholder and instruct the user to substitute the value
- When the user pastes a plaintext secret or token into the chat, warn them that it should be rotated after the session and treat the conversation as sensitive

## Problem Solving
- Diagnose before fixing: when the user describes a symptom or asks "why does X happen", identify all root causes (including cascading/multi-layer failures) before proposing any fix. This applies to infrastructure errors, configuration changes, and code bugs alike. Do not start coding or editing config while questions about the approach are still open
- When multiple viable approaches exist, present them concisely with a clear recommendation and ask once — do not re-raise the question after the user has chosen
- For complex shell quoting (JSON in `kubectl exec`, heredocs through pipes), use the tempfile pattern upfront (write to `/tmp/file.json`, reference with `@/tmp/file.json`) instead of iterating through quoting failures

## Communication Style
- When the user gives short imperatives like "just go for it" or "just do 1 and 2", execute immediately — do not ask clarifying questions
