# The four kinds of gap

A problem statement is incomplete in four different ways, and each needs a different instrument.
Diagnosing which kind you're facing tells you what to do about it.

## Known knowns — what the user stated

The explicit requirements. These are the easy part, and the trap is treating them as the whole
problem because they're the only part that arrived in writing.

**What to do:** Record them and move on. Do not spend interview time confirming things the user
already said clearly.

## Known unknowns — gaps the user knows they have

"I don't know whether we should store this in Postgres or Redis." The user can name the gap, so
they'll usually volunteer it if given room.

**What to do:** Ask directly, then resolve with the cheapest instrument — read adjacent code,
prototype, or lay out the trade-off and let them choose. These close fast. Get them out of the
way early so interview time goes to the harder kinds.

## Unknown knowns — context they'd recognize but wouldn't think to say

The highest-value category and the one most often missed. Things so obvious to someone inside the
problem that it doesn't occur to them to mention it: the deploy target, that this service is
called from a cron job, that the team already tried the approach you're about to suggest, that
the data is never larger than a few hundred rows.

The signature: once you ask, the answer is immediate and slightly impatient. That impatience is
the signal you found one, not that you wasted a question.

**What to do:**
- Restate the problem *wrongly but plausibly* — a wrong restatement gets corrected instantly,
  and the correction contains the unstated context.
- Ask "what would surprise someone new to this codebase?"
- Ask what's been tried before and what happened.
- Propose a reasonable-but-wrong default and watch whether they flinch: "I'll assume this runs
  synchronously on request."
- Read the surrounding code yourself. Much unstated context is sitting in the repo, and reading
  it is cheaper than asking.

## Unknown unknowns — blind spots neither of you has raised

Nobody in the conversation has thought of it yet. The user cannot ask about these by definition,
so nothing surfaces them unless you go looking on purpose.

**What to do:** This is what the blind-spot pass in step 4 is for.
- Enumerate failure modes: what happens on partial failure, concurrent access, empty input,
  the largest realistic input, a retry?
- Name the decisions their framing has already silently made. "Phrasing it as a queue commits
  you to at-least-once delivery — is that intended?"
- In unfamiliar domains, ask Claude to *teach* first. The user cannot evaluate options in a
  field they don't know; a short explanation of how practitioners think about it converts a
  blind spot into a known unknown they can then have an opinion about.
- Check whether an established pattern exists for this problem class and whether they're
  deliberately departing from it.

The goal is not to eliminate this category — it's to convert as much of it as possible into the
other three, where it can actually be worked on. The rest surfaces during implementation, which
is why `/dev` and `/orchestrate` keep a deviations log.

# The map and the territory

Prompts, problem statements, and plans are the map. The codebase, its constraints, and the real
requirements are the territory. Refinement is the work of narrowing the gap between them.

Two failure modes, and both are live:

**Under-specification** — a vague statement leaves Claude to fill gaps with generic defaults.
The output is competent, conventional, and aimed at a problem nobody has.

**Over-specification** — an exhaustively pinned-down statement forces compliance with decisions
made before anyone knew enough to make them. It blocks the pivot when implementation reveals a
better approach.

Refine until the shape is right and the irreversible decisions are made. Leave the reversible
details open.
