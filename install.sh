#!/usr/bin/env bash
#
# Install the workflow commands into a project, for Claude Code and/or Codex.
#
#   ./install.sh                            # adopt — this directory, both agents
#   ./install.sh --init                     # init  — also scaffold the references/ layer
#   ./install.sh --update                   # take the source version of commands you changed
#   ./install.sh claude                     # this directory, Claude Code only
#   ./install.sh /path/to/project           # that project, both agents
#
# adopt (default)  the project already has references/SKILL.md. Links the commands and
#                  writes no docs — /setup wires them into the index that exists.
# init  (--init)   no doc layer yet. Also writes TODO stubs for the three paths the
#                  commands read, plus references/features/, for /setup to fill.
#
# Commands are COPIED, so each project owns and may edit its own, and deleting this clone
# breaks nothing already installed. An edited copy is replaced only by --update.
#
# Targets:
#   <project>/references/development/commands/<name>   real files, this project's own
#   <project>/.claude/skills/<name>   → ../../references/development/commands/<name>
#   <project>/.agents/skills/<name>   → ../../references/development/commands/<name>
#
# One source file per command lives at skills/<name>/SKILL.md.

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/skills"
[[ -d "$SRC" ]] || { echo "no skills/ next to this script — wrong checkout?" >&2; exit 1; }

usage() { awk 'NR>1 && /^#/ {sub(/^# ?/,""); print; next} NR>1 {exit}' "$0"; }

# --- flags ------------------------------------------------------------------
MODE=adopt
UPDATE=0
ARGS=()
for arg in "$@"; do
  case "$arg" in
    --init)     MODE=init ;;
    --update)   UPDATE=1 ;;
    -h|--help)  usage; exit 0 ;;
    --user)
      echo "--user is gone: the workflow installs into a project, not the machine." >&2
      echo "cd into the project and run this script there." >&2
      exit 2 ;;
    -*) echo "unknown flag: $arg (use --init, --update)" >&2; exit 2 ;;
    *)  ARGS+=("$arg") ;;
  esac
done
set -- ${ARGS[@]+"${ARGS[@]}"}

# No path → here. A bare agent name in slot 1 is still an agent name, so
# `install.sh claude` means "this directory, Claude only" — not a directory named claude.
case "${1:-}" in
  claude|codex|both) PROJECT="."; AGENT="$1" ;;
  *)                 PROJECT="${1:-.}"; AGENT="${2:-both}" ;;
esac
[[ -d "$PROJECT" ]] || { echo "not a directory: $PROJECT" >&2; exit 1; }
PROJECT="$(cd "$PROJECT" && pwd)"

case "$AGENT" in
  claude) TARGETS=("$PROJECT/.claude/skills") ;;
  codex)  TARGETS=("$PROJECT/.agents/skills") ;;
  both)   TARGETS=("$PROJECT/.claude/skills" "$PROJECT/.agents/skills") ;;
  *) echo "unknown agent: $AGENT (use claude | codex | both)" >&2; exit 2 ;;
esac

HUB="references/development/commands"

# --- stubs ------------------------------------------------------------------
# Every line a TODO, and every file carrying the marker `/setup` greps for. A scaffold of
# plausible guesses is worse than none, because the commands trust what they read. An
# existing file is NEVER touched.
stub() {
  local rel="$1" f="$PROJECT/$1"
  if [[ -e "$f" ]]; then cat >/dev/null; echo "  · $rel (exists, left alone)"; return 0; fi
  mkdir -p "$(dirname "$f")"
  cat > "$f"
  echo "  ✓ $rel (stub)"
}

scaffold() {
  stub references/SKILL.md <<'EOF'
# Project Reference Index

<!-- Stub from install.sh. Run /setup to fill this from the real codebase, or delete it. -->

## Routing

| When the work touches             | Read                          |
|-----------------------------------|-------------------------------|
| Anything that writes code         | `development/conventions.md`  |
| Structure, stack, where code goes | `development/architecture.md` |

TODO — one row per feature area that actually exists in this repo. A row pointing at a doc
nobody wrote is a broken route.

## Standing rules

1. **Never commit without explicit per-commit approval.** No command in this workflow
   creates a commit on its own; `/build` leaves work in the tree for review.
2. TODO — rules this project actually enforces, one line each. Six that are true beat
   twenty that are aspirational.
EOF

  stub references/development/architecture.md <<'EOF'
# Architecture

<!-- Stub from install.sh. Run /setup to fill this from the real codebase, or delete it. -->

## Stack

TODO — languages, frameworks and versions, read out of the lockfile rather than guessed.

## Directory map

TODO — generate it, don't recall it:

    git ls-files | awk -F/ 'NF>1 {print $1"/"$2}' | sort -u

## Where a new file goes

TODO — one line per kind of file, each naming the existing file that proves the rule.

## Load-bearing boundaries

TODO — the data contract (schema, data model, API shape) and which boundaries
break things when crossed.
EOF

  stub references/development/conventions.md <<'EOF'
# Conventions

<!-- Stub from install.sh. Run /setup to fill this from the real codebase, or delete it. -->

Numbered, because /inspect cites them by number. Derive each rule from code that already
does it — six rules that are true beat twenty that are aspirational.

1. TODO — the rule in one line.
   Why: TODO.
   Shown by: TODO — path/to/file.ts
EOF

  stub references/features/example.md <<'EOF'
# Feature doc template

<!-- Stub from install.sh. /setup writes this from the shape shipped beside the command,
     tailored to this project — its vocabulary, its real paths, its conventions rules. -->

TODO — run /setup.

This file stays in place as the template. Feature docs written later follow it; one doc per
feature, and a feature earns one when someone would otherwise have to read three files to
answer "what is supposed to happen here."
EOF
}

