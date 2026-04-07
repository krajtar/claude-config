---
name: verify
description: Verification before claiming completion — requires running a verification command and confirming output matches the claim before saying "done."
allowed-tools: Bash, Read, Grep, Glob
argument-hint: [verification command or description of what to verify]
---

Verify that work is actually done before claiming completion. Never say "done" or "fixed" without fresh evidence.

## Rules

1. **No claim without proof**: Before saying something is complete, fixed, passing, or working — you MUST run a verification command and read the full output.

2. **Fresh evidence only**: Prior test runs, cached results, or "it worked before" do not count. Run the check NOW.

3. **Full output review**: Read the COMPLETE output of verification commands. Do not skim, truncate, or assume success from partial output.

4. **Match claim to evidence**: The verification output must directly confirm the specific claim you're about to make. "Tests pass" means you ran the tests and saw them pass. "Bug is fixed" means you reproduced the original failure and confirmed it no longer occurs.

## Process

1. Identify the right verification command for the claim:
   - Code compiles? → Run the build
   - Tests pass? → Run the tests
   - Bug fixed? → Reproduce the original failure scenario
   - Feature works? → Exercise the feature end-to-end
   - If `$ARGUMENTS` specifies a command, use that

2. Run the command and read ALL output

3. If verification **fails**: Report what failed, diagnose, and fix — do NOT claim completion

4. If verification **passes**: Report the evidence, THEN make the completion claim

## Anti-patterns

- "This should work now" without running anything → FORBIDDEN
- Running tests but not reading the output → FORBIDDEN
- Claiming success from a subset of tests when the full suite was requested → FORBIDDEN
- "I verified earlier in this conversation" → Stale. Run it again
