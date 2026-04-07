---
name: oneshot
description: Quick implementation — for smaller tasks that don't need a full plan. Clarify, explore, implement, verify in one pass.
model: opus
allowed-tools: Bash, Read, Edit, Write, Grep, Glob, Agent
argument-hint: <task description>
---

Lightweight implementation for tasks that don't warrant a full plan/spec cycle.

## Process

1. **Clarify** the request from `$ARGUMENTS`:
   - What exactly should happen? (expected behavior)
   - What error messages or defaults apply?
   - What validation is needed?
   - What is out of scope?
   If anything is ambiguous, ask the user before proceeding.

2. **Explore** the codebase:
   - Find where the change needs to happen
   - Understand existing patterns (how similar features are built)
   - Identify dependencies and potential side effects
   - Check existing test patterns

3. **Present a brief approach** to the user:
   - Which files will change and why
   - The general approach (1-3 sentences)
   - Wait for user confirmation before coding

4. **Implement**:
   - Follow existing code patterns and conventions
   - Order changes by dependency (if A depends on B, implement B first)
   - Write tests if the codebase has test coverage for similar features

5. **Verify**:
   - Run the build/compile step
   - Run relevant tests
   - Confirm the feature works as described in step 1

## Rules

- **Get confirmation before coding**: Step 3 is a checkpoint — don't skip it
- **Follow existing patterns**: Match the style and architecture of the surrounding code
- **Don't over-engineer**: This is oneshot — solve the stated problem, not hypothetical future ones
- **Verify before claiming done**: Run actual commands to confirm it works
