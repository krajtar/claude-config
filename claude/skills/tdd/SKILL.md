---
name: tdd
description: Test-Driven Development — enforces RED-GREEN-REFACTOR. No production code without a failing test first.
allowed-tools: Bash, Read, Edit, Write, Grep, Glob
argument-hint: <feature or behavior to implement>
---

Strict TDD: RED → GREEN → REFACTOR. No production code without a failing test first.

## The Cycle

### RED: Write a Failing Test
1. Write the smallest test that describes the next behavior to implement
2. Run the test — it MUST fail. If it passes, your test isn't testing anything new
3. Confirm the failure message is clear and points at the right thing

### GREEN: Make It Pass
1. Write the MINIMUM production code to make the test pass
2. No more, no less — resist the urge to implement ahead of the tests
3. Run the test — it MUST pass now
4. Run the full related test suite — nothing else should have broken

### REFACTOR: Clean Up
1. With tests green, improve the code: remove duplication, clarify names, simplify
2. Run tests after each refactoring change — they must stay green
3. Do NOT add new behavior during refactoring

Then repeat the cycle for the next behavior.

## Iron Laws

- **Wrote production code before the test? Delete it and start over.** No exceptions. The test drives the design.
- **One behavior per cycle**: Each RED-GREEN-REFACTOR iteration adds exactly one behavior
- **Tests must be deterministic**: No flaky tests, no time-dependent assertions, no network calls in unit tests

## Anti-Patterns to Avoid

1. **The Giant Test**: Writing a test that requires 50+ lines of production code to pass. Break it down — each test should need only a few lines of new code.

2. **Testing Implementation**: Tests should assert behavior (what), not implementation (how). Don't test private methods or internal state — test the public interface.

3. **The Skip**: "I'll write the tests after" or "this is too simple to test." If it's too simple to test, it's simple enough to test in 30 seconds.

4. **Green Bar Addiction**: Refactoring while tests are red, or adding features during the refactor phase. Each phase has one job.
