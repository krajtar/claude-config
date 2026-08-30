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
- When the user references a PR or URL and says "create" or "apply", confirm the exact mechanism (merge vs. `kubectl apply` vs. cherry-pick) before acting — never merge the PR on that phrasing
- At the end of any work that produced artifacts (code, config, docs), always commit before finishing — don't leave changes uncommitted for the user to clean up. This is a commit, not a push: the push-to-main and merge confirmation rules above still apply unchanged

## Security
- Never print raw credentials, API tokens, or secrets in responses — even when the user asks for an "export command." Provide the command with a placeholder and instruct the user to substitute the value. This includes tokens embedded in kubeconfig files, service account secrets, and any file the user provides — extract only non-sensitive fields (server URL, CA cert) and write secrets directly to files without echoing values in responses
- Secret-holding files must not be readable by other local users: write them to the session scratchpad directory rather than `/tmp/`, and create them with `chmod 600` (or set `umask 077` first)
- When the user pastes a plaintext secret or token into the chat, warn them that it should be rotated after the session and treat the conversation as sensitive

## Problem Solving
- For "X is broken but Y works" reports, the first action is a `diff` / side-by-side read of the two artifacts, not a fix proposal
- Scope filesystem searches to the current repo; never run unbounded `find` or `grep` across a parent directory containing sibling repos
- Do not spawn deep web/GitHub-search agents without asking first — each unbounded search costs significant tokens and rarely returns load-bearing info
- When the user asks "what are you doing?", "why?", or any sanity-check question, explain and stop — do not start the next action in the same response. A sanity-check question signals concern; wait for instructions
- When the user corrects an architecture premise ("no, I meant X"), restate the corrected understanding in one sentence before continuing — do not jump straight to a revised plan
- During option discussions, don't produce artifacts meant to *be* the implementation before the user picks an approach. Throwaway prototypes and mockups are fine and often settle a question faster than prose — put them in the scratchpad and label them as disposable
- When multiple viable approaches exist, present them concisely with a clear recommendation and ask once — do not re-raise the question after the user has chosen
- Write multi-line, complex, or secret-containing content to a file and reference it (`@/path/to/file.json`) rather than passing it inline through shell quoting

## Communication Style
- When the user gives short imperatives like "just go for it" or "just do 1 and 2", execute immediately — do not ask clarifying questions
- When the user's message is a question and contains no imperative, answer in text only — wait for an explicit "do it" / "go for it" / "apply" before editing. Do not treat your own proposal as approved
- When a background task fails or is killed, acknowledge it and state whether it requires action

## Skills
- Prefer a matching skill over raw tools — skills encode workflow the user expects. `diagnose` is the one most often skipped: use it whenever the user reports a bug, pastes an error, or asks why something isn't working, even when the cause looks obvious
- `refine` comes before `plan` when the idea is still fuzzy — it sharpens the problem statement; `plan` turns a sharp one into phased steps

## Repository Context
- Read the recent commits (`git log -10 --oneline`) when starting work in a repo not yet touched this session — they show what's actively being worked on and often explain why the current state exists
- Before claiming work is done, run the repo's documented verification steps (project CLAUDE.md or README). If none are documented and none are obvious, ask rather than guessing — and offer to record the answer in the project CLAUDE.md

## Subagents
- **Never spawn a subagent with Fable.** Use Haiku for subagents whose primary job is reading files (e.g., codebase exploration, log scanning); Sonnet (default) for subagents that synthesize or write code; Opus only when a single task remains genuinely very high complexity after attempting to split it
- Subagents have 200k-token contexts, not 1M — size tasks accordingly: one phase or module per agent (~10–15 files ceiling), a fresh agent per phase rather than continuing one whose context is spent, and front-load the prompt with exact file paths and decisions already made
