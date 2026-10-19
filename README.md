# A shipping workflow for Claude Code and Codex

```bash
git clone https://github.com/ledtorch/coding-agent-workflow.git ~/coding-agent-workflow
```

Then, **from inside the project you want the workflow in** — it installs into the current
directory, never the machine:

```bash
~/coding-agent-workflow/install.sh          # adopt — the project already has references/SKILL.md
~/coding-agent-workflow/install.sh --init   # init  — it doesn't, so write the whole layer
```

The commands are copied into the project, so they become yours to edit and no two projects
affect each other. Re-run any time to pick up new ones; only `--update` replaces ones you
have edited.

Then open your agent there and run **`/setup`** — `$setup` in Codex. It reads your codebase
and finishes whichever half the script couldn't. You can stop reading here.

---

Eleven commands that turn an agent from something you chat with into something you can run
a release through. They are not prompt templates — each one is a contract about where judgment
sits, what counts as verified, and what the agent is not allowed to do on its own.

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

|                                       |                                                                                                                                                        |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [`/plan`](skills/plan/SKILL.md)       | Cuts work into ordered, contract-bearing tasks. Writes no code.                                                                                        |
| [`/build`](skills/build/SKILL.md)     | Executes an approved plan, one verified task at a time. May only stop and ask. Never commits.                                                          |
| [`/inspect`](skills/inspect/SKILL.md) | Audits what exists — duplication, dead code, wrong-sized abstractions, logic bugs — and ends in severity-labelled findings plus a plan. Fixes nothing. |
| [`/commit`](skills/commit/SKILL.md)   | Proposes grouped commits by topic, waits for a yes.                                                                                                    |
| [`/release`](skills/release/SKILL.md) | Clean tree → push → tag → release notes → deploy. Stops and reports on any blocker.                                                                    |

Supporting commands:

|                                       |                                                                                                                                                                    |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [`/setup`](skills/setup/SKILL.md)     | Run once per project. Reads the codebase, then either wires the commands into your existing router or fills the scaffolded docs.                                   |
| [`/trim`](skills/trim/SKILL.md)       | Reduces a named file to its smallest correct form. Zero information loss, behavior identical.                                                                      |
| [`/handoff`](skills/handoff/SKILL.md) | Writes a self-contained handoff for the next session, with a tree fingerprint so the next agent can detect drift.                                                  |
| [`/team`](skills/team/SKILL.md)       | Runs a request as a small agent DAG with two review gates and a critic that must disagree.                                                                         |
| [`/label`](skills/label/SKILL.md)     | Renames Figma layers to a design-system convention. Names only.                                                                                                    |
| [`/aeo`](skills/aeo/SKILL.md)         | Audits a website for answer/agent-engine optimization — crawler access, raw-HTML visibility, citability — with evidence-tiered findings and a plan. Fixes nothing. |

## Two modes

What differs between the two is only **who owns `references/SKILL.md`**, the index the
commands route through:

|               | **adopt** — `install.sh`                                                                        | **init** — `install.sh --init`                                      |
| ------------- | ----------------------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| For           | a project that already has its own `references/SKILL.md`                                        | a project with no doc layer yet                                     |
| Writes docs   | **none** — the commands and nothing else; yours stay yours                                      | TODO stubs for the three contract paths, plus `features/example.md` |
| `/setup` then | reads your router and proposes the edit that wires in the commands and the three contract paths | reads your code and fills the scaffolded docs, for you to correct   |
| Failure mode  | your router doesn't route to what the commands read                                             | a scaffold of plausible guesses nobody corrected                    |

In adopt, `/setup` proposes the edit and you approve it; write it differently if you prefer,
as long as it satisfies the contract below.

**`/setup` is not a gate.** Skip it and the commands still run; they just work from the code
alone and say so at the top of each run, because a command that silently invents a
convention is worse than one that admits it has none.

### The contract

Three paths are hardcoded in the commands' required reading. Whatever your router says about
them, they have to resolve:

| Path                                     | Read by                                                         |
| ---------------------------------------- | --------------------------------------------------------------- |
| `references/SKILL.md`                    | `/build` `/inspect` `/plan` `/setup` `/team`                    |
| `references/development/conventions.md`  | `/build` `/handoff` `/inspect` `/label` `/plan` `/team` `/trim` |
| `references/development/architecture.md` | `/build` `/handoff` `/plan`                                     |

Prose is yours. Paths are not. A command whose Step 0 can't find its doc doesn't degrade
quietly — it stops and says so, which is the intended behavior and the reason these three
are worth pinning.

