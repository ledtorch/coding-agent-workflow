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

Then open your agent there and run **`/setup`** — `$setup` in Codex. It reads your codebase
and finishes whichever half the script couldn't. You can stop reading here.

---

Ten commands that turn an agent from something you chat with into something you can run a
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
| [`/setup`](skills/setup/SKILL.md) | Run once per project. Reads the codebase, then either wires the commands into your existing router or fills the scaffolded docs. |
| [`/trim`](skills/trim/SKILL.md) | Reduces a named file to its smallest correct form. Zero information loss, behavior identical. |
| [`/handoff`](skills/handoff/SKILL.md) | Writes a self-contained handoff for the next session, with a tree fingerprint so the next agent can detect drift. |
| [`/team`](skills/team/SKILL.md) | Runs a request as a small agent DAG with two review gates and a critic that must disagree. |
| [`/name`](skills/name/SKILL.md) | Renames Figma layers to a design-system convention. Names only. |

## Two modes

The workflow installs into a repo, not into your home directory. There is no global install
and no per-machine state — a project either carries the workflow or it doesn't, and you can
see which by looking at it.

What differs between the two is only **who owns `references/SKILL.md`**, the index the
commands route through:

| | **adopt** — `install.sh` | **init** — `install.sh --init` |
|---|---|---|
| For | a project that already has its own `references/SKILL.md` | a project with no doc layer yet |
| Writes docs | **none** — the commands and nothing else; yours stay yours | TODO stubs for the three contract paths, plus `features/example.md` |
| `/setup` then | reads your router and proposes the edit that wires in the commands and the three contract paths | reads your code and fills the scaffolded docs, for you to correct |
| Failure mode | your router doesn't route to what the commands read | a scaffold of plausible guesses nobody corrected |

Adopt is the one that matters for adoption: a project with real docs already has an index,
and overwriting it to install a workflow would be the rudest possible thing to do. `/setup`
proposes the edit and you approve it — and if you or your agent would rather write it
differently, that's fine, as long as it satisfies the contract below.

**`/setup` is not a gate.** Skip it and the commands still run; they just work from the code
alone and say so at the top of each run, because a command that silently invents a
convention is worse than one that admits it has none. It is still the single highest-value
thing you can do per project, and every command will remind you until it exists.

### The contract

Three paths are hardcoded in the commands' required reading. Whatever your router says about
them, they have to resolve:

| Path | Read by |
|---|---|
| `references/SKILL.md` | `/build` `/inspect` `/plan` `/setup` `/team` |
| `references/development/conventions.md` | `/build` `/handoff` `/inspect` `/name` `/plan` `/team` `/trim` |
| `references/development/architecture.md` | `/build` `/handoff` `/plan` |

Prose is yours. Paths are not. A command whose Step 0 can't find its doc doesn't degrade
quietly — it stops and says so, which is the intended behavior and the reason these three
are worth pinning.

### The layout

```
references/
├── SKILL.md                     the index — what to read, and when
├── development/
│   ├── commands/                the ten commands — the only truth in this tree
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

Adopt creates only `development/commands/` and the two symlink directories — the docs are
already yours. Init adds the four files above as TODO stubs, each carrying a marker `/setup`
looks for, so a stub is never mistaken for something someone wrote. **Neither mode ever
overwrites an existing file.**

### `references/development/commands/` is the source of truth

Agents discover commands by scanning `.claude/skills` and `.agents/skills` and nothing else.
Those two directories are **pointers**, not homes — every entry hops through
`references/development/commands/`, which is where the commands actually live for this
project. One place to read them, one place to point at in review, one place a teammate finds
without being told where to look.

The hops into `references/` are relative, so renaming or moving the project doesn't break
them. Only the last hop — `references/development/commands/<name>` into the clone — is
absolute.

Skills are symlinked rather than copied, so `git pull` in the clone updates every project at
once. Keep the clone somewhere permanent: moving or deleting it breaks every install, and
does it silently.

Commit `references/` — the docs are yours. Do not commit the symlinks; they store absolute
paths and resolve to nothing on a teammate's machine, who runs `install.sh` themselves:

```
references/development/commands/
.claude/skills/
.agents/skills/
```

## The docs are frameworks, not content

`install.sh` is plain bash — it can lay out the tree and the symlinks, but it cannot know
anything about your code. The reference docs are what `/setup` writes, by reading the
codebase. Nothing is downloaded and nothing is copied from another project.

They are **shapes to fill**, not files to fetch. Every project has a different stack,
different rules, and different features, so what transfers is the structure and the altitude
— a conventions file that numbers its rules so an audit can cite them, an architecture file
that states boundaries rather than restating the directory tree.

| Doc | Owns |
|---|---|
| `references/SKILL.md` | The router. What each doc covers, what to read first, the standing rules. |
| `references/development/architecture.md` | Stack and versions, layer map, where a new file goes, the boundaries that break things when crossed. |
| `references/development/conventions.md` | Numbered rules for how code is written here, each one shown by a file that already does it. |
| `references/features/example.md` | The template for a feature doc — contracts and invariants, not a description of the code. `/setup` writes it against your stack; every feature doc you add next to it follows it. |

The commands read these before doing anything. That layer is the difference between an agent
that checks a claim against something and one that checks it against its own memory — and it
is the part only your codebase can supply, which is why `/setup` exists and why it runs once
per project.

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

`references/` is where everything project-specific belongs. **Don't edit the `SKILL.md`
files** — they are symlinks into your clone, so a change there rewrites the workflow for
every project you installed into.

Some commands still carry examples from the project they grew in — a static-site deploy step
in `/release`, an Astro dependency graph in `/plan`. Those are illustrations of shape, not
instructions; the structure around them is what transfers.

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
