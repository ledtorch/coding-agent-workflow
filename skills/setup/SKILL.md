---
name: setup
description: Prepare a project to run this workflow — either wire the commands into the doc layer it already has (adopt), or build that layer from the real codebase (init). Use right after install.sh, or when the other commands report that references/ is missing.
---


# Setup

Make a project ready for the other commands. **Writes only inside `references/`**, plus
one proposed edit to a `references/SKILL.md` the project already owns. Never touches source,
config, or history.

**Use when:** `install.sh` has just linked the commands into a project; a command reported
that `references/` was missing; the project's reference docs have drifted so far they mislead
more than they help.
**NOT for:** installing the commands (that is `install.sh`, and it needs no agent), or writing
a plan for actual work (`/plan`).

## The mode is already chosen

The user picked when they ran the installer. **Detect it — never re-ask.**

|              | **adopt** — `install.sh`                             | **init** — `install.sh --init`                   |
| ------------ | ---------------------------------------------------- | ------------------------------------------------ |
| The project  | already has its own `references/SKILL.md`            | has no doc layer yet                             |
| Your job     | wire the commands into the docs that exist           | write the layer from the real codebase           |
| `SKILL.md`   | **theirs.** You propose an edit; they approve it     | yours to write                                   |
| Failure mode | their router doesn't route to what the commands read | a scaffold of plausible guesses nobody corrected |

Both end in the same place: the three contract paths resolve, and the index routes to them.

### The three contract paths

Hardcoded in the other commands' blocking Step 0. Whatever the index says about them, they
have to exist:

| Path                                     | Read by                                                         |
| ---------------------------------------- | --------------------------------------------------------------- |
| `references/SKILL.md`                    | `/build` `/inspect` `/plan` `/team`                             |
| `references/development/conventions.md`  | `/build` `/handoff` `/inspect` `/label` `/plan` `/team` `/trim` |
| `references/development/architecture.md` | `/build` `/handoff` `/plan`                                     |

Prose is the project's. Paths are not. This is the one thing setup must leave true.

## Step 0: Read the ground before proposing anything

Run these and read the output. Ask nothing until you have.

```
git rev-parse --show-toplevel
ls -a
ls -R references/ 2>/dev/null | head -40 || echo "NO references/"
cat references/SKILL.md 2>/dev/null | head -60
grep -rl 'Stub from install.sh' references/ 2>/dev/null
ls docs/ AGENTS.md CLAUDE.md CONTRIBUTING.md 2>/dev/null
```

That last line matters: a project with no `references/` may still be well documented
somewhere else, and adopt mode's whole job is to find it rather than write a second copy.

Then identify the stack from what is actually present — `package.json`, `pyproject.toml`,
`go.mod`, `Cargo.toml`, `*.config.*` — not from the directory names.

## Step 1: Say which mode you detected, in one line

| What Step 0 found                                     | Mode                |
| ----------------------------------------------------- | ------------------- |
| `references/SKILL.md` with real routing content       | **adopt** → Step 2A |
| Absent, or carrying the `Stub from install.sh` marker | **init** → Step 2B  |

State it so the user can interrupt before any file moves:

> *"Astro 5 + TypeScript, 34 files under `src/`, `references/SKILL.md` already written —
> adopt: I'll wire the commands into it rather than write my own."*

**Stubs are not content.** `install.sh` leaves `architecture.md` and `conventions.md` behind
carrying the marker `Stub from install.sh`. A file with the marker has never been filled:
treat it as absent and overwrite it freely. Only a file *without* the marker is the user's,
and that one is never overwritten without showing the diff first.
`references/development/commands/` holds the commands themselves, copied in by the
installer. They are the project's to edit, but not *yours* to edit during a setup — they are
tooling, not project knowledge, and nothing here audits or rewrites them.

## Step 2A: Adopt — wire into the docs that exist

The project already documented itself. Your job is the smallest edit that makes the commands
work, not a second doc layer beside the real one.

### 1. Locate what already plays each role

Read their `references/SKILL.md` in full, then find the existing equivalents:

- What do they call the file that holds code rules? (`conventions.md`, `style-guide.md`,
  a section of `CONTRIBUTING.md`, rules inside `AGENTS.md` or `CLAUDE.md`)
- What holds the stack, layer map, and boundaries?
- Do they already have per-feature docs, and where?

Report the mapping as a table before touching anything — role, the file that plays it, and
whether it already sits at the contract path.

### 2. Bridge each contract path that doesn't resolve

Three moves, in preference order. **Ask; don't pick for them.**

| Situation                                                 | Move                                                                                                                                                     |
| --------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Their doc is already at the contract path                 | Nothing to do                                                                                                                                            |
| Their doc exists elsewhere                                | **Point** — write a short doc at the contract path whose entire body routes to the real one. No copying, so nothing can drift. Reversible in one delete. |
| Their doc exists elsewhere and is the obvious single home | **Move** — `git mv` to the contract path, then sweep every inbound link to zero hits. Cleaner, but touches their tree.                                   |
| No equivalent exists                                      | **Write** it, exactly as Step 2B does                                                                                                                    |

Never copy content into the contract path. A copied rule is a second source of truth, and it
will drift in the direction of whichever file someone edits next.

### 3. Propose the `SKILL.md` edit

Two additions, shown as a diff and applied only on approval. Match their voice and structure —
if their index is prose, write prose; if it's a table, add rows.

