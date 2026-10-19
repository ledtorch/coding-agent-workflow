---
name: plan
description: Breaks work into ordered tasks. Use when you have a spec or clear requirements and need to break work into implementable tasks. Use when a task feels too large to start, when you need to estimate scope, or when parallel work is possible.
---


# Planning and Task Breakdown

Decompose work into small, verifiable tasks with explicit acceptance criteria — each small
enough to implement, test, and verify in one focused session.

**Also use when:** scope must be communicated to a human, or implementation order isn't
obvious.
**NOT for:** single-file changes with obvious scope, or specs that already contain
well-defined tasks.

## Step 0: Required Reading (blocking, before any breakdown)

Planning is **read-only** — the output is a plan document, never code.

1. `references/SKILL.md` — doc index; route to every reference relevant to the request.
2. `references/development/conventions.md` — any plan whose tasks touch code must respect it.
3. `references/development/architecture.md` — the layer map and the data contract; a task
   that changes a shared schema changes everything built on it.

Skipping Step 0 is a planning failure — restart here. Docs drift: `grep` any file/route/
flag a doc names before building on it.

> **No `references/SKILL.md`?** The reference layer isn't set up here — skip Step 0 and plan
> from the codebase itself. **Say so at the top of the run.** Don't invent a reference doc,
> and don't halt over its absence. [`/setup`](../setup/SKILL.md) builds it, in either mode.

## Step 1: Break the Request Down

Slice **vertically** — each task delivers one complete, testable path, not one layer:

- **Bad (horizontal):** Task 1 entire schema → Task 2 all endpoints → Task 3 all UI → Task 4 connect.
- **Good (vertical):** Task 1 user can register (schema + API + UI) → Task 2 user can
  log in → Task 3 user can create an item → each slice works and is testable on its own.

Split until every task passes **"Small Enough"** (below).

## Step 2: Define What Each Task Is

Answer **"this task is for what?"** before planning how:

- **Categorize:** bug fix / feature / refactor / data / ops / doc.
- **Define the underlying thing.** "Fix this bug" is not a definition — a bug task states
  observed behavior, expected behavior, and suspected cause. Cause unknown → diagnosis is
  its own first task; the fix is a later task.
- **Expand hidden multiplicity.** One user sentence often hides several tasks: a "bug"
  needing a store + API + UI change is a plan of tasks, not a task. Never compress a
  multi-task problem into one task to keep the list short.

Can't categorize and define it in two sentences → not understood yet; go back to Step 0/1.

## Step 3: Build the Logic Map

Two relations, stated for **every** task:

**Dependencies** — what must exist before what; build bottom-up:

```
Schema (src/<area>/<schema-file>)
    │
    └── Data / API (src/<area>/<data-file>)
            │
            └── Route (src/<area>/<route-file>)
                    │
                    └── Layout (src/<area>/<Layout>)
                            │
                            └── Component (src/<area>/<Component>)
                                    │
                                    └── Design tokens (src/<area>/<tokens-file>)
```

Draw the project's own graph from `architecture.md`; this one only shows the shape.

Not every plan spans all layers — a UI-only task starts mid-graph; whatever layers the
plan touches, build the lower one first.

**Conflicts** — dependency-free tasks can still collide. Check every pair for shared:
file, store/state, API contract, DB table, doc. Shared surface → order them, or pin the
shared contract first.

The logic map is what proves N subtasks won't step on each other. "No dependencies, no
shared surfaces" is a claim — verify it against the codebase, don't assume it.

## Step 4: Schedule — Sequential or Parallel

- **Sequential (default):** dependency chains, shared-state changes, DB migrations, any
  pair with a conflict edge.
- **Parallel** (only when the map proves no conflict): independent vertical slices, tests
  for already-implemented behavior, documentation.
- **Contract-first parallel:** tasks sharing an API/store contract may parallelize only
  AFTER a task pins the contract down.

Order the sequential spine: dependencies satisfied → each task leaves the system in a
working state → high-risk/high-unknown tasks early (fail fast) → checkpoint after every
2–3 tasks (tests pass, build clean, flow works end-to-end, human review before proceeding).

## Step 5: Expectations and Review Checks

Written **before building**, per task:

- **Expectation** — observable behavior that didn't exist before ("user taps X and sees
  Y"), not implementation ("add function Z").
- **Acceptance criteria** — ≤3 specific, testable conditions.
- **Review check** — how the builder verifies: command to run, flow to drive, value to
  observe. This makes "does the build match our goal?" answerable during the build.

## Step 6: Reuse Review — Compare Plan Against Codebase

Walk every task: **does the codebase already do this?** Search existing components,
composables, stores, endpoints, utilities — route through `references/SKILL.md` and the
feature docs, which record what's already built.

- Plan needs A, B, C and feature A exists → the plan **includes** existing A (naming where
  it lives) and builds only B and C.
- Partial coverage → the task becomes "extend X", not "build X".
- Record results in the plan's **Reuse** table. Duplication costs tokens twice — build and
  upkeep. New code proposed without naming what was searched = incomplete plan.

## "Small Enough" — the Definition

All six must hold; fail any one → break it down further:

1. **≤5 files touched** (M size or below)
2. **One subsystem** — not two independent ones (e.g. auth AND billing)
3. **≤3 acceptance criteria** describe it completely
4. **One focused session** — ~≤2 h agent work, survives no session boundary
5. **One working state** — ends with the system building and behaving; one commit's worth
6. **No "and" in the title** — that's two tasks

