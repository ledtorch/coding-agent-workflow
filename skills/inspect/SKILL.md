---
name: inspect
description: Deep audit of named components — duplication, dead code, wrong-sized abstractions, logic bugs — ending in severity-labelled findings and a plan doc you approve before any code moves. Use when you want specific files scrutinized rather than a diff reviewed.
---


# Inspect

Audit the **named targets**, label what you find by severity, and produce one plan doc.
**Write no code.**

**Use when:** two components look like they overlap; a file has grown and nobody knows what
is still reachable; a component's logic needs checking before you build on it.
**NOT for:** reviewing a diff (`/code-review`), shrinking one file's prose (`/trim`), or
breaking an already-understood spec into tasks (`/plan` — go straight there).

State the targets and their line counts in one line so the user can interrupt.

## Scope

The named paths, nothing else. No target → ask which files; never guess.

Reading is unrestricted — read anything, anywhere, to *prove* a finding. **Editing is
zero.** `/inspect` never modifies a file, including its targets. One exception: a
`build-<slug>.md` plan the refact plan supersedes is deleted in the same pass —
§Superseding a build plan.

## Step 0: Required reading (blocking)

1. `references/SKILL.md` — route to the docs covering the targets' feature area
2. `references/development/conventions.md` — its numbered rules; half the detections below
   are restatements of them
3. Whatever feature/data doc SKILL.md routes to for each target

A finding that contradicts a reference doc is a finding **about the doc too**. Record both;
the doc is as likely to be wrong as the code.

> **No `references/SKILL.md`?** The reference layer isn't set up here — skip Step 0 and audit
> against the codebase itself. **Say so at the top of the run.** Don't invent a reference doc,
> and don't halt over its absence. [`/setup`](../setup/SKILL.md) builds it, in either mode.

## Step 1: Read every target completely

Whole files, not excerpts. A conclusion drawn from a grep hit is a hypothesis, not a
finding. With more than ~3 targets, fan out one read-only agent per target and keep the
conclusions, not the file dumps — but the reads still have to happen.

## Step 2: Map the neighbourhood

The named targets are where you start, not where the findings are. **A duplicate is by
definition in a file you weren't given** — an audit confined to the targets will confirm
whatever the requester already believed.

Before detecting anything, find every file that shares a surface with a target:

- **Symbols** — who imports from it, and what it imports. Both directions.
- **Values** — every other declaration of the same constant, cap, or vocabulary, including
  copies under a different name.
- **Contracts** — the endpoint it calls, the store it reads, the table it writes, the
  schema constraint behind that table.
- **Siblings** — components serving the same role in a parallel flow. These are where
  near-duplicates live.

Then **state the scope in one line before proceeding** — the targets, the neighbours pulled
in, and why. That is the user's interrupt point. Do not write a plan document to describe
an audit you haven't run; a sentence is enough.

## Step 3: The six detections

### D1 — Duplicated logic
Two functions doing one job. Compare *behavior*, not text: the same formula with different
argument shapes still counts. Name which copy is the better survivor and why.

### D2 — Duplicated values
One constant, cap, or vocabulary declared in N places — the highest-value detection here,
and the one greps miss, because the copies rarely share a name. Count **every** layer:
server, client, schema constraint, prompt, doc. A cap enforced in code but absent from the
schema is a real gap; so is a prompt instructing a model to emit more than the code accepts.
Cross-check the section of `architecture.md` that lists shared code↔data pairs, if it has
one — a pair that belongs there and isn't is itself a finding.

### D3 — Dead code
Exports, components, branches, columns nothing reaches. **Prove it dead** — Step 4's grep
rules.

### D4 — Wrong-sized abstraction
Packaging debt in both directions. Too *little* structure accumulates without anyone
deciding to take it on; too *much* passes every other detection — called, correct, fast —
while taxing every reader who has to trace through it.

**Too little:**
- **A conditional bolted onto an unrelated flow.** A design smell, not a nit — the logic
  wants its own helper, state, or policy rather than a branch in someone else's path.
- **Repeated branching on the same shape.** Signals a missing model or dispatcher. A
  "temporary" branch is usually permanent.
- **Feature logic living in a shared module**, or a bespoke helper standing next to an
  existing canonical one.
- **A silent fallback papering over an unclear invariant.** Making the boundary explicit
  usually makes the surrounding control flow disappear.
- **File size as a signal, not a cap.** A file past ~1000 lines is worth asking about; a
  change that would grow an already-large file is worth decomposing first.

**Too much:**
- **A pass-through wrapper** — a function whose body only forwards to another function.
  Delete it; the call site should name the real thing.
- **A "shared" module with exactly one consumer** — indirection wearing a reuse costume;
  counts per §Extract or inline.
- **A layer that decides nothing** — every method delegates 1:1 to the layer below, so
  the reader opens two files to learn one fact.
