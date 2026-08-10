---
description: Cut a release — clean the tree via /commit, push, tag vX, emit raw GitHub release notes, then deploy. Stops and reports on any blocker.
allowed-tools: Read, Grep, Glob, Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git rev-list:*), Bash(git tag:*), Bash(git push:*), Bash(git add:*), Bash(git commit:*), Bash(git cat-file:*), Bash(git ls-remote:*), Bash(gh:*), Bash(grep:*), Bash(cat:*), Bash(npm:*)
---

## Context

- Current git status: !`git status --short`
- Current branch: !`git branch --show-current`
- Existing tags: !`git tag -l | tail -5`

## Charter

**Cut release `$ARGUMENTS` end-to-end: clean tree → push → tag → release notes → deploy.**
One invocation = one release. Every gate below either passes or **stops the run with a
report** — a partial release (e.g. tagged but not deployed) is worse than no release.

`$ARGUMENTS` is the tag name, e.g. `/release v1.2.0`. Required — never infer or
auto-increment.

> **This is a static site.** There is no app binary, no store build, and no version string
> that has to agree across build configs — so there is no version-match gate. The tag is
> the only version that exists. If `package.json` is ever brought under real versioning,
> add the check back here in the same pass.

## Workflow

### 1. Preflight — all three must pass, else report and stop

- **Tag is new:** `$ARGUMENTS` exists neither locally (`git tag -l`) nor on the remote
  (`git ls-remote --tags origin`). Never re-tag or move a tag.
- **On `main`,** no rebase/merge in progress, not detached.
- **No secret-shaped files** anywhere in the pending changes (`.env*`, `deploy.env`,
  `*.key`, `*.pem`, credentials). Found one → report and stop.

### 2. Clean the tree — via the /commit flow, never blind

If `git status` is dirty, run the full [`/commit`](./commit.md) workflow: group the
changes by topic, propose the commit message(s), and **wait for Y**. The proposal + Y is
the explicit per-commit ask the standing rule requires — `/release` never bypasses it
with `git add -A`.

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
  the step-4 **Title**, so lead it with the release's verdict rather than burying it behind
  a feature list — if the body's lede lands on *"the Webflow export is gone"*, the tag
  should too. Same verdict, different words: the body never repeats this line (step 4,
  output contract).
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
   site is**: a new kind of page, a rebuild, a structural change to how content works.
   Ordinary content-and-fix releases skip it and open on the stat line.
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
   what moved in that area: `### 📄 Case studies — the flagship study lands`. **Take the emoji from
   the table below** — a theme that changes glyph between releases reads as a different
   area to anyone skimming the tag list.
4. **Bullets are `- **<claim>** — <evidence>`.** The bold lead-in is the takeaway; the text
   after the em-dash is what makes it true. Name real identifiers in backticks
   (`ProjectCard.astro`, `content.config.ts`, `--column`). Keep the concrete deciding fact —
   *"openrsync has no `--chmod`, so permissions are set locally"* is the line that makes a
   decision legible. Parentheses carry caveats.

**Section emoji — one glyph per theme, fixed across releases**

| Emoji | Theme | Covers |
|---|---|---|
| 📄 | **Case studies** | the content collection, project pages, case-study copy |
| 🏠 | **Home & nav** | the project grid, tiles, the catalogue, contact |
| 🎨 | **Design system** | tokens, typography, shared components, layout primitives |
| 🎬 | **Motion** | scroll reveals, transitions, video tiles |
| ⚡ | **Performance** | images, fonts, video encoding, build output size |
| ♿ | **Accessibility** | alt text, heading order, focus, reduced motion |
| 🔎 | **Discoverability** | metadata, OG cards, canonicals, sitemap, robots |
| 🔧 | **Infrastructure** | deploy, nginx, TLS, DNS, the scripts |
| 📚 | **Docs & commands** | `references/`, the slash commands |
| 🐛 | **Fixes** | bugs with no home above — use sparingly, prefer the owning theme |

Rules: **pick from this table, never invent a glyph.** A release uses only the themes its
log actually contains — an empty theme is omitted, never included with filler. A fix
belongs in its owning theme (a tile-blurb size fix is 🎨, not 🐛); 🐛 is the leftover bin,
and a long 🐛 section means the fixes were mis-filed. Genuinely new area → add a row here
in the same pass, so the next release inherits it instead of re-deciding.

