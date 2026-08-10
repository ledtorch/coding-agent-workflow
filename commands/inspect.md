---
description: Deep audit of named components — duplication, dead code, wrong-sized abstractions, logic bugs — ending in severity-labelled findings and a plan doc you approve before any code moves. Use when you want specific files scrutinized rather than a diff reviewed.
allowed-tools: Read, Grep, Glob, Write, Bash(rg:*), Bash(grep:*), Bash(find:*), Bash(ls:*), Bash(git status:*), Bash(git diff:*), Bash(git log:*)
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
zero.** `/inspect` never modifies a file, including its targets. The deliverable is a
document, and the user decides whether any of it gets built. One exception: a
`build-<slug>.md` plan the refact plan supersedes is deleted in the same pass —
§Superseding a build plan.

## Step 0: Required reading (blocking)

1. `references/SKILL.md` — route to the docs covering the targets' feature area
2. `references/development/conventions.md` — Rules 1–9; half the detections below are
   restatements of them
3. Whatever feature/data doc SKILL.md routes to for each target

A finding that contradicts a reference doc is a finding **about the doc too**. Record both;
the doc is as likely to be wrong as the code.

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
an audit you haven't run; a sentence is enough, and it costs nothing to reject.

## Step 3: The six detections

### D1 — Duplicated logic
Two functions doing one job. Compare *behavior*, not text: the same formula with different
argument shapes still counts. Name which copy is the better survivor and why.

### D2 — Duplicated values
One constant, cap, or vocabulary declared in N places — the highest-value detection here,
and the one greps miss, because the copies rarely share a name. Count **every** layer:
server, client, schema constraint, prompt, doc. A cap enforced in code but absent from the
schema is a real gap; so is a prompt instructing a model to emit more than the code accepts.
Cross-check `architecture.md` §9 — a pair that belongs there and isn't is itself a finding.

### D3 — Dead code
Exports, components, branches, columns nothing reaches. **Prove dead, don't infer it** —
see Step 3.

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
- **A "shared" module with exactly one consumer** — indirection wearing a reuse costume.
  §Extract or inline owns the counts; this bullet makes single-consumer modules something
  the audit *hunts*, not something it notices only while judging a fix for another finding.
- **A layer that decides nothing** — every method delegates 1:1 to the layer below, so
  the reader opens two files to learn one fact.
- **Speculative generality** — options, modes, or parameters nothing passes. Prove
  "nothing passes it" the same way as dead code (Step 4's grep rules).

### D5 — Logic bugs
Ranked by what actually bites in this codebase:
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

Quantify where you can: "one query per row, ~40 rows on the profile" beats "this could be
slow."

### What the target's *kind* obliges
Six detections are generic; these are the contracts a component owes by virtue of what it
is. Check the row that matches each target — a target that skips its row is a finding.

| Target kind | Must hold |
|---|---|
| View or route | Route registered and its `name` matches the file · back-stack and origin-return behave (`features/view-return.md`) · deep-link entry works |
| Store | Registered wherever the project resets user state on sign-out · persisted drafts carry the project's save-guard · storage key follows the project's versioned naming scheme |
| Composable | Category matches its return shape — data vs behavior (Rule 4) · no side effects on import · singletons marked |
| Component | State at the narrowest scope (Rule 1) · no direct `fetch` (Rule 3) · overlay prefix matches its surface (Card / Sheet / Modal) |
| Endpoint | Handler is async · response model declared · 404-not-403 posture where the code shouldn't be confirmed · auth resolved the same way as its siblings |
| Schema or migration | Every application-enforced rule backed by a constraint, or the asymmetry recorded · pending migrations still pending |

Dependencies point inward at every kind (Rule 2). A route importing from a service that
imports back is a finding regardless of which row applies.

## Step 4: Evidence — a finding is a claim until proven

Every finding carries `file:line` and a **failure scenario**: concrete inputs or state →
wrong output. "This looks duplicated" is not a finding.

Three proofs are mandatory, because each has burned this repo:

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

| Label | Meaning |
|---|---|
| **Critical** | Data loss, security exposure, or broken behavior shipping today |
| **Required** | Should be fixed before building further on this code |
| **Consider** | Worth doing; the user decides |
| **Nit** | Style or preference — safe to ignore |
| **FYI** | Context for later, no action |

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

**Then, one plan doc**, following `plan.md` — its Task Template, its "Small Enough"
definition, its Plan Document Template, and its naming rule (`references/refact-<slug>.md`,
since fixes and consolidations add no new concept). Do not restate those here.

Three additions specific to `/inspect`:
- Each task cites the finding that motivated it. A task with no finding behind it is scope
  creep.
- Findings needing a product or architecture decision go in **Open Questions**, not the
  task list. They are not tasks until someone answers them.
- The plan doc carries an **`## Outcome`** stub (one line: `Outcome: pending`) — the
  at-a-glance recap filled when the plan ships. Format and rules: §Outcome recap below.

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

`/build` then runs from the single `refact-<slug>.md`. This deletion-and-sweep is the
one edit `/inspect` makes beyond writing its own plan doc — it removes a
source-of-truth conflict, never code.

## Outcome recap

Written in the same pass that flips **Status** to SHIPPED (normally `/build`'s last task),
directly under the Status line, and repeated in that session's chat report. One line:

> **Outcome:** 3 bugs fixed · −75 lines (−120/+45) · merged 2 (fileA+fileB) · removed 1 · created 2

Rules — tiny, precise, no padding:
- **Fixed order:** bugs · lines · files (merged / removed / created). Eyes learn positions.
- **Omit any zero-count axis entirely** — `0 bugs fixed` is noise, absence says it.
- **Lines lead with the net** (sign included), raw `−removed/+added` in parens. Count code
  and tests only; docs and the plan doc itself don't count.
- **"Bugs fixed" = observable wrong behavior corrected** (the plan's `bug fix`-category
  tasks plus incidentals) — refactors and hygiene don't inflate it.
- Derive from `git show --numstat` over the plan's commits, not from memory.

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

## Common rationalizations

| Rationalization | Reality |
|---|---|
| "The tests pass, so it's fine" | Tests prove the paths they reach. Mutate the code; a suite that stays green was never covering it. |
| "The refactor makes it cleaner" | Relocating complexity isn't reducing it. If the reader holds the same number of concepts, nothing improved. |
| "It's only a small addition to this file" | Small diffs still bolt branches onto unrelated flows and push files past a healthy size. Judge the resulting structure, not the diff. |
| "Nothing references it, so it's dead" | Not until the grep covers lazy imports, re-exports, and importers that never call. |
| "The doc says so" | Docs drift. Re-derive the claim from the code before building a finding on it. |

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
- [ ] Plan doc passes `plan.md`'s own verification list
- [ ] Plan red-teamed on breakage, consistency, sequencing and its own claims
- [ ] Nothing was edited — except a superseded `build-<slug>.md`, deleted with its
      pending tasks folded in and its inbound links swept to zero hits

## See Also

`plan.md` (task and plan-doc templates) · `build.md` (executes one task at a time) ·
`trim.md` (single-file, prose-only, zero behavior change) · `conventions.md` (Rules 1–9) ·
`/security-review` (owns the security verdict)

**Last Updated**: 2026-07-26
