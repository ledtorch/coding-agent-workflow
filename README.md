# A shipping workflow for Claude Code and Codex

Nine commands that turn an agent from something you chat with into something you can run a
release through. They are not prompt templates — each one is a contract about where judgment
sits, what counts as verified, and what the agent is not allowed to do on its own.

Extracted from a real project, so the examples are concrete rather than generic.

Written once as [Agent Skills](https://agentskills.io), so the same file runs in both:
`/plan` in Claude Code, `$plan` in Codex.

## The thesis

**Every generation drifts. So judgment sits at both ends and never in the middle.**

An agent asked to "build feature X" makes a hundred small decisions you never see, and the
ones it gets wrong surface days later. The fix is not a better prompt. It is to split the
work so that intent is decided before any code exists, and the result is audited after —
with the generation itself boxed in between, allowed to execute but never to redefine.

```
/plan  →  /build  →  /inspect  →  /build  →  /commit  →  /release
```

The audit loops back. `/inspect` doesn't fix what it finds — it ends in a plan document, and
that plan goes through `/build` like any other. An audit that edits code on the way past is
just another unreviewed generation.

| | |
|---|---|
| [`/plan`](skills/plan/SKILL.md) | Cuts work into ordered, contract-bearing tasks. Writes no code. |
| [`/build`](skills/build/SKILL.md) | Executes an approved plan, one verified task at a time. May only stop and ask. Never commits. |
| [`/inspect`](skills/inspect/SKILL.md) | Audits what exists — duplication, dead code, wrong-sized abstractions, logic bugs — and ends in severity-labelled findings plus a plan. Fixes nothing. |
| [`/commit`](skills/commit/SKILL.md) | Proposes grouped commits by topic, waits for a yes. |
| [`/release`](skills/release/SKILL.md) | Clean tree → push → tag → release notes → deploy. Stops and reports on any blocker. |

Supporting commands:

| | |
|---|---|
| [`/trim`](skills/trim/SKILL.md) | Reduces a named file to its smallest correct form. Zero information loss, behavior identical. |
| [`/handoff`](skills/handoff/SKILL.md) | Writes a self-contained handoff for the next session, with a tree fingerprint so the next agent can detect drift. |
| [`/team`](skills/team/SKILL.md) | Runs a request as a small agent DAG with two review gates and a critic that must disagree. |
| [`/name`](skills/name/SKILL.md) | Renames Figma layers to a design-system convention. Names only. |

## Installing

```bash
git clone https://github.com/ledtorch/coding-agent-workflow.git
cd coding-agent-workflow
./install.sh /path/to/your-project        # both agents
```

`./install.sh /path/to/project claude` or `... codex` installs one only, and
`./install.sh --user` installs for every project at once. The script symlinks rather than
copies, so `git pull` here updates every project you installed into.

What it links, if you'd rather do it by hand:

| Agent | Directory | Invoked as |
|---|---|---|
| Claude Code | `<project>/.claude/skills/<name>` | `/plan` |
| Codex | `<project>/.agents/skills/<name>` | `$plan` |

Codex scans `$CWD/.agents/skills` → `$REPO_ROOT/.agents/skills` → `$HOME/.agents/skills`,
and follows symlinked folders. It will also pick a skill *implicitly* when your request
matches its `description` — ask it to "audit this file for dead code" and `$inspect` can
trigger without being named.

> **Not `~/.codex/prompts/`.** Codex custom prompts are deprecated in favour of skills, and
> they only ever lived in your home directory — they cannot ship inside a repo, which is the
> whole point of sharing a workflow.

Older installs that symlinked `.claude/commands` still work: `commands/` is kept as symlinks
pointing at the same files.

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

## Adapting them

They assume a `references/` directory holding the project's own docs — an index, a
conventions file, an architecture file — and several commands refuse to start until they
have read the relevant ones. That directory is the part you supply. Without it the commands
still run, but they lose the thing that makes them accurate: a place to check a claim
against something other than the model's memory.

Some commands carry examples from the project they grew in — a static-site deploy step in
`/release`, an Astro dependency graph in `/plan`. Replace them with your own; the structure
around them is what transfers.

Each command opens with the shell commands it wants run first (branch, status, diff) rather
than pre-injecting them, because that is what makes one file work in both agents. If you use
Claude Code only and prefer the output pre-loaded, add
`` - Branch: !`git branch --show-current` `` back to the top of that skill — Claude expands
it, Codex prints it literally.

## License

MIT — see [LICENSE](LICENSE).
