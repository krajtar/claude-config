---
name: refine
description: Interactive problem refinement — sharpen a fuzzy idea into a problem statement worth planning against. Claude interviews you, surfaces what you haven't considered, and prototypes to resolve open questions. Use before /plan when the idea is still vague, when you're working in an unfamiliar domain, or when you can feel that you don't yet know what you're asking for. Not for well-understood problems — go straight to /plan for those.
allowed-tools: Read, Grep, Glob, Bash, Write, Agent
argument-hint: <rough idea, problem, or half-formed requirement>
---

Refine an idea until it is worth planning against. The deliverable is a **sharpened problem
statement**, not an implementation plan.

The work is bottlenecked by how well the problem is stated, and the user cannot state it fully
up front — parts of it they haven't articulated, parts they haven't thought of. Your job is to
surface those, together, through conversation. See `references/unknowns.md` for what kinds of
gaps exist and how each is attacked.

This is a **conversation, not a questionnaire**. Ask a few questions, listen, let the answers
redirect you. Do not dump twenty questions and wait.

## Process

1. **Restate the problem** as you currently understand it — in two or three sentences, including
   what you think the user is *actually* trying to achieve, not just what they asked for. Getting
   this wrong is useful: a wrong restatement is the fastest way to make an unstated assumption
   visible. Ask whether it's right.

2. **Establish position and expertise.** Before interviewing, find out where the user is: is this
   a domain they know well or one they're new to? Are they exploring or committed? Is there
   existing code, or is this greenfield? Their answers change which techniques are worth running
   and how much you should teach versus ask.

3. **Interview.** Ask targeted questions, architectural and irreversible decisions first — the
   ones expensive to change later. Batch two to four at a time, not more. Read
   `references/techniques.md` for how to run this well.

4. **Blind-spot pass.** Name what the user has not considered but probably should: failure modes,
   constraints implied by their stack, decisions their framing has silently already made. Be
   direct — this is the one step where volunteering unrequested concerns is the point. Especially
   valuable when they told you the domain is unfamiliar.

5. **Resolve open questions with the cheapest instrument available**, in this order:
   - **Read existing code** — an existing implementation is a better spec than any description.
     If something in the repo already solves an adjacent problem, read it and ask "like this?"
   - **Prototype** — when a question is about feel, timing, layout, or ergonomics, a throwaway
     prototype answers it and discussion does not. Label it as disposable, put it in the
     scratchpad, and say plainly that it is not the implementation.
   - **Brainstorm alternatives** — when the shape of the solution is open, sketch two or three
     distinct approaches with trade-offs rather than converging on the first one.

6. **Converge.** Write the sharpened problem statement to a file (see Output). Show it, ask what's
   wrong with it, revise. Repeat until the user says it's right.

7. **Hand off.** Offer `/plan` with the problem statement as input. Do not write the plan here.

## Output

Write to `PROBLEM.md` in the repo root, or a path the user names:

```markdown
# Problem: <name>

## What we're actually solving
<the sharpened statement — what and why, not how>

## Decisions made
- <decision> — because <reason>

## Constraints
- <constraint, and where it comes from>

## Explicitly out of scope
- <thing> — <why it's excluded>

## Open questions
- <question> — <who or what resolves it, and when it must be resolved by>

## References
- `path/to/file.ts` — <what this is a reference for>
```

Keep it short. A problem statement that runs longer than a page has usually started becoming a
plan — stop and hand off.

## Rules

- **The user's answers outrank your assumptions.** When they contradict you, drop your version
  immediately and don't relitigate it.
- **Never start implementing.** Prototypes are disposable and labeled as such. Production code
  here is a scope violation.
- **Volunteer concerns in the blind-spot pass, nowhere else.** Outside step 4, follow the user's
  direction rather than steering.
- **Don't interview past the point of usefulness.** When answers stop changing the shape of the
  problem, converge. Over-refinement is its own failure — an over-specified problem statement
  blocks the useful pivots that only become visible during implementation.
- **Record what was rejected and why.** Rejected options in the statement stop the same debate
  from reopening during planning and implementation.
- **Unknowns will still surface later.** This step reduces them; it does not eliminate them.
  Say so when handing off rather than presenting the statement as complete.
