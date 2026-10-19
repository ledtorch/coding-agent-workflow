---
name: handoff
description: Generate a handoff document for the next session — prerequisites, session recap, next tasks
---


## Context

Run these first and read the output — the last two are the **fingerprint** the
next session verifies against, so capture them verbatim:

```
git branch --show-current
git status --short             # changed files this session
git diff --stat HEAD
git log --oneline -8
git log -1 --format=%h         # HEAD at write time
git diff HEAD | shasum         # uncommitted-diff hash
```

## Purpose

The next session starts from zero context. This command produces a self-contained document that lets a fresh agent (a) read the right references first, (b) understand what just shipped, and (c) know what to do next — without scrolling this chat.

## Ground truth — the tree, not memory

A handoff drifts two ways: claims written from conversation memory that no longer match the tree (compacted context, parallel sessions, late changes), and a tree that moves between write time and pickup.

**At write time — verify every claim.**

1. The Context block above is captured fresh at invocation. Treat it, not conversation memory, as the truth about tree state.
2. Every file path, symbol, section anchor (`architecture.md §<Section>`), and count ("<N> tests green") the draft names gets checked against the tree (Grep / Read / ls) **before the document is emitted**. A failed check is fixed or flagged — never emitted as remembered.
3. **Attribute the working tree.** `git status` shows everything — pre-existing and parallel-session files included. Cross-check file mtimes (`ls -laT <file>`) against the session's timespan before claiming a file as this session's; anything foreign is omitted or labeled *"not this session's — do not sweep into commits."*

**At pickup — make drift detectable.** The template's mandatory fingerprint line (HEAD · dirty counts · diff hash) is what §0's Verify step compares. Why three signals: HEAD only moves on commit, so alone it is blind to edits in a dirty tree — the diff hash is what catches those. Accepted residual: `git diff HEAD` misses untracked-file *content* (the untracked count sees them appear); only an mtime spot-check at pickup catches that. Do not replace the fingerprint with a full tree snapshot — a copy goes stale on the first commit, and the next session has the real tree.

## Output format

Produce a markdown document with these sections in order. **No preamble, no closing remarks** — just the document, ready to paste into a new session.

```
# Handoff — <date>, <topic summary in 3-6 words>
Tree at write: HEAD `<short-sha>` · <N> modified · <M> untracked · diff `<hash, first 8>`

## 0. Pickup protocol
…(fixed wording — see Section 0)

## 1. Read first
…

## 2. What shipped this session
…

## 3. Next tasks
…
```


### Section 0 — Pickup protocol

Fixed wording, copied **verbatim** into every handoff:

> **Do not build yet.** First:
> 1. **Verify** — compare the fingerprint above against `git log -1 --format=%h`, `git status --short`, and `git diff HEAD | shasum`. If any of the three moved, re-check §2's claims and §3's start-anchors against the live tree before trusting them.
> 2. **Report** — a few lines: what matches, what drifted, current tree state.
> 3. **Recommend** — which §3 item (or other work) should go first, one line of reasoning each.
> 4. **Wait** — the user picks. Only then touch code.

Do not drop this section: without it a pasted handoff reads as marching orders — a fresh agent sees imperative titles with start-anchors and begins executing instead of recommending.


### Section 1 — Read first

A short list of `references/*.md` files the next agent should read BEFORE touching code.

**Always include** (the baseline):

- [`references/SKILL.md`](references/SKILL.md) — index of all reference docs
- [`references/development/conventions.md`](references/development/conventions.md) — numbered code rules
- [`references/development/architecture.md`](references/development/architecture.md) — stack, project structure, data contract, load-bearing boundaries

**Conditionally include** — scan only the area(s) the session actually touched, then attach the matching docs, not the whole folder:

| Session touched… | Attach                                                                                                        |
| ---------------- | ------------------------------------------------------------------------------------------------------------- |
| `<area>`         | its doc under `references/` (`references/<path>/<area>.md`), or the `architecture.md §<Section>` that owns it |

If a touched area has no doc, flag it inline: *"⚠️ No reference doc exists for `<area>` yet — flag to user."*


### Section 2 — What shipped this session

**3-8 bullets, each ≤ 1 sentence.** Lead with WHAT changed, then in parens the WHY if non-obvious.

