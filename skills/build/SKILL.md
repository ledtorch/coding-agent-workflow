---
name: build
description: Implement the pending tasks from a plan doc — each verified and patch-snapshotted, run to completion or a judgment call, left in the working tree. Never commits.
---


## Input

The text after the command — `/build <plan-doc-path>` (Claude Code) or
`$build <plan-doc-path>` (Codex) — optionally followed by a task number.
Called **the plan doc path** below.

## Context (gather first)

Before anything else, run these and read the output:

```
git branch --show-current
git status --short
```

## Charter

**Implement the pending tasks from a plan doc, one at a time in order, each verified before
the next starts. Run until the plan is done or a judgment call needs the user.** All work is
left uncommitted for one holistic review before [`/commit`](../commit/SKILL.md).

`/build` is the execution half of [`plan.md`](../plan/SKILL.md). Plan decides *what* and *in what
order*; build executes. It never re-plans, never reorders, and never invents a task that
isn't in the doc.

> **Why batch is safe without commits.** Checkpointing (commits between tasks) and batching
> (proceeding to the next task) are different things. Commits stay forbidden
> (this workflow's standing rule 1, restated in `references/SKILL.md` where that exists);
> what actually gates the run is **per-task verification** — a task that doesn't verify
> clean halts the run before it contaminates later work — plus **per-task patch snapshots**
> (below) as commit-free rollback points.
>
> **The honest trade:** without a user review between tasks, a slightly-off interpretation
> in an early task can propagate before the user sees it. The per-task acceptance criteria
> and *Files likely touched* bounds are the mitigation — hold them tightly, and pause on
> ambiguity rather than guessing forward.

## Scope (the plan doc path)

The input is **a plan doc path**, optionally followed by a task number:

- `/build references/build-place-contact-action.md` → **all** remaining unchecked tasks, in
  plan order, until done or interrupted.
- `/build references/build-place-contact-action.md 3` → **Task 3 only**, dependencies
  permitting, then stop. Use this to isolate a risky task deliberately.
- **Empty** → list the plan docs under `references/` with unchecked tasks and ask which.
  Never guess.

State the resolved plan + mode (all-remaining vs single task) + the task list in one line so
the user can interrupt.


## B.0 Required reading (blocking, before any edit)

1. The **plan doc** itself — in full, not just the tasks. The Architecture Decisions, Reuse
   table, and Logic Map bound what every task may do.
2. `references/SKILL.md` — route to the reference docs this plan's surface
   touches, and read them. The plan's *References Read* section lists what planning consulted.
3. `references/development/conventions.md` — code rules, design tokens, component patterns.
   Required before any code change, per SKILL.md.
4. `references/development/architecture.md` — where the code goes, and the content-collection
   contract.

Skipping any is a build failure — restart from B.0.

> **No `references/SKILL.md`?** The reference layer isn't set up here — item 1 still binds,
> items 2–4 are skipped, and the conventions come from the surrounding code. **Say so at the
> top of the run.** Don't invent a reference doc, and don't halt over its absence.
> [`/setup`](../setup/SKILL.md) builds it, in either mode.


## The run loop

Repeat for each task until the plan is done (or the single named task is done, or an
interrupt gate fires):

1. **Select the task.** Next unchecked `- [ ]` in the plan's Task List, or the one named in
   the plan doc path. If its **Dependencies** aren't complete, stop and say which blocks it.
2. **Read its contract** — Expectation, Acceptance criteria, Review check, Files likely
   touched, Reuses. These are the spec; don't widen them.
3. **Honor the Reuse table.** The plan already searched for what exists. If it says *Reuse*,
   reuse it — don't build a parallel version because the existing one needs a small change.
4. **Implement the minimum that satisfies the acceptance criteria.** Stay inside *Files
   likely touched*; if the task genuinely needs a file outside that list, log it for the
   report rather than silently expanding scope.
5. **Verify** (below). A task that can't verify clean fires the interrupt gate — do not
   proceed to the next task on top of broken work.
6. **Sync the docs.** A change that makes a reference doc wrong isn't done — update it and
   bump its `Last Updated` in this same pass. New shared code↔doc data pairs go in
   architecture.md §9.
7. **Tick the checkbox** in the plan doc, and flip its **Status** line to `IN PROGRESS`
   (or `SHIPPED` when this was the last task). On SHIPPED, fill the plan's `## Outcome`
   one-liner (bugs · lines · files, zeros omitted — format: inspect.md §Outcome recap)
   and repeat it in the final report.
8. **Snapshot.** Write the cumulative diff to the session scratchpad:
   `git diff > <scratchpad>/build-<plan-slug>-task-<N>.patch`. These are the commit-free
   rollback points — "undo back to end of task N" = `git checkout .` + apply patches 1..N.
9. **Progress line.** One line to the user — task number, title, verify result — then
   continue to the next task. The full report waits for the end.

When the loop ends, **report and stop** (below). Leave everything in the working tree.


## Verification

Run the task's own **Review check** block, plus whichever of these the change touches. There
is **no test-runner in this repo** — don't claim "tests pass."

| Surface                              | Check                                                                                                                                                                  |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Any change                           | `npm run build` — must complete clean and build the expected page count                                                                                                |
| Content collection                   | A schema violation fails the build. Confirm the page count changed the way you intended — a card-only project builds no page                                           |
| Anything observable                  | Drive it in the Browser pane and read the result back. A screenshot of the changed state is the proof                                                                  |
| Layout / responsive                  | Measure with `getComputedStyle` at 1280 / 900 / 600 / 400, don't eyeball a screenshot. Confirm `document.documentElement.scrollWidth <= innerWidth`                    |
| Images                               | Check the emitted `srcset` and that `sizes` holds no CSS variable — the attribute is parsed by the preload scanner, which knows nothing about custom properties        |
| Anything behind IntersectionObserver | The Browser pane suspends the rendering lifecycle when hidden, and IO delivery with it. `document.visibilityState` is the first thing to check before believing a zero |
| Deploy                               | `./deploy.sh --dry-run` shows the exact file list. Never claim deployed without the HTTP 200 check the script runs                                                     |

Report what you actually ran and what it returned. A skipped check gets said out loud, not
omitted.


## Never

- **Never `git commit`.** Not per task, not "to checkpoint," not when the plan says to. The
  user commits via [`/commit`](../commit/SKILL.md). This is the repo's first standing rule — the
  patch snapshots exist precisely so batch mode never needs commits.
- **Never mark a task complete on unverified work.** A checkbox is a claim.
- **Never continue past a failed verification** — the next task builds on sand.

## Interrupt gates — pause, ask, continue

These are the only things that halt the run mid-plan. When one fires: stop implementing,
state the situation and the options in one tight block, and **ask the user for the call**.
On an answer, resume the loop; the tasks already done stay done (checkboxes ticked,
snapshots written), so a run that ends here is cleanly resumable by re-invoking.

- A verify/check can't be made to pass without a judgment call.
- The plan is ambiguous, or the task needs a decision the plan doesn't cover — the plan's
  **Open Questions** section is where that belongs.
- The task is **irreversible or high-risk**: auth/permission changes, destructive migrations,
  deletions, payments, deploys, anything touching secrets, or anything `git revert` can't
  undo. Get explicit sign-off first.
- The work would exceed the task's stated scope by more than a file or two — that's a signal
  the plan needs re-cutting, which is `/plan`'s job, not this one.

## Report (end of run)

- Tasks completed this run — number + title each, acceptance criteria marked met / not met.
- Files touched (vs. the plans' predicted lists — call out any difference).
- Every check run, with its actual result.
- Patch snapshots written (paths).
- Docs updated.
- What's left: pending tasks if interrupted (and the gate that fired), or SHIPPED + the
  Outcome line if the plan is done.


**Last Updated**: 2026-10-19
