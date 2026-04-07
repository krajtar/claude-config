---
name: dispatch
description: Dispatch parallel subagents for independent tasks — use when facing 2+ problems that can be solved concurrently.
allowed-tools: Agent, Read, Grep, Glob, Bash
argument-hint: <task description with multiple independent parts>
---

When facing 2+ independent tasks, dispatch one subagent per problem domain for concurrent work instead of solving sequentially.

## When to Use

- Multiple independent bug fixes
- Changes across unrelated modules
- Research + implementation that don't depend on each other
- Any time tasks don't share mutable state or ordering constraints

## Process

1. **Identify independent domains** from `$ARGUMENTS`:
   - Can task A be completed without knowing the result of task B? → Independent
   - Do tasks touch the same files? → Probably dependent, don't parallelize
   - Is there a data dependency (output of A feeds into B)? → Sequential, not parallel

2. **Scope each agent's task** with:
   - **Goal**: What specifically this agent must accomplish
   - **Boundaries**: Which files/directories are in scope
   - **Constraints**: What NOT to touch, any rules to follow
   - **Output**: What the agent should report back (file changes, findings, status)

3. **Dispatch agents** using the Agent tool — one per independent domain

4. **Collect and integrate results**:
   - Check for conflicts (did two agents touch the same file?)
   - Verify combined changes are coherent
   - Report overall status to the user

## Rules

- **Only parallelize truly independent work**: If in doubt, run sequentially
- **Each agent gets a complete prompt**: Don't assume agents share context — give each one everything it needs
- **Conflict resolution**: If agents produce conflicting changes, flag it for the user rather than auto-resolving