### The layout

```
references/
├── SKILL.md                     the index — what to read, and when
├── development/
│   ├── commands/                the eleven commands, copied — yours to edit
│   │   ├── plan/SKILL.md
│   │   ├── build/SKILL.md
│   │   └── …
│   ├── architecture.md          stack, layer map, load-bearing boundaries
│   └── conventions.md           how code is written here, numbered
└── features/
    ├── example.md               the template — stays, gets followed
    ├── auth.md                  one contract per feature, written by you
    └── …

.claude/skills/<name>   →   ../../references/development/commands/<name>
.agents/skills/<name>   →   ../../references/development/commands/<name>
```

Init adds the four doc files above as TODO stubs, each carrying a marker `/setup` looks for,
so a stub is never mistaken for something someone wrote. **Neither mode ever
overwrites an existing file.**

### The commands are copies, and they are yours

Agents discover commands by scanning `.claude/skills` and `.agents/skills` and nothing else.
Those two directories are **pointers**; the commands themselves are real files under
`references/development/commands/`, copied into the project at install time.

Copied, not symlinked, and that is the whole point:

- **Edit them.** A command is a file in your repo. Change `/inspect`'s severity labels or
  `/commit`'s types to suit this project — nothing you change here reaches any other project.
- **The clone stops mattering.** Move it, delete it, `git pull` it — every project already
  installed keeps working, unchanged, because it holds its own copy.

Both symlink hops are **relative and stay inside the project**, so they survive a rename and
resolve on someone else's machine. Commit all of it — `references/`, `.claude/skills/`,
`.agents/skills/`. A teammate who clones the repo has the commands without running anything.

Re-running `install.sh` never overwrites a command you changed: it lists each one that differs
from the source with the `diff -ru` to read, and you decide — `--update` takes the source
version (losing your edits), or keep yours.

## The docs are frameworks, not content

`install.sh` can copy the commands and lay out the tree, but it cannot know your code, so the
reference docs are what `/setup` writes by reading it — **shapes to fill**, not files to
fetch or copy from another project. Every project has a different stack,
different rules, and different features, so what transfers is the structure and the altitude
— a conventions file that numbers its rules so an audit can cite them, an architecture file
that states boundaries rather than restating the directory tree.

| Doc                                      | Owns                                                                                                                                                                              |
| ---------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `references/SKILL.md`                    | The router. What each doc covers, what to read first, the standing rules.                                                                                                         |
| `references/development/architecture.md` | Stack and versions, layer map, where a new file goes, the boundaries that break things when crossed.                                                                              |
| `references/development/conventions.md`  | Numbered rules for how code is written here, each one shown by a file that already does it.                                                                                       |
| `references/features/example.md`         | The template for a feature doc — contracts and invariants, not a description of the code. `/setup` writes it against your stack; every feature doc you add next to it follows it. |

The commands read these before doing anything. That layer is the difference between an agent
that checks a claim against something and one that checks it against its own memory — and it
is the part only your codebase can supply, which is why `/setup` exists.

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
doc is updated in the same pass. Every command reads `references/` first and fails loudly if
it was skipped.

**State belongs in a file, not a chat.** Plan documents are the unit of work; `/handoff`
exists because context decays and the next session starts from zero.

## Adapting them

**Edit the commands** in `references/development/commands/<name>/SKILL.md`. The constraints
are the valuable part, so tighten them where this project needs it rather than working around
them.

The one file to leave alone is the clone at `~/coding-agent-workflow` — edit there and you
change what every *future* install starts from, which is a different decision from adapting
one project.

The commands are written project-agnostic. Some command folders also carry an `example.md`
of worked examples from a real project — for you to read and borrow from; the command never
reads it.

Each command opens with the shell commands it wants run first (branch, status, diff) rather
than pre-injecting them, because that is what makes one file work in both agents. If you use
Claude Code only and prefer the output pre-loaded, add
`` - Branch: !`git branch --show-current` `` back to the top of that skill — Claude expands
it, Codex prints it literally.

Codex scans `$CWD/.agents/skills` → `$REPO_ROOT/.agents/skills` → `$HOME/.agents/skills`,
and follows symlinked folders. It will also pick a skill *implicitly* when your request
matches its `description` — ask it to "audit this file for dead code" and `$inspect` can
trigger without being named.

> **Not `~/.codex/prompts/`.** Codex custom prompts are deprecated in favour of skills, and
> they only ever lived in your home directory — they cannot ship inside a repo, which is the
> whole point of installing per project.

## License

MIT — see [LICENSE](LICENSE).