> ⚠️ **Scope to THIS session** — the attribution rules in § Ground truth apply here. Prefer commits made this session (`git log`) as the source of truth.

**Skip:**
- CSS tweaks unless they encode a real decision
- Comment-only edits
- Trivial refactors
- File renames without semantic change

**Include:**
- Architecture decisions made (e.g. *"switched `<endpoint>` to `<transport>` with a `<eventA>`/`<eventB>` split"*)
- New stores, modules, ops, endpoints, or contracts
- Discoveries that change how things work (e.g. *"`<API>` fails on `<object kind>` — must use `<workaround>` in `<layer>`"*)
- API/breaking changes (any model/contract version bump, deprecated SDK methods, etc.)
- Anything the next agent MUST know to not re-litigate decisions

If the session was small (one bug fix, a CSS tune), say so honestly in 1-2 bullets — don't pad.


### Section 3 — Next tasks

**Step 0 — Reconcile the prior task list FIRST.**

A handoff drifts when it re-emits tasks the session already resolved. Before writing anything, pull the inherited task list — the previous handoff's §3 (if it was pasted into this session) — and classify each one against what THIS session actually did:

| Prior task became…                         | Action                                                                              |
| ------------------------------------------ | ----------------------------------------------------------------------------------- |
| **Finished** this session                  | Drop from §3 → record in §2 ("shipped X")                                           |
| **Dropped / superseded / decided-against** | Drop from §3 → if the call matters, note it in §2 ("chose B over A; A not pursued") |
| **Still open**                             | Carry forward — refresh its estimate + start-anchor                                 |

A task the session **finished or abandoned must never reappear in §3.** Only after reconciling do you add newly-discovered items (sources below). If a `/handoff` argument file carries dropped/done items as live tasks, they are stale by definition — reconcile, don't recopy.

Then pick the right case:

**Case A — no follow-up work.** State plainly:

> No follow-up tasks. Session work is complete. Next session can start on whatever the user prioritizes.

Do NOT fabricate tasks to fill space.

**Case B — follow-up work exists.** A prioritized punch-list of *proposals* — the next agent recommends, the user chooses (§0); imperative titles do not authorize starting. Each item is:

- **Title** (1 line, imperative verb)
- **Why** (1 line — what's at stake / what breaks without it)
- **Estimate** (S = <1h, M = 1-3h, L = half-day+)
- **Start at** (file path or section anchor)

**Where to look for items:**

- **Verify before building** — a non-trivial change with no run evidence from this session (backend changed, server never restarted). Already-verified work is a §2 line, not a task (check 5). When it applies, lead with it.
- **Refactor candidates** — dead code, duplicated logic, stale comments noticed during this session.
- **Promised but deferred** — anything the user explicitly said "later" or "after `<milestone>`" about.
- **Spawned chips** — only if STILL ACTIONABLE.
- **Known caveats** — partial implementations, missing error handling, hard-coded fallbacks.

If the next task depends on a user decision, phrase as a decision item, not a build item.

**Delete any item that fails these checks:**

1. Requires the next agent to DO something? Status notes ("FYI…", "already done…", anything starting with "Surface…" / "Mention…" / "Remember…") belong in §2, not §3.
2. Already covered by §1 prerequisites the next agent will read anyway? Redundant — delete.
3. Specific to this session's work? Generic backlog belongs in the standing TODO doc, not the handoff.
4. Figured out from `git log` + `git diff` alone? "Review what shipped" is implicit — don't restate.
5. Describes work already **completed** this session (built / fixed / verified)? That's §2.

**Length:** 3-5 real items typical. 1-2 is fine. 0 → switch to Case A. If writing item 6+, audit items 5-6 against the checks above.

## Argument handling

- **No arguments**: dump the handoff document to chat for copy-paste into the next session.
- **With argument** (e.g. `/handoff .claude/handoffs/<YYYY-MM-DD>-<topic>.md`): treat the input as a file path and write the document there with `Write`, then confirm the path in chat. Create the directory first if needed.

## Tone

- Direct, no marketing language.
- "Shipped X" not "Successfully implemented X."
- "Verify before building" not "It is recommended that you verify."
- If the session had a meaningful failure or pivot (e.g. "tried approach A, abandoned for approach B because Y"), include it — the next agent saves time knowing why a path was rejected.


**Last Updated**: 2026-10-19
