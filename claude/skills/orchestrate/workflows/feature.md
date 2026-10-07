# Workflow: Phased Feature Build

Standard workflow for a multi-file feature built from an approved plan.

## Sequence

1. **Recon** (Explore agents, haiku, parallel where independent)
   - Map the touchpoints: where the feature plugs in, existing patterns to follow,
     test layout. Ask for conclusions and `file:line` references, not file dumps.
   - Lead reads the load-bearing files personally before finalizing the phase breakdown.

2. **Per phase, in plan order:**
   a. **dev agent (haiku; sonnet if the phase meets an escalation criterion in the Model
      Policy)** — implement the phase. Prompt includes: the phase's plan
      section verbatim, exact files in scope, conventions/decisions already made, and
      "report files changed + verification output".
   b. **Lead verifies** — run linter/typecheck/tests yourself, diff-review against the
      plan. Failures go back to the *same* dev agent via SendMessage only if the fix is
      small; otherwise a fresh dev agent with a tightened prompt. A second failure on the
      same task escalates the next agent one model tier.
   c. Check off the phase in the plan file.

3. **QA pass** (qa agent, haiku) — after all phases: hunt edge-case coverage gaps,
   extend tests. QA only touches test files. If QA exposes a production bug, the lead
   decides the fix and dispatches a dev agent — QA never patches production code.

4. **Review gate** (reviewer agent, sonnet) — review the full branch diff. Lead triages
   findings: dispatch fixes for Critical/Important, judge Minor ones personally.

5. **Final verification** — lead runs the full suite, summarizes to the user: phases
   completed, files changed, verification results, anything deferred.

## Phase-boundary rules

- A phase isn't done until the lead has verified it with real commands.
- New information that invalidates the plan → stop, update the plan, confirm with the
  user if the scope changed.
- Each phase gets a fresh dev agent — don't stretch one agent across phases.