- **Routing** to the contract paths, so a command sent here is told where to read.
- **Standing rule:** *"Never commit without explicit per-commit approval."* This is cited by
  name from [`/build`](../build/SKILL.md) and [`/plan`](../plan/SKILL.md), so it has to be
  present in every project. If their index already says this in their own words, cite theirs
  and add nothing.

If the user — or their agent — would rather write the edit differently, that is fine. The
contract is the paths resolving, not the wording.

### 4. Feature docs

If they already have a per-feature doc convention, leave it alone and add nothing.

Otherwise offer `references/features/example.md`, written per [`feature-doc.md`](feature-doc.md)
and tailored to their stack — see Step 2B §4.

## Step 2B: Init — build the layer

Four files. **Each claim must come from a file you opened**, and every path you name must be
verified with `ls` or `grep` before it goes in. A scaffold full of plausible-looking guesses is
worse than no scaffold: the commands will trust it.

Where a fact is genuinely unknown, write `TODO — <the specific question>` rather than a guess.
A visible hole is a working document; a confident wrong sentence is a trap.

### 1. `references/SKILL.md` — the index

Every command's Step 0 reads this first and routes from it. Two sections, both required:

```markdown
# Project Reference Index

## Routing

| When the work touches | Read |
|---|---|
| Anything that writes code | `development/conventions.md` |
| Structure, stack, where code goes | `development/architecture.md` |
| <feature area found in this repo> | `features/<doc>.md` |

## Standing rules

1. **Never commit without explicit per-commit approval.** No command in this workflow
   creates a commit on its own; `/build` leaves work in the tree for review.
2. <rule this project actually enforces, one line each>
```

Rule 1 stays verbatim in every project. Rules after it are the project's own — draw them from
what the codebase visibly enforces, and if you find none, leave only rule 1 rather than
inventing company policy.

A routing row pointing at a doc you did not write is a broken route — write the doc or leave
the row out.

### 2. `references/development/architecture.md`

Stack with versions, read out of the lockfile. The directory map, generated — not recalled:

```
git ls-files | awk -F/ 'NF>1 {print $1"/"$2}' | sort -u | head -40
```

Then the parts a newcomer gets wrong: where a new file of each kind goes, what the data
contract is (schema, content collection, API shape), and which boundaries are load-bearing.
Name the file that proves each one.

### 3. `references/development/conventions.md`

Numbered rules, because [`/inspect`](../inspect/SKILL.md) cites them by number.

Derive them from the code, not from best practice. Read enough real files to see the pattern,
then state it with the file that demonstrates it. Naming, imports, styling tokens, state,
error handling, testing — cover only the ones this codebase visibly has a position on.
**Six rules that are true beat twenty that are aspirational.**

For each: the rule in one line, then why, then the file that shows it.

### 4. `references/features/example.md`

Read [`feature-doc.md`](feature-doc.md) — it holds the shape and the reasoning. Write the
project's own copy from it, tailored: their stack's vocabulary, their real file paths in the
illustrations, their conventions rules cited by the numbers you just assigned.

Do not copy it verbatim. A template naming another project's framework teaches the wrong
shape, and the first person to follow it inherits the mismatch.

The file stays in place as the project's template; feature docs written later follow it.
Write no actual feature docs here — that is the user's work, and `/plan` or `/build` will
prompt for them as features get built.

### 5. Close the loop

Show the user every file you wrote and ask them to correct it. You inferred these from code;
they know which inferences are wrong. Their corrections are the point of the exercise — the
docs are only worth what this review puts into them.

Then remind them: `references/` belongs to **their** repo and should be committed. It is
project knowledge, not tooling. Commit `.claude/skills/` and `.agents/skills/` too — both
hops are relative and resolve inside the repo, so a teammate who clones it has the commands
without running the installer.

## If the user stops here

Setup is not a gate. Say so plainly rather than pressing:

- Commands still run. They work from the codebase alone and say so at the top of each run.
- `/plan` and `/inspect` still write their plan docs into `references/`. That is a working
  directory, not the doc layer.
- Nothing halts for a missing doc — but nothing gets checked against anything, either.
- `/setup` again, any time, picks up where this left off.

## Constraints

**Never edit the commands.** `references/development/commands/` belongs to the person running
this project, who may tune it whenever they like — but a setup that quietly rewrites the
command it is being run by is indistinguishable from a bug. Everything you write belongs in
the doc layer.

**Never overwrite a doc the user wrote.** Diff first, apply on approval. The only files you
overwrite freely are the ones still carrying the `Stub from install.sh` marker.

**Never write outside `references/`** — except a `git mv` the user explicitly approved in
Step 2A, and never source, config, `.gitignore`, or CI.

**Never fabricate a path.** `ls` or `grep` it first, every time.

**Never proceed on silence.** No approval stated, no files written.

## Verification

- [ ] Step 0 run in full, including the search for docs outside `references/`
- [ ] Mode detected and stated in one line before anything was written
- [ ] All three contract paths resolve when you finish
- [ ] Nothing copied between docs — pointed or moved, never duplicated
- [ ] Every path named in a doc verified with `ls` or `grep`
- [ ] Unknowns written as `TODO — <question>`, not guessed
- [ ] The user has seen every file written or edited, and corrected it
- [ ] Nothing written outside `references/`

**Last Updated**: 2026-10-19
