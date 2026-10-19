---
name: commit
description: Create a git commit following this project's conventions
---


## Context

Before proposing anything, run these and read the output in full:

```
git status
git diff HEAD                 # staged + unstaged; use --cached when staging exists
git branch --show-current
git log --oneline -10         # match the existing message style
```

## Commit message format

```
<type>[optional (scope)]: <description>

[optional body]

Assisted by: <model name>
```

### Types

| Type      | When to use                                               |
| --------- | --------------------------------------------------------- |
| `feat`    | New user-facing feature or capability                     |
| `fix`     | Bug fix or correcting broken behavior                     |
| `ui`      | Visual/layout changes                                     |
| `refact`  | Code restructure without changing behavior                |
| `docs`    | Documentation, references, specs, product plans           |
| `content` | Case-study copy or assets — `src/content/`, images, video |
| `perf`    | Performance improvement                                   |
| `chore`   | Maintenance — deps, config, cleanup                       |

### Rules

1. **One logical change per commit.** Group or split by topic — multiple types/scopes = multiple commits.
2. **Imperative present tense**: "add", "fix", "update" — not "added", "fixes", "updated".
3. **Description under 72 characters.** Lead with what changed, not which files.
4. **Scope is optional** — use when it clarifies: `ui(profile):`, `fix(auth):`, `feat(directions):`.
5. **Body bullets start with file name** — e.g. `- tags.py: add search endpoint with prefix matching`.

### Safety

- **Never** commit files that may contain secrets (`.env`, credentials, private keys). Warn the user.
- **Never** use `--no-verify`, `--force`, or amend without explicit user request.

## Workflow

### If there ARE staged changes:

**The commit scope is the staged changes only.** Do NOT propose unrelated unstaged/untracked files for inclusion.

1. Read the staged diff (`git diff --cached`).
2. Check unstaged/untracked files for anything **directly related** to the staged topic that might have been forgotten (e.g., a modified file that belongs with the same logical change). Flag these briefly and ask whether to include — but do not pull in unrelated work.
3. If the staged changes cover a single topic → propose one commit message.
4. If the staged changes span multiple topics → propose a split with separate commit messages (unstaging and restaging subsets as needed).
5. Present the proposal and wait for **Y** (confirm) or **N** (reject).

### If there are NO staged changes:

1. Read all unstaged and untracked changes (`git diff` + `git status`).
2. Group changes by topic into one or more commits.
3. For each group, list the files and propose a commit message.
4. Present the full proposal and wait for **Y** (confirm) or **N** (reject).

### On confirm (Y):

- Stage the relevant files and create the commit(s) in order.
- If multiple commits, execute them sequentially.

### On reject (N):

- Ask what to change.

### Arguments:

- If the user provided arguments (e.g., `/commit fix the search bug`), use that as context for the message but still verify the diff matches.


**Last Updated**: 2026-10-19
