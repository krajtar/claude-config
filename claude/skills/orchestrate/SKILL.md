---
name: orchestrate
description: Feature orchestration via agent teams — the main agent acts as tech lead, delegating scoped tasks to dev/qa/reviewer/explore subagents. Use when the effort is not small (multi-file feature, multi-phase change) or the work is sensitive/complex (migrations, security-adjacent code, cross-cutting refactors). Not for small tasks — use oneshot for those.
allowed-tools: Agent, Read, Grep, Glob, Bash, Write, Edit
argument-hint: <feature description or path to spec>
---

You are the **tech lead** for this feature. You make ALL decisions — architecture, task
breakdown, model choice, tool choice, what gets merged. Subagents execute scoped tasks and
report back; they never make design decisions. If a subagent hits ambiguity or a blocker,
it reports — you decide.

## Process

1. **Understand and plan (lead does this personally)**
   - Read the spec/description from `$ARGUMENTS`. Explore the codebase enough to own the
     design — delegate broad read-only sweeps to Explore agents (Haiku), but read the
     load-bearing files yourself. Never delegate the architectural decision.
   - Write a plan file with phases and checkboxes (like `/plan` output). Get user approval
     before any implementation if the work is sensitive or the approach has open questions.

2. **Pick the workflow** and read it before dispatching any implementation agent:
   - New feature / phased build → read `workflows/feature.md`
   - Sensitive or risky change (auth, migrations, prod config, data handling) → read `workflows/sensitive.md`
   - Independent workstreams that can run concurrently → read `workflows/parallel.md`

3. **Delegate in scoped tasks** (see Task Sizing below). Each agent prompt must contain:
   goal, exact files/directories in scope, constraints (what NOT to touch, conventions to
   follow), decisions already made (agents follow them, not revisit them), and what to
   report back.

4. **Verify and integrate (lead does this personally)**
   - After each phase: run the verification suite yourself, check the diff against the plan,
     update checkboxes. Never take an agent's "done" at face value.
   - Resolve conflicts between agents' changes yourself; don't dispatch an agent to arbitrate.
   - Log deviations in the plan file's `### Deviations` section, one line each:
     `Phase N — <what the plan said> → <what was done>, because <what made the plan wrong>`.
     Require every agent to report deviations as part of its handback — that report is the lead's
     main signal that the plan is drifting, and it is the record the next phase's agent inherits.

## Model Policy (strict) — Haiku first, escalate on evidence

All tiers are the Claude 5.5 family (`haiku` / `sonnet` / `opus` aliases). Always pass `model`
explicitly on every Agent call — an omitted model inherits the lead's (Opus) model.

- **Never spawn a subagent with Fable.** No exceptions.
- **haiku (default for coding)** — exploration, log scanning, and most dev and qa tasks: a
  well-specified phase with named files, an existing pattern to follow, and a runnable check.
  Haiku 5.5 costs ~1/20th of Sonnet, so it is the starting tier, not a fallback.
- **sonnet** — escalate to it when any one holds:
  - the task needs judgment the prompt can't pin down: no existing pattern to copy, or
    design choices left inside the phase;
  - the change crosses module boundaries or touches more than ~8 files;
  - non-trivial algorithmic, concurrency, or state-management logic;
  - security-, auth-, migration-, or data-integrity-adjacent code (see `workflows/sensitive.md`);
  - a Haiku agent failed lead verification twice on the same task.
  Reviewer agents stay on sonnet: they are the quality gate for Haiku-written code.
- **opus** — only when a single task stays very high complexity after attempting to split it,
  or a Sonnet agent failed verification twice on it.

**Escalation ladder.** On a failed verification, first retry at the same tier with a tightened
prompt (the exact failure output, the file:line, the decision it got wrong). If that fails too,
escalate one tier and record it in `### Deviations`. Never skip a tier on the first attempt
unless a sonnet/opus criterion above already applies.

## Task Sizing — budget for ~200k of useful context

The 5.5 models have 1M-token windows, but agent quality degrades long before the limit, and a
subagent may not be granted the full window. Size every task to finish comfortably inside ~200k:

- **One phase or one module per agent.** If describing the task needs the word "and" between
  unrelated deliverables, split it.
- **Rough ceiling per agent: ~10–15 files to read/modify, one coherent unit of change.**
  Bigger than that → split by module or into sequential phases. Smaller, sharper tasks also
  keep work on the Haiku tier.
- **Fresh agent per phase.** Don't continue a long-running agent into new work via
  SendMessage — its context is already spent. Continuation is only for small follow-ups
  ("also fix the lint error you introduced").
- **Front-load context in the prompt** — name the exact files and paste the relevant
  decisions — so the agent doesn't burn its budget rediscovering what you already know.
- **Verification-heavy suites**: if the test suite output is huge, tell the agent to run
  only the targeted subset and let the lead run the full suite between phases.

## Rules

- Subagents follow the plan and the lead's decisions. An agent proposing a redesign is
  reporting a blocker, not making a decision — the lead rules on it.
- The lead never rubber-stamps: verify every phase with real commands before checking it off.
- Stop and consult the user on: scope changes, plan-invalidating discoveries, anything
  destructive or irreversible.
- Track progress in the plan file — check off items as verified, not as reported done.
