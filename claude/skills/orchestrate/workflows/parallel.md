# Workflow: Parallel Workstreams

For features that decompose into genuinely independent workstreams — separate modules,
frontend + backend halves behind an agreed interface, or multiple unrelated call sites.

## Independence test — all three must hold, otherwise run sequentially

- Stream A can finish without knowing stream B's result (no data dependency).
- The streams touch disjoint files. Shared files = shared mutable state = sequential.
- Any shared contract (API shape, type definitions, event schema) is **decided and
  written down by the lead before dispatch** — agents implement against it, never
  negotiate it between themselves.

## Sequence

1. **Lead fixes the contracts first.** Write interface definitions / type stubs / API
   shapes into the codebase (or the plan file) so every stream builds against the same
   frozen surface.

2. **Dispatch one dev agent per stream, in parallel** — haiku by default, picking the tier per
   stream with the Model Policy. Each prompt states:
   the stream's scope, the frozen contract verbatim, the explicit list of files the
   *other* streams own (do not touch), and the report format.

3. **Integrate personally.** When streams complete:
   - `git status` / diff check for overlapping file touches — if two agents modified
     the same file, the lead reconciles it; never dispatch an agent to arbitrate.
   - Wire the streams together (the integration seam is lead's code).
   - Run the full verification suite — per-stream tests passing does not mean the
     integrated whole works.

4. **Single QA + review pass on the integrated result**, same as the feature workflow —
   not per stream.

## Sizing cautions

- Parallelism multiplies context spend — 3 streams = 3 agent budgets burning at once.
  Cap at 3–4 concurrent agents; queue the rest.
- A stream too big for one agent doesn't become parallelizable by splitting it
  mid-stream — split it into sequential phases within the stream instead.
- If the independence test is borderline, it failed. Sequential is slower but never
  produces a broken merge.
