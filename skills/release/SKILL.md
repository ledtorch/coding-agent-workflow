---
name: release
description: Cut a release — clean the tree via /commit, push, tag vX, emit raw GitHub release notes, then deploy. Stops and reports on any blocker.
---


## Context

Run these first and read the output:

```
git status --short
git branch --show-current
git tag -l | tail -5           # the version series you are continuing
```

## Charter

**Cut the release named by the input, end-to-end: clean tree → push → tag → release notes → deploy.**
One invocation = one release. Every gate below either passes or **stops the run with a
report** — a partial release (e.g. tagged but not deployed) is worse than no release.

The input is the tag name — `/release v1.2.0` (Claude Code) or `$release v1.2.0` (Codex). Required — never infer or
auto-increment.

## Workflow

### 1. Preflight — all four must pass, else report and stop

- **Tag is new:** the tag exists neither locally (`git tag -l`) nor on the remote
  (`git ls-remote --tags origin`). Never re-tag or move a tag.
- **On `main`,** no rebase/merge in progress, not detached.
- **No secret-shaped files** anywhere in the pending changes (`.env*`, `deploy.env`,
  `*.key`, `*.pem`, credentials). Found one → report and stop.
- **Every version source equals the tag.** If the project declares its version anywhere
  (e.g. a package manifest, an app's marketing version), each source equals the tag minus
  `v`. More than one surface ships one version, bumped together in one commit. A mismatch →
  report and stop; don't bump. The tag is the only version → nothing to check.

### 2. Clean the tree — via the /commit flow, never blind

If `git status` is dirty, run the full [`/commit`](../commit/SKILL.md) workflow: group the
changes by topic, propose the commit message(s), and **wait for Y**. The proposal + Y is
the explicit per-commit ask the standing rule requires.

**Blockers → report and stop:** the user rejects the proposal, changes don't group into
committable topics (half-finished work), or anything in /commit's own safety list fires.
"Report" means: name the blocker, list the offending files, suggest the unblock
(finish/stash/discard), and end the run — the user re-invokes `/release` after.

### 3. Push, tag, push the tag

```bash
git push origin main
git tag -a vX -m "vX — <short summary>"
git push origin vX
```

- Tag message is the house one-liner: `vX — two or three comma-separated highlights`.
  Pick highlights from the commit log, favoring user-facing changes. This same line becomes
  the step-4 **Title**, so lead it with the release's verdict, not a feature list (same
  verdict as the body's lede, never the same words — step 4 output contract).
- A rejected push (diverged remote) → report and stop. **Never `--force`.**

### 4. Release notes — raw markdown for GitHub

Build from `git log <prevTag>..vX` (prevTag = the highest existing tag). The stat line is
mechanical, so derive it rather than guessing:

```bash
git rev-list --count <prevTag>..vX          # commit count
git log -1 --format=%ad --date=short <prevTag>   # window start
git log -1 --format=%ad --date=short vX          # window end
```

**Body shape** — the body starts at the lede if there is one, otherwise at the stat line.
Nothing above that: no `# vX` heading, no date line, no restatement of the title.

1. **Key recap — OPTIONAL.** A lede paragraph, and only when the release **changes what the
   project is**: a new kind of surface, a rebuild, a structural change to how it works.
   Ordinary feature-and-fix releases skip it and open on the stat line.
   - When it earns one: open with a **bolded verdict** — the one thing this release decided
     or settled — then one sentence naming the other two or three headline shipments, each
     **bolded** inline. Prose, not a list.
   - **Test:** can you name the thing this release makes possible that was impossible
     before? Yes → write the recap. No → skip it; a recap over an ordinary release inflates
     it and trains the reader to skim the next one.
2. **Stat line — REQUIRED, every release, no exceptions.** Italic, on its own line: the
   lede's next line, or the body's first line when there is no lede.
   `_<N> commits · YYYY-MM-DD → YYYY-MM-DD_`
3. **`### <emoji> <Theme> — <thesis>`** section headers. Themes come from what the log
   actually contains, never from commit types or scope prefixes. The trailing thesis says
   what moved in that area: `### ⚡ Performance — <what moved>`. Emoji from the
   table below. **One blank line before every section header**, including the first after
   the stat line: a header that follows a bullet directly reads as part of the list above it.
4. **Bullets are `- **<claim>** — <evidence>`.** The bold lead-in is the takeaway; the text
   after the em-dash is what makes it true. Name real identifiers in backticks
   (`<Component>`, `src/<area>/<file>`, `--<flag>`). Keep the concrete deciding fact —
   *"`<tool>` has no `--<flag>`, so `<step>` is done locally"* is the line that makes a
   decision legible. Parentheses carry caveats.

**Section emoji — one glyph per theme, fixed across releases**

| Emoji | Theme               | Covers                                                           |
| ----- | ------------------- | ---------------------------------------------------------------- |
| ✨    | **Features**        | new user-facing capabilities                                     |
| 🎨    | **UI & design**     | tokens, typography, shared components, layout, motion            |
| ⚡    | **Performance**     | load time, assets, build output size                             |
| ♿    | **Accessibility**   | alt text, heading order, focus, reduced motion                   |
| 🔎    | **Discoverability** | metadata, OG cards, canonicals, sitemap, robots                  |
| 🔧    | **Infrastructure**  | build, CI, deploy, hosting, the scripts                          |
| 📚    | **Docs & commands** | `references/`, the slash commands                                |
| 🐛    | **Fixes**           | bugs with no home above — use sparingly, prefer the owning theme |

Rules: **pick from this table, never invent a glyph** — a theme that changes glyph between
releases reads as a different area to anyone skimming the tag list. A release uses only the
themes its log actually contains — an empty theme is omitted, never included with filler. A
fix belongs in its owning theme (a component's spacing fix is 🎨, not 🐛); 🐛 is the leftover
bin, and a long 🐛 section means the fixes were mis-filed. Genuinely new area → add a row
here in the same pass, so the next release inherits it instead of re-deciding. A project
adds a row for each product area of its own (e.g. `<area>`), each with its own fixed glyph.

**Content rules**

- Fold refactors into the feature line they serve; omit chore commits.
- When a decision was made, give the *why* and what it ruled out — a reader should finish
  the bullet knowing what the alternative cost.
- Group by what a user or the next engineer would go looking for, not by scope prefix.
- Experiments that were run and rejected are release content, not noise. Say so.

**Style reference A — with a key recap:**

```markdown
**<The one thing this release settles>.** This release <headline change>, moves <area> to
**<new shape>**, and cuts <metric> from **<before> to <after>**.

_<N> commits · YYYY-MM-DD → YYYY-MM-DD_

### <emoji> <Theme> — <thesis>
- **<claim>** — <evidence: the identifier (`src/<area>/<file>`) and the deciding fact that
  makes the claim true>.

### <emoji> <Theme> — <thesis>
- **<claim>** — <evidence> (<caveat>).
```

**Style reference B — no key recap.** The ordinary case:

```markdown
_<N> commits · YYYY-MM-DD → YYYY-MM-DD_

### <emoji> <Theme> — <thesis>
- **<claim>** — <evidence: what now builds, fails or behaves differently, and why>.
```

**Output contract — emit exactly two labelled fenced blocks, in this order:**

**1. Title** — one line, the tag one-liner. Goes in GitHub's *Release title* field.

**2. Note body** — per Body shape above. Goes in GitHub's *Describe this release* field.

Each block pastes into its own field with no editing.

> **The body must not double the title.** Title and body are different artifacts: the
> title compresses, the body explains. They agree in *theme* — if the title lands on
> "<verdict>", the body's lede opens on that same verdict — but never in *wording*. A reader
> who sees both should never read the same sentence twice. The lede's first sentence is
> written fresh rather than pasted from the title. **The title is always required** — it
> carries the compression when the body has no recap.

Publishing: if the `gh` CLI is available, offer
`gh release create vX --title "<title>" --notes-file <body>` — but **ask before
publishing** (it's outward-facing). No `gh` → print
`https://github.com/<owner>/<repo>/releases/new?tag=vX` and note both pastes are manual.

### 5. Deploy

Offer the project's deploy command (from `references/` or its scripts) — its dry run first,
if it has one, to show what will change.

**Ask before running the real deploy** — it is outward-facing and may delete remote files.
Report what the deploy's own verification returned (e.g. an HTTP 200 check); "deployed"
without it is a claim, not a result.

## Never

- Never tag or push with a dirty tree — step 2 is not skippable.
- Never `git add -A` without the /commit proposal + Y.
- Never `--force`, never move/delete an existing tag, never amend.
- Never publish the GitHub release, or deploy, without an explicit yes in this session.

## Report (end of run)

- Tag + pushed refs (or the blocker that stopped the run and how to unblock).
- **Two labelled blocks: (1) Title, (2) Note body** — per step 4's output contract.
- Where they go (gh command offered, or the manual releases/new URL).
- Deploy result — what the deploy's own verification reported, or that it wasn't run.


**Last Updated**: 2026-10-19
