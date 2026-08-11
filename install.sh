#!/usr/bin/env bash
#
# Install the workflow skills into a project, for Claude Code and/or Codex.
#
#   ./install.sh /path/to/project            # both agents
#   ./install.sh /path/to/project claude      # Claude Code only
#   ./install.sh /path/to/project codex       # Codex only
#   ./install.sh --user                       # install for every project (home dir)
#
# Skills are SYMLINKED, not copied — `git pull` in this repo updates every project
# at once. Both agents follow symlinked skill folders.
#
# Targets:
#   Claude Code   <project>/.claude/skills/<name>   → /<name>
#   Codex         <project>/.agents/skills/<name>   → $<name>
#   --user        ~/.claude/skills, ~/.agents/skills
#
# One source file per command lives at skills/<name>/SKILL.md. `commands/` holds
# symlinks to the same files for the older `.claude/commands` install; you do not
# need it if you use this script.

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/skills"
[[ -d "$SRC" ]] || { echo "no skills/ next to this script — wrong checkout?" >&2; exit 1; }

if [[ "${1:-}" == "--user" ]]; then
  AGENT="${2:-both}"
  CLAUDE_DIR="$HOME/.claude/skills"
  CODEX_DIR="$HOME/.agents/skills"
  WHERE="your home directory (all projects)"
else
  PROJECT="${1:-}"
  AGENT="${2:-both}"
  [[ -n "$PROJECT" ]] || { sed -n '3,12p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }
  [[ -d "$PROJECT" ]] || { echo "not a directory: $PROJECT" >&2; exit 1; }
  PROJECT="$(cd "$PROJECT" && pwd)"
  CLAUDE_DIR="$PROJECT/.claude/skills"
  CODEX_DIR="$PROJECT/.agents/skills"
  WHERE="$PROJECT"
fi

case "$AGENT" in
  claude) TARGETS=("$CLAUDE_DIR") ;;
  codex)  TARGETS=("$CODEX_DIR") ;;
  both)   TARGETS=("$CLAUDE_DIR" "$CODEX_DIR") ;;
  *) echo "unknown agent: $AGENT (use claude | codex | both)" >&2; exit 2 ;;
esac

echo "→ installing into $WHERE"

for dir in "${TARGETS[@]}"; do
  mkdir -p "$dir"
  n=0
  for skill in "$SRC"/*/; do
    name="$(basename "$skill")"
    # -n so an existing symlink is replaced rather than nested inside itself.
    ln -sfn "$skill" "$dir/$name"
    n=$((n + 1))
  done
  echo "  ✓ $n skills → ${dir/#$HOME/\~}"
done

cat <<'EOF'

Done. Invoke them as:
  Claude Code   /plan   /build   /inspect   /commit   /release
  Codex         $plan   $build   $inspect   $commit   $release

Codex also picks a skill implicitly when your request matches its description —
say "audit this file for dead code" and $inspect can trigger on its own.

⚠️  These commands assume a `references/` directory in your project holding the
docs they route through (SKILL.md index, conventions.md, architecture.md). See
the README — the commands are written to be edited, not used verbatim.
EOF