**Content rules**

- Fold refactors into the feature line they serve; omit chore commits.
- When a decision was made, give the *why* and what it ruled out — a reader should finish
  the bullet knowing what the alternative cost.
- Group by what a visitor or the next engineer would go looking for, not by scope prefix.
- Experiments that were run and rejected are release content, not noise. Say so.

**Style reference A — with a key recap.** Note it starts on the lede, no title above it:

```markdown
**The Webflow export is gone.** This release rebuilds the site in Astro, replacing 57KB of
generated CSS and a jQuery dependency with hand-written tokens, moves the four case studies
into a **typed content collection**, and cuts the font payload from **2.3MB to 305KB**.

_2 commits · 2026-08-07 → 2026-08-07_

### 🎨 Design system — tokens replace the Webflow bundle
- **Hand-written token layer** — colour, type scale and the 991/767/479 breakpoints lifted
  from the export into `global.css`; fixed widths became max-widths, which removes the
  horizontal scrollbar the original had between 992px and 1285px.

### 🎬 Motion — IX2 replaced by one inline observer
- **33 hidden elements now revealed by IntersectionObserver** — kept inline and
  self-contained because `.reveal` starts at `opacity:0`: a separate bundle that failed to
  load would leave the content invisible. Three fallbacks — `no-js`, reduced-motion, and a
  `load` backstop for anything already above the fold.
```

**Style reference B — no key recap.** The ordinary case:

```markdown
_11 commits · 2026-08-08 → 2026-08-09_

### 📄 Case studies — the flagship study lands
- **Card-only projects are now a real schema shape** — a project with no `cover` builds no
  page and must set `href`, enforced by a refinement, so a half-filled case study fails the
  build instead of rendering with holes.
```

**Output contract — emit exactly two labelled fenced blocks, in this order:**

**1. Title** — one line, the tag one-liner. Goes in GitHub's *Release title* field.

**2. Note body** — the lede paragraph onward, or the stat line onward when the release
didn't earn a recap. Goes in GitHub's *Describe this release* field.

Two blocks, never one, so each pastes into its own field with no editing.

> **The body must not double the title.** Title and body are different artifacts: the
> title compresses, the body explains. They agree in *theme* — if the title lands on
> "the Webflow export is gone", the body's lede opens on that same verdict — but never in
> *wording*. A reader who sees both should never read the same sentence twice. Concretely:
> no `# vX` heading, no `(YYYY-MM-DD)`, and the lede's first sentence is written fresh
> rather than pasted from the title. **The title is always required** — it carries the
> compression when the body has no recap.

Publishing: if the `gh` CLI is available, offer
`gh release create vX --title "<title>" --notes-file <body>` — but **ask before
publishing** (it's outward-facing). No `gh` → print
`https://github.com/<owner>/<repo>/releases/new?tag=vX` and note both pastes are manual.

### 5. Deploy

A tag that never reaches the server is a changelog, not a release. Offer:

```bash
./deploy.sh --dry-run   # show the exact file list
./deploy.sh             # build, confirm, upload, verify
```

**Ask before running the real deploy** — it is outward-facing and uses `--delete`. Report
what the script's own HTTP check returned; "deployed" without that 200 is a claim, not a
result. Anything pushed by `/push-doc` that is not in `public/` is removed by this deploy —
say so if such a file exists.

## Never

- Never tag or push with a dirty tree — step 2 is not skippable.
- Never `git add -A` without the /commit proposal + Y.
- Never `--force`, never move/delete an existing tag, never amend.
- Never publish the GitHub release, or deploy, without an explicit yes in this session.

## Report (end of run)

- Tag + pushed refs (or the blocker that stopped the run and how to unblock).
- **Two labelled blocks: (1) Title, (2) Note body** — per step 4's output contract. Never
  merge them, and never let the body restate the title.
- Where they go (gh command offered, or the manual releases/new URL).
- Deploy result — the HTTP status the script reported, or that it wasn't run.

---

**Last Updated**: 2026-08-09
