---
name: dev
description: Phase-based development from a plan — executes implementation phase by phase with verification between each phase.
allowed-tools: Bash, Read, Edit, Write, Grep, Glob, Agent
argument-hint: spec=<path-to-plan> [phase=<number>]
---

Execute an implementation plan phase by phase. Verify after each phase before moving on.

## Process

1. **Read the plan** from the path in `$ARGUMENTS` (spec=...), or if no path given, look for a plan in the current conversation context

2. **Identify current phase**:
   - If `phase=N` is specified, start there
   - Otherwise, scan checkboxes — find the first unchecked phase
   - If all phases are complete, report that and stop

3. **For each phase**:

   a. **Announce**: State which phase you're starting and what it involves

   b. **Implement**: Execute the steps in the plan
      - Follow the plan's approach — don't improvise unless you hit a blocker
      - If a step is unclear, stop and ask rather than guessing
      - Use subagents for independent steps within the phase

   c. **Verify** (two checks):
      - **Spec check**: Does the implementation match what the plan specified?
      - **Quality check**: Does the code compile? Do tests pass? Any obvious issues?

   d. **Update checkboxes**: Mark completed steps as `[x]` in the plan file

   e. **Log deviations**: Where the implementation diverged from the plan, append to the plan
      file's `### Deviations` section (create it if absent), one line each:
      `Phase N — <what the plan said> → <what was done>, because <what made the plan wrong>`.
      Log anything that would surprise someone reading only the plan: a different file than
      specified, an extra step the plan missed, an assumption that turned out false, a step that
      proved unnecessary. Nothing to log is a valid outcome — say so rather than inventing entries.

   f. **Report**: Summarize what was done, what was verified, any issues found

4. **Stop between phases**: After completing a phase, report status and ask if you should continue to the next phase — unless the user has asked you to run all phases

## Rules

- **Follow the plan**: The plan was already approved. Don't redesign during implementation
- **Stop on blockers**: If something in the plan doesn't work as expected, stop and report rather than improvising a workaround
- **Verify after each phase**: Never skip verification. A phase isn't done until it's verified
- **Update the plan file**: Check off completed items so progress is tracked
- **Deviations are data, not failures**: Where reality diverged from the plan is the most useful
  thing the next reader can know. Log it plainly — don't quietly conform to a plan that turned
  out to be wrong, and don't hide that you departed from it
