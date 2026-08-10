# A shipping workflow for Claude Code

Nine slash commands that turn an agent from something you chat with into something you can
run a release through. They are not prompt templates — each one is a contract about where
judgment sits, what counts as verified, and what the agent is not allowed to do on its own.

Extracted from a real project, so the examples are concrete rather than generic.

## The thesis

**Every generation drifts. So judgment sits at both ends and never in the middle.**

An agent asked to "build feature X" makes a hundred small decisions you never see, and the
ones it gets wrong surface days later. The fix is not a better prompt. It is to split the
work so that intent is decided before any code exists, and the result is audited after —
with the generation itself boxed in between, allowed to execute but never to redefine.

```
/plan  →  /build  →  /inspect  →  /commit  →  /release
```

| | |
|---|---|
| [`/plan`](commands/plan.md) | Cuts work into ordered, contract-bearing tasks. Writes no code. |
| [`/build`](commands/build.md) | Executes an approved plan, one verified task at a time. May only stop and ask. Never commits. |
| [`/inspect`](commands/inspect.md) | Audits what exists — duplication, dead code, wrong-sized abstractions, logic bugs — and ends in severity-labelled findings. Fixes nothing. |
| [`/commit`](commands/commit.md) | Proposes grouped commits by topic, waits for a yes. |
| [`/release`](commands/release.md) | Clean tree → push → tag → release notes → deploy. Stops and reports on any blocker. |

Supporting commands:

| | |
|---|---|
| [`/trim`](commands/trim.md) | Reduces a named file to its smallest correct form. Zero information loss, behavior identical. |
| [`/handoff`](commands/handoff.md) | Writes a self-contained handoff for the next session, with a tree fingerprint so the next agent can detect drift. |
| [`/team`](commands/team.md) | Runs a request as a small agent DAG with two review gates and a critic that must disagree. |
| [`/name`](commands/name.md) | Renames Figma layers to a design-system convention. Names only. |

## What actually makes them work

The commands are long because the useful parts are the constraints, not the instructions.
The ideas that carry the most weight:

**Red-teaming belongs in the audit, not the plan.** Attacking a plan is speculation about
speculation. Attacking an audit is verification. `/inspect` red-teams its own output before
the user sees it; `/plan` does not.

**A checkbox is a claim.** `/build` verifies each task against its own acceptance criteria
before starting the next one, and a task that cannot verify halts the run rather than
letting bad work become the foundation for more.

**Commits are never automatic.** No command commits without an explicit per-commit yes.
`/build` instead writes a patch snapshot per task, which gives rollback points without
handing the agent the history.

**Prove dead, don't infer it.** Before `/inspect` calls anything unused it has to show the
grep — including lazy imports, re-exports, and importers that never call. The failure mode
this prevents is real: a substring match on `_title` happily matches `tile__title`.

**Docs are load-bearing.** A change that makes a reference doc wrong is not done until the
doc is updated in the same pass. Several commands read a `references/` directory first and
fail loudly if it was skipped.

**State belongs in a file, not a chat.** Plan documents are the unit of work; `/handoff`
exists because context decays and the next session starts from zero.

## Installing

Claude Code reads project commands from `.claude/commands/`.

```bash
git clone https://github.com/<owner>/claude-code-workflow.git
cd your-project
ln -s ../../claude-code-workflow/commands .claude/commands
```

A symlink keeps one source of truth if you use them across several repos. Copying the
directory works just as well.

## Adapting them

They assume a `references/` directory holding the project's own docs — an index, a
conventions file, an architecture file — and several commands refuse to start until they
have read the relevant ones. That directory is the part you supply. Without it the commands
still run, but they lose the thing that makes them accurate: a place to check a claim
against something other than the model's memory.

Some commands carry examples from the project they grew in — a static-site deploy step in
`/release`, an Astro dependency graph in `/plan`. Replace them with your own; the structure
around them is what transfers.

## License

MIT — see [LICENSE](LICENSE).
