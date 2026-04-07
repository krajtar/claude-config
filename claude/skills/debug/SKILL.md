---
name: debug
description: Systematic debugging — root cause analysis before fixing. Investigate, hypothesize, test, then fix with user approval.
allowed-tools: Bash, Read, Grep, Glob, Agent
argument-hint: <bug description, error message, or failing test>
---

Systematic debugging using the scientific method. Diagnose before fixing.

## Phase 1: Investigate

Gather evidence before forming any hypothesis.

1. **Reproduce the bug**: Run the failing command/test and capture the full error output
2. **Read the relevant code**: Follow the stack trace or error path — read the actual source, don't guess
3. **Check recent changes**: `git log --oneline -20` and `git diff HEAD~5` — did something change recently that correlates?
4. **Map the data flow**: Trace the input through the system to where it breaks

Collect all findings before moving on. Do NOT start fixing yet.

## Phase 2: Hypothesize

Based on evidence from Phase 1:

1. List 2-3 candidate root causes, ranked by likelihood
2. For each hypothesis, identify what evidence would confirm or rule it out
3. Be specific: "the null check on line 42 doesn't handle the empty array case" — not "something is wrong with validation"

## Phase 3: Test Hypotheses

For each hypothesis (most likely first):

1. Design a minimal test that would confirm or refute it
2. Run the test — change ONE variable at a time
3. If confirmed → move to Phase 4
4. If refuted → move to next hypothesis

If all hypotheses are refuted, go back to Phase 1 with fresh eyes.

## Phase 4: Fix

**STOP**: Present your diagnosis and proposed fix to the user. Wait for approval before changing code.

Once approved:
1. Make the minimal fix that addresses the root cause
2. Re-run the original failing command to confirm it passes
3. Run related tests to check for regressions

## Rules

- **One variable at a time**: Never change multiple things simultaneously when debugging
- **Read before guessing**: Always read the actual code at the error location — don't theorize from memory
- **If 3+ fix attempts fail**: Step back and question your assumptions about the architecture. You may be fixing a symptom, not the cause
- **No speculative fixes**: "Let's try this and see" without a hypothesis is not debugging — it's guessing
- **Preserve evidence**: Don't clean up logs or revert diagnostic changes until the bug is confirmed fixed