| Size   | Files | Scope                                 | Example                              |
| ------ | ----- | ------------------------------------- | ------------------------------------ |
| **XS** | 1     | Single function or config change      | Add a validation rule                |
| **S**  | 1-2   | One component or endpoint             | Add a new API endpoint               |
| **M**  | 3-5   | One feature slice                     | User registration flow               |
| **L**  | 5-8   | Multi-component feature               | Search with filtering and pagination |
| **XL** | 8+    | **Too large — break it down further** | —                                    |

Agents perform best on S and M. L must be justified; XL is never a task, only a phase.

## Task Template

```markdown
## Task [N]: [Short descriptive title — no "and"]

**Category:** [bug fix | feature | refactor | data | ops | doc]

**Description:** One paragraph: what this task is for (the "what" from Step 2).

**Expectation:** Observable behavior after this task that didn't exist before.

**Acceptance criteria:**
- [ ] [Specific, testable condition]
- [ ] [Specific, testable condition]

**Review check (how the builder verifies):**
- [ ] Tests pass: [command]
- [ ] Build succeeds: [command]
- [ ] Manual check: [flow to drive, value to observe]

**Dependencies:** [Task numbers, or "None"]

**Shared surfaces:** [files/stores/contracts shared with other tasks, or "None"]

**Reuses:** [existing component/store/endpoint this builds on, or "None — searched: <terms>"]

**Files likely touched:**
- `src/path/to/file`

**Estimated scope:** [XS | S | M | L]
```

## Output: One Plan Doc Under `references/`

The plan is a **single file** in `references/`, named by comparing the work to what's
already in the codebase:

- **`references/build-<slug>.md`** — builds or adds a new feature/capability the codebase
  doesn't have yet.
- **`references/refact-<slug>.md`** — refactors or updates existing code — adds no new
  concept, or only a minimal one. Covers restructuring AND most bug fixes (a fix corrects
  existing behavior; it doesn't introduce a new concept).
- **`references/<slug>.md`** (no prefix) — doesn't clearly fit either bucket.

The task checklist lives **inside** the plan doc — no separate todo file. Downstream
tooling (`/build`, later sessions) reads this doc directly by path. After writing it:


1. Keep its **Status** line current (`PLANNED` → `IN PROGRESS` → `SHIPPED`).
2. **Never list it in a `SKILL.md` index.** Those indexes route to fact docs only; a plan is
   found by its path or by `ls references/build-*`.

## Outcome recap

A plan's `## Outcome` line is written in the same pass that flips **Status** to SHIPPED
(normally `/build`'s last task), directly under the Status line, and repeated in that
session's chat report. One line:

> **Outcome:** 3 bugs fixed · −75 lines (−120/+45) · merged 2 (fileA+fileB) · removed 1 · created 2

Rules — tiny, precise, no padding:
- **Fixed order:** bugs · lines · files (merged / removed / created). Eyes learn positions.
- **Omit any zero-count axis entirely** — `0 bugs fixed` is noise, absence says it.
- **Lines lead with the net** (sign included), raw `−removed/+added` in parens. Count code
  and tests only; docs and the plan doc itself don't count.
- **"Bugs fixed" = observable wrong behavior corrected** (the plan's `bug fix`-category
  tasks plus incidentals) — refactors and hygiene don't inflate it.
- Derive from `git show --numstat` over the plan's commits, not from memory.

## Plan Document Template

```markdown
# Implementation Plan: [Feature/Project Name]

**Status:** PLANNED (not started) <!-- → IN PROGRESS → SHIPPED -->

## Overview
[One paragraph summary of what we're building, and what kind of work it is]

## References Read (Step 0)
- [reference docs consulted, per references/SKILL.md routing]

## Architecture Decisions
- [Key decision 1 and rationale]
- [Key decision 2 and rationale]

## Reuse (Step 6)
| Plan needs | Already exists? | Where | Action |
|---|---|---|---|
| [capability] | Yes / Partial / No | [file/doc] | Reuse / Extend / Build |

## Logic Map (Step 3)
[Dependency graph + conflict notes: which tasks share files/stores/contracts]

## Execution Schedule (Step 4)
- Sequential spine: [task order]
- Parallelizable: [task groups proven conflict-free, or "none"]

## Task List

### Phase 1: Foundation
- [ ] Task 1: ...
- [ ] Task 2: ...

### Checkpoint: Foundation
- [ ] Tests pass, builds clean

### Phase 2: Core Features
- [ ] Task 3: ...
- [ ] Task 4: ...

### Checkpoint: Core Features
- [ ] End-to-end flow works

### Phase 3: Polish
- [ ] Task 5: ...

### Checkpoint: Complete
- [ ] All acceptance criteria met
- [ ] Ready for review

## Risks and Mitigations
| Risk | Impact | Mitigation |
|------|--------|------------|
| [Risk] | [High/Med/Low] | [Strategy] |

## Open Questions
- [Question needing human input]
```

## Verification (before implementation starts)

- [ ] Step 0 reading done; references listed in the plan
- [ ] Every task has a category and a defined "what" (Step 2)
- [ ] Every task has an expectation, acceptance criteria, and a review check (Step 5)
- [ ] Logic map covers all dependencies AND shared surfaces (Step 3)
- [ ] Schedule marks sequential vs parallel, with justification (Step 4)
- [ ] Reuse table filled — every "Build" row states what was searched (Step 6)
- [ ] Every task passes the "small enough" definition
- [ ] Checkpoints exist between major phases
- [ ] The human has reviewed and approved the plan

## See Also

Acceptance criteria are per-task ("did we build the right thing?") and sit on top of the
project-wide Definition of Done, the standing bar every task clears before it counts as
done. See `references/SKILL.md` § Standing rules where that exists; with no reference layer,
the standing bar is whatever the codebase's own tests and build already enforce.

**Last Updated**: 2026-10-19
