# Workflow: Sensitive / Risky Change

For work where a mistake is expensive or hard to reverse: auth/security-adjacent code,
schema or data migrations, payment paths, prod configuration, anything touching secrets.

Differences from the standard feature workflow — everything else is the same:

## Tighter gates

0. **Sonnet minimum for dev agents.** Haiku-first does not apply to sensitive phases —
   dev agents start on sonnet. Haiku is still fine for read-only recon and for qa agents
   writing tests against an already-reviewed phase.

1. **Mandatory user approval of the plan** before any implementation, every time — even
   if the approach seems obvious. The plan must name the blast radius: what breaks if
   this is wrong, and how it gets rolled back.

2. **Reviewer after every phase, not just at the end.** Dispatch a reviewer agent
   (sonnet) on each phase's diff before checking the phase off. For very high complexity
   phases (subtle concurrency, crypto-adjacent logic), this is the one place opus is
   justified for review.

3. **Smaller phases.** Sensitive work gets phases sized so each diff is reviewable in
   one sitting — prefer 5 small verified phases over 2 big ones.

4. **Lead writes the riskiest code personally.** The single most dangerous piece
   (the migration statement, the permission check, the crypto call) is not delegated —
   the lead implements it, and a reviewer agent checks it.

## Hard rules

- No irreversible action (dropping columns, deleting data, rotating credentials,
  touching prod) without explicit per-action user confirmation — plan approval does
  not cover these.
- Secrets never appear in agent prompts, agent reports, or the plan file. Reference
  them by location (`env var X`, `secret Y in namespace Z`), never by value.
- If any agent's report mentions unexpected behavior in the sensitive path, halt the
  pipeline and investigate personally before dispatching anything else.
- Rollback procedure must be written in the plan file *before* the phase that needs it
  runs, not after.
