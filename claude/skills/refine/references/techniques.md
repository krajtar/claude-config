# Techniques

Instruments for refinement. Pick by what's blocking, not by working down the list.

| Blocked on | Use |
|---|---|
| Don't know what the user wants | Interview |
| User doesn't know what they don't know | Blind-spot pass, Teach-first |
| Behaviour is hard to describe in prose | Code-as-reference |
| Question is about feel, timing, or layout | Prototype |
| Solution shape is wide open | Brainstorm |
| Need someone else to agree | Pitch |
| About to commit and unsure it's understood | Quiz |

---

## Interview

Claude asks the questions. The ordering principle is **cost of being wrong**, not logical
sequence: ask about the decisions that are expensive to reverse first, and never spend early
questions on things easily changed later.

- Two to four questions per round. More reads as a form and gets answered like one.
- Prefer concrete either/or over open-ended. "Should stale entries be evicted on read or by a
  background sweep?" beats "how should caching work?"
- Offer a default with each question so the user can accept rather than compose an answer.
- Stop when answers stop changing the shape of the problem.

## Blind-spot pass

You name what hasn't come up. Run it once, deliberately, after the interview has established
enough context to make it specific — a generic checklist of concerns is noise.

Productive angles: failure and partial-failure behaviour; concurrency and ordering; the empty
case and the largest realistic case; what happens on retry; operational concerns (who gets paged,
what's observable); decisions the framing has already silently made; whether a standard approach
exists that they're departing from.

Deliver as a short list with a stated view on which items actually matter here. An undifferentiated
list of everything that could go wrong is not a blind-spot pass.

## Teach-first

When the user is working in an unfamiliar domain, explain how the field frames the problem before
asking them to make choices in it. Someone who doesn't know what color grading is cannot answer
questions about color grading — but they can, after a paragraph explaining what the knobs are and
what practitioners argue about.

Keep it to what's decision-relevant. This is not a tutorial; it's the minimum context needed for
the user to hold an opinion.

## Code-as-reference

An existing implementation is a better specification than any description of one. Before writing
prose about desired behaviour, look for something adjacent that already exists — in this repo,
in a dependency, in a project the user names — read it, and ask "like this, with these
differences?"

Record the reference in the problem statement by path. Downstream, `/plan` and `/dev` get a
concrete target instead of an adjective.

## Prototype

For questions prose cannot settle — does this interaction feel right, is this layout readable,
is this fast enough, does this API read well at the call site. Build the smallest thing that
answers the question and nothing more.

Rules: put it in the scratchpad, state clearly that it is disposable and not the implementation,
and throw it away once it has answered its question. A prototype that quietly becomes the
implementation is the failure mode this technique carries.

## Brainstorm

When the solution shape is open, produce two or three genuinely distinct approaches — not one
approach and two strawmen. For each: how it works in a sentence, what it's good at, what it
costs, and what it forecloses.

End with a recommendation. Presenting options without a view pushes work back onto the user that
they came here to offload.

## Pitch

Package the sharpened statement for someone who wasn't in the conversation: what problem, why it
matters, what was decided, what was deliberately not done. Useful when the work needs sign-off,
and useful as a test of the statement itself — a problem statement that can't be explained to an
outsider in a paragraph isn't finished.

## Quiz

Before committing to a direction, Claude asks the *user* questions about the change: what happens
when X, why was Y chosen over Z, where does this break. Cheap, and it reliably finds the places
where apparent agreement was actually ambiguity. Best used right at the handoff to `/plan`, or
before merging work that was largely delegated.