- **Speculative generality** — options, modes, or parameters nothing passes. Prove
  "nothing passes it" the same way as dead code (Step 4's grep rules).

### D5 — Logic bugs
Ranked by how often each bites in practice:
- **Swallowed failures** — an error returned as a payload rather than raised, a result
  discarded, a handler that logs success unconditionally
- **Unguarded async actions** — a post-await write to an element that may already be gone,
  or a listener attached without a matching teardown
- **Counter drift** — `±1` where the codebase recomputes from source
- **Shape collisions** — a field that is a string on one path and an object on another
- **State that resurrects** — a cleared draft rewritten by a queued watcher, or a
  save-guard that the reset path forgets to set
- **Caps and boundaries** — off-by-one, `>` vs `>=`, a cap enforced at one layer only
- **Untrusted input used unvalidated** at a system boundary. Flag it and hand the verdict
  to `/security-review`; don't run a security audit inside an inspect.

### D6 — Cost and boundaries
- Queries issued per item where one batched call would do
- Fetches, scans, or loops with no bound — including in-code scans over a table that will
  outgrow their limit
- Work repeated on a hot path that could be computed once
- List endpoints with no pagination

Quantify where you can: "one query per row, ~40 rows per page load" beats "this could be
slow."

### What the target's *kind* obliges
Six detections are generic; these are the contracts a component owes by virtue of what it
is. Check the row that matches each target — a target that skips its row is a finding.

| Target kind                                     | Must hold                                                                                                                                                                                                     |
| ----------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| View or route                                   | Registered, and its name matches the file per the project's routing convention · back navigation and return-to-origin behave as the project's navigation doc says · deep-link entry works                     |
| Store                                           | Registered wherever the project resets user state on sign-out · persisted drafts carry the project's save-guard · storage key follows the project's versioned naming scheme                                   |
| Shared logic module (hook, composable, service) | Its category matches its return shape (data vs behavior), per the conventions · no side effects on import · singletons marked                                                                                 |
| Component                                       | State at the narrowest scope · data reaches it only through the layer the conventions sanction, never an ad-hoc fetch · its name matches the surface it renders on, per the project's naming convention       |
| Endpoint                                        | Follows the project's handler conventions (sync/async, declared response shape) · answers not-found rather than forbidden where existence shouldn't be confirmed · auth resolved the same way as its siblings |
| Schema or migration                             | Every application-enforced rule backed by a constraint, or the asymmetry recorded · pending migrations still pending                                                                                          |

Each check cites the conventions rule behind it, by number, when the project has one.

Dependencies point inward at every kind. A route importing from a service that
imports back is a finding regardless of which row applies.

## Step 4: Evidence — a finding is a claim until proven

Every finding carries `file:line` and a **failure scenario**: concrete inputs or state →
wrong output. "This looks duplicated" is not a finding.

Three proofs are mandatory, because each is a common way an audit goes wrong:

- **Before calling something dead:** grep the symbol repo-wide, including route-lazy
  `() => import()`, star-imports, re-exports, and dynamic attribute access. Then check
  whether anything *imports* it without *calling* it — deleting a symbol whose only
  reference is an unused import still breaks startup.
- **Before trusting a green test suite:** confirm the tests actually reach the code. Delete
  one element of the thing under test and re-run. If the suite stays green, the coverage is
  vacuous, and that gap is the finding.
- **Before repeating a prior doc's claim:** re-derive it from the code. Plan docs go stale
  in the specific direction of understating scope — "declared twice" is worth counting
  yourself.

## Step 5: Judgment — three calls per finding

### Severity
Label every finding. Unlabelled findings get treated as uniformly mandatory, which wastes
the reader's attention on nits.

| Label        | Meaning                                                         |
| ------------ | --------------------------------------------------------------- |
| **Critical** | Data loss, security exposure, or broken behavior shipping today |
| **Required** | Should be fixed before building further on this code            |
| **Consider** | Worth doing; the user decides                                   |
| **Nit**      | Style or preference — safe to ignore                            |
| **FYI**      | Context for later, no action                                    |

**Lead with what matters.** One structural problem and ten nits means the structural
problem *is* the report. A few high-conviction findings beat a long list; padding the count
is a failure, not thoroughness.

### Remedy — propose the move
A finding that only names a problem leaves the reader guessing. Name the restructuring:
collapse duplicate branches into one flow · replace a conditional chain with an explicit
dispatcher · separate orchestration from the logic it orchestrates · move feature logic
into the layer that owns it · reuse the canonical helper · delete a pass-through wrapper ·
split a file into focused modules.

**Then check the remedy actually reduces complexity.** Count the concepts a reader must
hold to follow the code, before and after. If the count is unchanged, the remedy relocates
complexity rather than removing it — prefer the version that makes whole branches, modes,
or layers disappear. Deleting an abstraction beats polishing one.

### Extract or inline
For every duplication finding, count real consumers before proposing a shared home:

- **3+ consumers, or 2 across a package boundary** (route ↔ service, store ↔ view) →
  extract. A boundary crossing counts at two, because the alternative is one layer
  importing from another it shouldn't.
- **Exactly one consumer** → do not extract. A single-caller "shared" module is
  indirection; the fix is to inline it.
- **Two consumers in the same module** → a local helper, not a new file.

State the count. An extraction proposed without one is incomplete.

## Step 6: Output — write the plan, then attack it

**First, in chat:** findings ordered by severity — `file:line`, the failure scenario, the
proposed move, and the consumer count where relevant. Say plainly what you could not
verify and why. Don't soften a real problem into a hedge, and don't rubber-stamp: if the
targets are genuinely sound, report that in one line rather than manufacturing findings.

**Then, one plan doc**, following [plan](../plan/SKILL.md) — its Task Template, its "Small
Enough" definition, its Plan Document Template, and its naming rule
(`references/refact-<slug>.md`).

Three additions specific to `/inspect`:
- Each task cites the finding that motivated it. A task with no finding behind it is scope
  creep.
- Findings needing a product or architecture decision go in **Open Questions**, not the
  task list. They are not tasks until someone answers them.
- The plan doc carries an **`## Outcome`** stub (one line: `Outcome: pending`) — the
  at-a-glance recap filled when the plan ships. Format and rules:
  [plan § Outcome recap](../plan/SKILL.md#outcome-recap).

### Superseding a build plan

When the audited feature still has a `build-<slug>.md` in the tree (the inspect was
pointed at it, or the neighbourhood map surfaced it), the new `refact-<slug>.md`
**replaces** it — two live plan docs for one feature is exactly the two-homes drift this
command exists to catch, and the one left behind WILL get built from twice.

In the same pass that writes the refact plan:

1. **Fold, don't lose.** Every still-unchecked task and load-bearing fact in the build
   doc moves into the refact plan — re-derived against the code first (Step 4), not
   copied on faith; a build-doc task the audit proved already shipped or stale dies
   here instead of migrating.
2. **Delete `build-<slug>.md`.** Git keeps the history; recoverable via
   `git show <sha>:references/build-<slug>.md`.
3. **Sweep every inbound link** — `grep -rn "build-<slug>" references/ src/`:
   SKILL.md's index, doc cross-refs, code comments. Each pointer is re-aimed at the
   refact doc or deleted with its subject. Zero hits before reporting.

`/build` then runs from the single `refact-<slug>.md`.

### Red-team the plan

**Then red-team the plan you just wrote**, before the user sees it. A plan reviewed only by
its author ships its author's blind spots — and the failure mode is specific: the document
written to fix drift introduces its own. Attack it on four lines:

- **Breakage** — for each task, what currently works that this could stop working? Name the
  callers, the surfaces, and the on-disk or deployed state that the task assumes.
- **Consistency** — does each remedy match how this codebase already solves that problem,
  or does it introduce a second way? A new pattern needs a reason stated in the task.
- **Sequencing** — do two tasks touch one file? Then they are ordered, not parallel, and
  the doc must say so.
- **Its own claims** — re-derive every count, every "only caller", every "nothing
  references this". These are what go stale first, including in the plan you wrote minutes
  ago.

Where the red team finds something, fix the plan and say what changed. A red-team pass that
returns nothing on a plan of any size is a pass that wasn't run.

## The gate

Stop at the plan. `/inspect` does not fix what it finds, does not commit, and does not roll
into `/build`. The user reads the findings and decides whether the work is worth doing —
that decision is the whole point of the command.

## Verification

- [ ] Step 0 reading done and listed
- [ ] Every target read in full
- [ ] Neighbourhood mapped and the scope stated before detecting
- [ ] Each target checked against the row its kind obliges
- [ ] Every finding has `file:line`, a failure scenario, a severity label, and a proposed move
- [ ] Every "dead" claim shows its zero-hit grep, including lazy and indirect references
- [ ] Every duplication finding states its consumer count and the extract/inline call
- [ ] Every proposed remedy reduces the concept count, not just its location
- [ ] Coverage claims tested by mutation, not by a passing suite
- [ ] Prior docs' claims re-derived, not repeated
- [ ] Plan doc passes [plan](../plan/SKILL.md)'s own verification list
- [ ] Plan red-teamed on breakage, consistency, sequencing and its own claims
- [ ] Nothing was edited — except a superseded `build-<slug>.md`, deleted with its
      pending tasks folded in and its inbound links swept to zero hits

## See Also

[plan](../plan/SKILL.md) (task and plan-doc templates) · [build](../build/SKILL.md)
(executes one task at a time) · [trim](../trim/SKILL.md) (single-file, prose-only, zero
behavior change) · `conventions.md` (its numbered rules) ·
`/security-review` (owns the security verdict)

**Last Updated**: 2026-10-19