# --- install ----------------------------------------------------------------
echo "→ installing into $PROJECT  (mode: $MODE)"

mkdir -p "$PROJECT/$HUB"

added=0; same=0; updated=0; migrated=0
DIFFER=()
for skill in "$SRC"/*/; do
  name="$(basename "$skill")"
  dest="$PROJECT/$HUB/$name"

  if [[ -L "$dest" ]]; then
    # Left by an older symlinking install. Not a user edit — migrate it to a real copy.
    rm -f "$dest"; cp -R "${skill%/}" "$PROJECT/$HUB/"; migrated=$((migrated + 1))
  elif [[ ! -e "$dest" ]]; then
    cp -R "${skill%/}" "$PROJECT/$HUB/"; added=$((added + 1))
  elif diff -rq -x '.DS_Store' "${skill%/}" "$dest" >/dev/null 2>&1; then
    same=$((same + 1))
  elif [[ "$UPDATE" == 1 ]]; then
    rm -rf "$dest"; cp -R "${skill%/}" "$PROJECT/$HUB/"; updated=$((updated + 1))
  else
    DIFFER+=("$name")
  fi
done

[[ $added    -gt 0 ]] && echo "  ✓ $added added        → $HUB/"
[[ $migrated -gt 0 ]] && echo "  ✓ $migrated migrated     (symlink → real copy)"
[[ $updated  -gt 0 ]] && echo "  ✓ $updated updated      (--update: source version taken)"
[[ $same     -gt 0 ]] && echo "  = $same unchanged"

# Commands this project has that the source no longer ships. Yours now — never removed.
EXTRA=()
for dir in "$PROJECT/$HUB"/*/; do
  [[ -e "$dir" ]] || continue
  n="$(basename "$dir")"
  [[ -d "$SRC/$n" ]] || EXTRA+=("$n")
done

for dir in "${TARGETS[@]}"; do
  mkdir -p "$dir"
  c=0
  for cmd in "$PROJECT/$HUB"/*/; do
    [[ -e "$cmd" ]] || continue
    n="$(basename "$cmd")"
    # -n so an existing symlink is replaced rather than nested in itself.
    ln -sfn "../../$HUB/$n" "$dir/$n"
    c=$((c + 1))
  done
  echo "  ✓ $c links → ${dir#$PROJECT/}"
done

# --- the decision this script refuses to make for you ------------------------
if [[ ${#DIFFER[@]} -gt 0 ]]; then
  echo
  echo "  ! ${#DIFFER[@]} command(s) differ from the source. Nothing was overwritten."
  echo "    Either you edited your copy, or the source moved on — only you can tell:"
  echo
  for n in "${DIFFER[@]}"; do
    printf '      %-10s diff -ru %s %s\n' "$n" "$HUB/$n" "${SRC/#$HOME/~}/$n"
  done
  echo
  echo "    Read the diffs, then re-run with --update to take the source version"
  echo "    (your edits are lost), or keep yours and ignore this."
fi

if [[ ${#EXTRA[@]} -gt 0 ]]; then
  echo
  echo "  · ${EXTRA[*]} — in this project, not in the source. Left alone; they are yours."
fi

if [[ "$MODE" == init ]]; then
  if [[ -e "$PROJECT/references/SKILL.md" ]] && \
     ! grep -q 'Stub from install.sh' "$PROJECT/references/SKILL.md" 2>/dev/null; then
    echo
    echo "  ! references/SKILL.md already exists and is not a stub."
    echo "    This project wants adopt mode — /setup will detect that and wire the"
    echo "    commands into the index you already have. Nothing was overwritten."
  fi
  scaffold
elif [[ ! -e "$PROJECT/references/SKILL.md" ]]; then
  echo
  echo "  ! no references/SKILL.md here — adopt mode has nothing to wire into."
  echo "    Re-run with --init to scaffold the layer, or point /setup at the docs"
  echo "    this project keeps somewhere else."
fi

# --- next -------------------------------------------------------------------
cat <<EOF

Done. Next step — open your agent in that project and run:

  Claude Code   /setup
  Codex         \$setup

It reads the codebase, then does the half this script can't:

EOF

if [[ "$MODE" == init ]]; then
  cat <<'EOF'
  init   fills the stubs above from your real code — the index, architecture,
         conventions, and the feature-doc template — for you to correct.
EOF
else
  cat <<'EOF'
  adopt  reads your references/SKILL.md, finds what already plays each role, and
         proposes the edit that routes the commands to it. Your index stays yours.
EOF
fi

cat <<'EOF'

Then the rest:
  Claude Code   /plan   /build   /inspect   /commit   /release
  Codex         $plan   $build   $inspect   $commit   $release

Everything installed belongs to the project — commit all of it:

  references/development/commands/   the commands, real files, yours to edit
  .claude/skills/                    relative symlinks into commands/
  .agents/skills/                    relative symlinks into commands/

Both symlink hops stay inside the project, so a teammate who clones the repo
has the commands without running this script.
EOF
