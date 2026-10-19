---
name: team
description: Run the request as an autonomous team. Plan → review → run → review → synthesize. Two gates; max 2 rollbacks.
---


## Context (gather first)

Run these and read the output before planning:

```
git branch --show-current
git status --short
```

## Pipeline

```
Read → Decompose → Plan → Gate 1 → Assign → Run → Gate 2 → Synthesize
```

The input — the text after `/team` (Claude Code) or `$team` (Codex) — is the user's natural-language goal. Run the pipeline. Don't ask permission for read-only work. Surface only when a gate fires.

## 0. Required reading (before Interpret)

Blocking, in order:

1. **Always** read `references/SKILL.md` — the project doc index. Use it to identify which reference files are relevant to the goal.
2. **If the request requires building** (writing/editing code, creating files, scaffolding features), **also** read `references/development/conventions.md` before any Plan node that writes code. No code-writing agent is dispatched until this read has happened in the main thread.

Cite both reads in the Gate 1 checklist as the first row(s). Skipping either is a planning failure — roll back to step 0.

> **No `references/SKILL.md`?** The reference layer isn't set up here — skip this step and work
> from the codebase itself. **Say so at the top of the run.** Don't invent a reference doc,
> and don't halt over its absence. [`/setup`](../setup/SKILL.md) builds it, in either mode.

## 1. Interpret
Extract: real intent · success shape (advice / fix / comparison / plan) · scope · destructive?

State a one-line restatement so the user can interrupt:
> *"Interpreting as: <X>. Dispatching team to produce: <Y>."*

## 2. Plan the DAG
Decompose into 3–5 nodes. Each node: type · deps · agent kind (`Explore` for reads, `Plan` for design, `general-purpose` for action / `+isolation: "worktree"` for code writes).

Always end with a **critic** node prompted to disagree with the synthesizer.

## 3. Gate 1 — Review the plan

For each plan finding, mark **Auto** or **Ask** using Claude Code's auto-mode as the classifier:
- Auto-mode would prompt → **Ask**
- Auto-mode would run silently → **Auto**
- `/team`-specific addition: ambiguous name/path with multiple valid resolutions → **Ask**

Print the checklist at the top of your response (one row per finding, Auto / Ask + 1-line note).

- All **Auto** → apply silently, proceed.
- Any **Ask** → use `AskUserQuestion` with the single most important question. Revise. Re-run Gate 1. Max 2 loops; on the 3rd, stop and surface the planning problem.

## 4. Run
Dispatch all dep-free nodes in ONE message (parallel `Task` calls). As layers finish, dispatch the next layer the same way. Critic runs last.

## 5. Gate 2 — Review the outcome

For each agent: format ok · scope ok · substance ok · budget ok · no "scope was wrong" signal.

- All pass → synthesize.
- N pass, 1 fails → re-dispatch only the failed node with sharpened prompt.
- "Scope was wrong" signal → roll back to Step 3.

Max 2 rollbacks per invocation. On the 3rd failure, stop:
> *"Plan and execution disagree after 2 rollbacks. Here's what I tried and the next plan I'd try — Y to run / N to revise."*

## 6. Synthesize
Final output:
1. The answer (recommendation / fix / diff)
2. Why — 1–3 sentences, cite `file:line` or `references/*.md`
3. Critic pushback (skip if rubber-stamp)
4. Out of scope (if user might expect it)

Never dump raw agent reports.

## Hard rules
- Main thread orchestrates only. Reads >3 files? Use `Task`.
- Always include a critic. Critics must disagree, not approve — re-prompt one that rubber-stamps.
- Cite `file:line` or doc section for every claim.

## Caps

**Hard (enforce):**
- Max 5 agents per layer
- Max 10 agents total per /team invocation
- Max 4 DAG layers (deeper = wrong problem)

**Soft (debug signal):**
- Total token budget ~60k; per-agent report ~4k
- Persistently over → re-scope, you over-fanned
- Per-agent report: the smallest table that conveys findings


**Last Updated**: 2026-10-19
