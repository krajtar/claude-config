---
name: plan
description: Feature planning — explore context, clarify requirements, produce a step-by-step implementation plan. No code until the plan is approved. Use when the user asks "how should we approach X", "what's the best way to build Y", "help me design Z", or says they want to think through a feature before coding — not just when they say "plan".
allowed-tools: Read, Grep, Glob, Agent
argument-hint: <feature description or requirements>
---

Design an implementation plan before writing any code. Hard gate: NO code changes until the user approves the plan.

## Process

1. **Understand the request** from `$ARGUMENTS`:
   - What is being asked for?
   - What are the acceptance criteria?
   - What is explicitly out of scope?

   **Sharpness gate**: if you cannot answer those three from what the user gave you plus a quick
   look at the codebase, the problem isn't ready to plan against. Say which parts are unclear and
   offer `/refine` — it interviews the user and produces a sharpened problem statement to plan
   from. Then stop; don't plan around the gap. If the user hands you a `PROBLEM.md` (or says to
   proceed anyway), take its decisions and constraints as settled and move to step 2 without
   reopening them.

2. **Explore the codebase** in parallel (Explore agents, `model: haiku`) to understand:
   - Where similar features exist (patterns to follow)
   - What code will need to change
   - What dependencies and constraints exist
   - What test patterns are in use

3. **Clarify** any ambiguities with the user:
   - Edge cases that need decisions
   - Trade-offs worth surfacing (performance vs. simplicity, etc.)
   - Scope questions ("should this also handle X?")

4. **Present the plan** as a simple markdown checklist:

   ```markdown
   ## Plan: <feature name>

   ### Phase 1: <name>
   - [ ] Step description — `path/to/file.ts`
     - What: brief description of the change
     - Why: reasoning if non-obvious

   ### Phase 2: <name>
   - [ ] ...

   ### Verification
   - [ ] How to verify the feature works end-to-end

   ### Deviations
   <!-- filled in during implementation, not now -->
   ```

   Each step should include:
   - The file(s) to modify or create
   - A brief description of the change
   - Reasoning if the approach isn't obvious

5. **Wait for approval**. Do NOT write any code until the user says to proceed.

## Rules

- **No code until approved**: The plan is the deliverable. Implementation comes after.
- **File paths are required**: Every step must reference specific files. Vague steps like "update the backend" are not acceptable.
- **Order matters**: Steps should be in dependency order (things that other steps depend on come first)
- **Include verification**: The plan must end with how to verify the feature works
