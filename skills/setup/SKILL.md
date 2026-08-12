---
name: setup
description: Prepare a project to run this workflow — decide between a grounded setup that builds the references/ layer from the real codebase, or general mode that runs the commands without it. Use right after install.sh, or when the other commands complain that references/ is missing.
---


# Setup

Make a project ready for the other eight commands. **Writes only inside `references/`.**
Never touches source, config, or history.

**Use when:** `install.sh` has just linked the skills into a project; a command halted
because `references/SKILL.md` was missing; the project's reference docs have drifted so far
they mislead more than they help.
**NOT for:** installing the skills (that is `install.sh`, and it needs no agent), or writing
a plan for actual work (`/plan`).

## The decision this command exists to force

Every other command in this workflow routes through `references/` — a small set of docs
holding *this project's* facts. That layer is the difference between an agent that checks a
claim against something and one that checks it against its own memory.

Two ways to run, and the user picks. **Never pick for them.**

| | **Grounded** | **General** |
|---|---|---|
| `references/` | built from the real codebase | absent |
| Commands read | project docs, then code | code only |
| `/plan`, `/inspect` cite | `file:line` **and** a doc | `file:line` only |
| Cost to set up | one session, with your review | nothing |
| Failure mode | a stale doc asserts something false | the agent re-derives, and sometimes re-derives wrong |

General mode is a real choice, not a degraded one — it suits a small or short-lived
codebase, or a first trial run. It is reversible: run `/setup` again whenever the project
grows into wanting the doc layer.

## Step 0: Read the ground before offering anything

Run these and read the output. Do not ask the user anything until you have.

```
git rev-parse --show-toplevel
ls -a
ls references/ 2>/dev/null || echo "NO references/"
cat references/SKILL.md 2>/dev/null | head -40
```

Then identify the stack from what is actually present — `package.json`, `pyproject.toml`,
`go.mod`, `Cargo.toml`, `*.config.*` — not from the directory names.

**State what you found in one line**, so the user can interrupt before you propose anything:

> *"Astro 5 + TypeScript, 34 files under `src/`, no `references/`. Two ways to set this up —"*

## Step 1: Offer the two modes, then stop

Present the table above, adapted to what you actually found. Recommend one, with the reason
tied to this project — size, age, how many people touch it — not to a general principle.

**Then wait.** No file is created before an explicit choice.

If `references/` already exists with content, do not offer to recreate it. Offer instead to
**audit** it: list which of the three core docs exist, which the other commands expect, and
what is missing. Fill only the gaps, and never overwrite a file the user wrote without
showing them the diff first.

## Step 2A: Grounded — build the layer

Three files. **Each claim must come from a file you opened**, and every path you name must
be verified with `ls` or `grep` before it goes in. A scaffold full of plausible-looking
guesses is worse than no scaffold: the commands will trust it.

Where a fact is genuinely unknown, write `TODO — <the specific question>` rather than a
guess. A visible hole is a working document; a confident wrong sentence is a trap.

### `references/SKILL.md` — the index

Every command's Step 0 reads this first, and routes from it. Two sections, both required:

```markdown
# Project Reference Index

## Routing

| When the work touches | Read |
|---|---|
| Anything that writes code | `development/conventions.md` |
| Structure, stack, where code goes | `development/architecture.md` |
| <feature area found in this repo> | `<doc>` |

## Standing rules

1. **Never commit without explicit per-commit approval.** No command in this workflow
   creates a commit on its own; `/build` leaves work in the tree for review.
2. <rule this project actually enforces, one line each>
```

Rule 1 is cited by name from [`/build`](../build/SKILL.md) and [`/plan`](../plan/SKILL.md).
It stays, verbatim, in every project. Rules after it are the project's own — draw them from
what the codebase visibly enforces, and if you find none, leave only rule 1 rather than
inventing company policy.

Add a routing row per feature area that actually exists. A row pointing at a doc you did not
write is a broken route — either write the doc or leave the row out.

### `references/development/architecture.md`

Stack with versions, read out of the lockfile. The directory map, generated — not recalled:

```
git ls-files | awk -F/ 'NF>1 {print $1"/"$2}' | sort -u | head -40
```

Then the parts a newcomer gets wrong: where a new file of each kind goes, what the data
contract is (schema, content collection, API shape), and which boundaries are load-bearing.
Name the file that proves each one.

### `references/development/conventions.md`

Numbered rules, because [`/inspect`](../inspect/SKILL.md) cites them by number.

Derive them from the code, not from best practice. Read enough real files to see the
pattern, then state it with the file that demonstrates it. Naming, imports, styling tokens,
state, error handling, testing — cover only the ones this codebase visibly has a position
on. **Six rules that are true beat twenty that are aspirational.**

For each: the rule in one line, then why, then the file that shows it.

### Close the loop

Show the user every file you wrote and ask them to correct it. You inferred these from code;
they know which inferences are wrong. Their corrections are the point of the exercise —
the docs are only worth what this review puts into them.

Then remind them: `references/` belongs to **their** repo and should be committed. It is
project knowledge, not tooling.

## Step 2B: General — write nothing

Create no files. `references/SKILL.md` staying absent *is* the switch: every command checks
for it and drops into general mode on its own.

Tell the user plainly what changes:

- Commands work from the codebase alone and re-derive context each session
- `/plan` and `/inspect` still write plan docs — into `references/`, which they create as a
  plain folder. That is a working directory, not the doc layer.
- Nothing halts for a missing doc
- `/setup` again, any time, switches over

## Constraints

**Never edit the workflow's own `SKILL.md` files.** They are symlinks into a shared clone —
an edit there silently rewrites the workflow for every project installed from it. Everything
project-specific belongs in `references/`. That split is what lets `git pull` update all
installs at once.

**Never write outside `references/`.** Not source, not config, not `.gitignore`, not CI.

**Never fabricate a path.** `ls` or `grep` it first, every time.

**Never proceed on silence.** No choice stated, no files written.
