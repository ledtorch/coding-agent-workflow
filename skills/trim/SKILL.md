---
name: trim
description: Trim a named file to its smallest, highest-signal form — zero information loss, behavior identical.
---


## Input

The text after the command — `/trim <file-path>` (Claude Code) or
`$trim <file-path>` (Codex). Called **the target file** below.

## Context (gather first)

Run these and read the output:

```
git branch --show-current
git status --short
```

## Charter

**Distill the named target to its smallest, highest-signal form — losing nothing
actionable.** Fewer lines, one home per fact, no dead weight. Observable behavior, public
contracts, and types come out identical.

Test for any change: *does this leave less text AND the same actionable content?* If it
grows the file, it isn't `/trim`. If it changes what the user observes, it isn't `/trim`.

**Performance is a side effect, never the goal.** You MAY fix obviously wasteful runtime
work — a redundant loop, a value recomputed every call — but **only when the fix also
removes code**. Never add memoization, caching, lazy-loading, or virtualization here.

> **Do not re-add:** no mode/pass selector — audit mode was removed with its methodology
> doc (`development/refactor.md`; git has it). The `refact` **commit type** and the
> `references/refact-<slug>.md` plan prefix ([plan.md](../plan/SKILL.md)) are code-refactor terms,
> unrelated to this command's rename from `/refact` — keep both.

## Scope (the target file)

**The target path(s)** is the whole input, nothing else. `/trim references/development/conventions.md`
trims that file. No mode token, no pass selector.

- **Edits ONLY the explicitly named target(s)** — never adjacent files, never "trim everything."
- **No target given** → ask which file. Never guess.
- If a cut would require changing a file *outside the target set* (a `§ref` others cite, a
  symbol others import), say so and stop — that's a separate change. Between targets in the
  same set, cross-file moves are allowed and mapped (below).

State the target(s) + line counts in one line so the user can interrupt.

### Multiple targets: map first, then trim as a group

N targets is **one group trim, not N solo trims.** Before any edit, build a **trim map** —
[plan.md](../plan/SKILL.md) Step 3 in miniature, over the target set:

- **Cross-file restatements (P3 across files).** A fact restated in several targets gets ONE
  home in the whole set; every other target keeps a one-line pointer. Solo-trimming each file
  would keep N "best homes."
- **Refs between targets.** List every `§ref`/anchor/`file:line` one target uses to cite
  another — a heading renamed in file A silently breaks file B's pointer mid-trim.
- **Order.** Trim the fact's home file first, pointer files after — a pointer can't be
  written to a home that hasn't settled.

T.0's load-bearing-fact list, the T.4 gate, and T.5 verification all run over the **set as a
whole**: a fact that vanished from file A survives only if its home in file B still holds it.


## T.0 The one rule: zero information loss

Brevity is the means, not the goal. Every **actionable fact** must survive — `file:line`
references, contracts, invariants, decisions, exact steps, acceptance checks, safety
guards, behavior, edge cases.

**Before writing, list the load-bearing facts. After writing, confirm each still appears.**
If a cut would drop a fact, don't cut it.


## T.1 The meta-pattern

Files bloat because **the author defends accuracy inline.** Every qualification,
restatement, and date was added so a reader couldn't misread *that sentence in isolation*.
That's why a bloated doc is usually *correct* — and why it resists editing.

The fix is almost never deleting facts. It's **giving each fact one home and pointing at
it.** Most of T.2 dissolves into that one move.


## T.2 The eleven bloat patterns

Run the detection command, then judge. A hit is a candidate, not a verdict.

> **Tooling note:** `rg` is aliased to `ugrep` in this repo, where `-E` means *encoding* and
> throws `unknown encoding`. Use **`grep -oE`** for regex extraction; `rg` is fine for plain
> literal search.

### P1 — Wall-of-text: one paragraph carrying many unrelated facts
A 400+ word paragraph holding a dozen independent facts can't be updated without re-reading
all of it, and nothing inside it can be linked.

```bash
awk 'BEGIN{RS="\n\n"} {n=split($0,w," "); if(n>150) print n" words — para "NR}' TARGET | sort -rn | head
```
**Fix:** split into a heading + one bullet per concern. The content is fine; the container is wrong.

### P2 — The file re-implements a source of truth it names
A doc that says "X is authoritative" and then enumerates X's contents will drift from X.

```bash
grep -oE '\*\*[0-9]+ (columns|fields|routes)\*\*|[0-9]+ → [0-9]+ (columns|fields)' TARGET
```
**Fix:** delete the enumeration; keep the pointer plus only the *non-obvious* notes (why an
odd ordering, why a generated column exists).
**Canonical instance:** moment.md claimed "24 columns" in one section and "26 → 27 columns"
in another while `moment.sql` had 27 — a contradiction inside one file.

### P3 — One fact restated N times
```bash
for pat in "<core term 1>" "<core term 2>"; do printf '%-40s %s\n' "$pat" "$(grep -ci "$pat" TARGET)"; done
```
**Fix:** find the fact's best home (usually an existing table), leave a one-line pointer
everywhere else. **Threshold: 3+ full restatements.** A short summary + pointer is fine and
is not a restatement.

### P4 — Decision archaeology
A reference doc records the **current fact**, not the log of how it got there — something
dropped should simply go unmentioned. Archaeology rarely announces itself with "Why"; it hides
as a bare assertion or a trailing parenthetical: "NO author_role gate (dropped 2026-06-22,
owner; a future `quality` column filters)".

```bash
grep -inE '(was|were) (dropped|removed|retired|deleted|renamed|superseded)|supersedes|reverses the|no longer|(dropped|removed|retired|deleted) [0-9]{4}-[0-9]{2}-[0-9]{2}' TARGET
```
**Fix:** keep only what absence would break — a **one-line guard** ("There is no `topic`
field; do not add one", collected in a `## Do not re-add` list) or a ⚠️ known-gap — and drop
the litigation. **Exceptions:** reasoning a live decision still hinges on, and a precedence
rule while the superseded model is still in the doc (journey.md's "Supersedes the older
'3 components' model in §Architecture where they conflict" — the reader must know which wins).

### P5 — Changelog embedded in contract prose
```bash
grep -inE '(fixed|added|changed|decided|revised|removed|renamed|dropped|retired|deleted|merged|split|shipped|superseded)[^0-9]{0,30}[0-9]{4}-[0-9]{2}-[0-9]{2}|since [0-9]{4}-[0-9]{2}-[0-9]{2}' TARGET
```
A contract states what *is* true; when it *became* true lives in git.
**Fix:** drop the date. **Exception — keep it when the date is load-bearing:** an unfinished
backfill, a migration window, a deprecation whose removal depends on elapsed time, or rows
still broken from before a fix, where the date bounds the affected content — "case studies
written before 2026-08-08 predate the card-only schema split" stays.

### P6 — `§refs` (or anchors) that point at nothing
```bash
grep -ohE '§[A-Za-z][A-Za-z ’&-]+' TARGET | sed 's/ *$//' | sort -u   # cited
grep -E '^#{2,4} ' TARGET | sed 's/^#* //'                            # actual headings
```
**Fix:** promote the target to a real heading, or stop calling it `§`. Silent dead-ends —
nothing detects these.

### P7 — Bold as texture rather than signal
When ~40% of a paragraph is bold, bold stops meaning "this is the load-bearing bit."
**Fix:** at most one bolded span per idea — the noun the reader must not miss.

### P8 — Comments that earn nothing
Four shapes. Each costs a line, pays nothing, and dilutes the comments that *do* matter:

- **Documents an absence** — "No `@click` here because…". The set of things NOT in a file is
  infinite; you cannot annotate it.
- **Restates the code** — `// increment the counter` above `i++`.
- **Generic platform knowledge** — DOM events bubble, `await` waits, `?.` short-circuits. If
  it's true of every codebase, it isn't project knowledge.
- **Justifies a removal** — see the hard rule in T.4.5.

```bash
grep -nE '(//|<!--|#)\s*(No |Not |Never |Intentionally|Deliberately|on purpose|left out|omitted|no longer needed|don.?t need)' TARGET
```

**Fix:** delete. **Keep** a comment only when it explains a *non-obvious, project-specific
why* — a platform bug, a device quirk, a constraint you'd otherwise have to re-derive.
**Test:** would a competent developer reading the surrounding code already know this? If yes,
cut it.

**Canonical instance:** a trimmer removes a redundant handler and adds
`<!-- No click handler: the glyph is a <button>, so its click bubbles to the card. -->`.
It documents an absence, restates generic DOM behaviour, and sits beside genuinely
hard-won comments (why the reveal observer is inline, why `sizes` cannot take a CSS
variable) — diluting the ones worth reading. Net line saving: zero.

### P9 — CSS that restates an inherited value
A declaration the element already receives from an ancestor renders identically without it.
Only the **inherited** properties can hit this — `color`, `font-*`, `line-height`,
`letter-spacing`, `text-align`, `white-space`, `visibility`, `cursor`, `list-style`.
`background`, `border`, `display`, `padding`, `width` do NOT inherit, so re-declaring those is
never this pattern.

```bash
grep -nE '^\s*(color|font-family|font-size|font-weight|line-height|letter-spacing|text-align|white-space):' TARGET
```

**Prove it before cutting** — a closer ancestor may override, so "the page sets it" isn't
enough. Compare against the real parent in the running app:

```js
const el = document.querySelector('SELECTOR')
getComputedStyle(el).color === getComputedStyle(el.parentElement).color  // true → the rule is a no-op
```

**Fix:** delete the declaration. If it was the rule's only content, delete the rule *and* the
class off the element. `references/development/conventions.md` § Color inheritance is the positive
form: set the dominant `color` on the container, override only the children that differ.

**Keep it** where the element doesn't actually sit under the ancestor it appears to, or where
the ancestor's value isn't always live:
- **Teleported content** — anything inside `<Teleport to="body">` is physically moved out of
  the page, so it inherits from `<body>`, not from the `.page` it reads as being nested in
  (`ModalCityPicker`, `PanelStopEditor`, and the confirm-modal blocks in `MomentComposer` /
  `JourneyExplore` / `JourneyFlightEditor`).
- **Shared / dual-use components** mounted under more than one color context.
- The ancestor sets it behind a **theme or state class**, so the child's value is conditional.

**Canonical instance:** `.photos-title` in `MomentComposer.vue` carried `color: var(--primary)`
while its `.page` ancestor already set exactly that. The class existed *only* to restate an
inherited value, so deleting the declaration took the whole class with it.

### P10 — Figma node ids
`13037:21804`-style node ids are unwanted **anywhere** — docs, todo items, code comments
(`// … (Figma 13292-23033)`). The design file is the source: a frame is found by opening it
by name, not by an id buried in a comment, and the id silently dies when the frame is
recreated. Never write one, and strip every one on sight — in `/trim` this is an
unconditional cut, not a judgment call.

```bash
grep -nE '[0-9]{4,6}[:-][0-9]{4,6}' TARGET
```

**Fix:** delete the numeric id, keep the human name of the surface ("the Location group",
"Segment Control", "JourneyDayHeader"). A named ref keeps the name and drops the id; a bare
`(Figma <id>)` with no name drops the whole parenthetical.

### P11 — A finished todo whose outcome is already a fact in the same doc
A checked box is a *status*, not a fact. Once the outcome is stated where the doc records
facts, the `- [x]` line is a second copy that can go stale on its own. **"[x] done — see
§Status" is the half-measure**: still a line, still a pointer to maintain.

```bash
grep -nE '^\s*[-*]\s*\[x\]|~~[^~]+~~|— *(done|shipped|complete)\b' TARGET
```

**Fix:** confirm the outcome is recorded as a present-tense fact, then **delete the whole
item** — box, evidence, and any closing commentary about the track ("remaining tail is
release cadence"), which dies with the track it described. If the outcome is recorded
nowhere, write it into the fact section first, *then* delete the box — converting the todo,
not dropping it.
**Keep** every unchecked item ([T.3](#t3-what-to-keep-the-signal)), and any `[x]` still
carrying something the fact section doesn't: a residual, a caveat, a known gap.
**Canonical instance:** roadmap.md's Next track held `- [x] Ship to App Store — done: v0.02.3
live, v0.02.4 in review` while Current position already read "v0.02.3 live; v0.02.4 submitted,
in review." Two homes for one status; deleting the box lost nothing.


## T.3 What to keep (the signal)

The precise, load-bearing detail *is* the value:

- **Docs:** exact `file:line` touch-lists, contracts/invariants, locked vocabularies,
  sequenced steps, "do-NOT-touch" guards, done-criteria, ⚠️ known-gap warnings.
- **Code:** working logic, edge-case handling, and any comment explaining a non-obvious
  *why*. Never change behavior, public contracts, or types to save lines.

**Never cut** a known-gap/⚠️ warning, an **unresolved** TODO, or a guard against
re-introducing a removed thing. Those exist *because* someone got it wrong once. (A
*resolved* one is the opposite case — [P11](#p11--a-finished-todo-whose-outcome-is-already-a-fact-in-the-same-doc).)

**But a guard earns its line only when re-introduction causes real harm** — a wrong column, a
silently dropped field, a deleted redirect that blank-pages every old bookmark (follow.md's
two route entries stay: `router.js` has no catch-all). A guard against a *harmless* mistake
(a duplicate idempotent call, a redundant listener) is just a comment: see [P8](#p8--comments-that-earn-nothing).
Don't use "it's a guard" to smuggle one in.


## T.4 Procedure

1. **Read the target fully.** Note its kind (doc vs code) and list its load-bearing facts (T.0).
   Multiple targets: read ALL of them, then build the trim map (Scope) before touching any.
2. **Run T.2's detection commands.** Report what each found — evidence before judgment.
3. **Gate — targets over ~150 lines: propose the structure first.** Post the target outline
   (headings + what moves where + estimated line delta) and wait for approval. Do not
   rewrite hundreds of lines unilaterally.
4. **For code, prove "unused" before deleting** — grep the symbol repo-wide; a thing
   referenced elsewhere is not dead. State what you verified.
5. **Rewrite.** Prefer `Edit` for surgical cuts; `Write` for a full restructure.

   > **HARD RULE — `/trim` NEVER adds a comment to justify what it removed.** If a cut needs
   > defending, either it's the wrong cut, or the defence belongs in the **commit message** —
   > never in the file. A trim that deletes a line and adds a comment about the deletion has
   > saved nothing and spent the reader's attention.
   >
   > This is T.1's failure mode turned on the trimmer: you remove something, feel exposed, and
   > write a defence that costs more than the removal saved. The urge to explain a cut *in the
   > file* is the signal to stop and re-read P8.

6. **Verify (T.5).**


## T.5 Verification

Mandatory before reporting:

- **Every T.0 fact still present.** Walk the list; don't sample.
- **Re-run the T.2 detections** — each flagged instance is resolved or consciously kept.
- **Links/anchors still resolve** (P6 command), including anchors *other* files use to cite
  this one:
  ```bash
  grep -rn "TARGET_BASENAME#" references/ | grep -oE '#[a-z0-9-]+' | sort -u
  ```
  A heading you renamed silently breaks every inbound link.
- **Code:** it still builds/lints by the project's check, and behavior is unchanged.

**Report:** lines before → after, what was cut by category (mapped to P1–P11), what was
deliberately kept and why, and an explicit **"no actionable fact lost"** confirmation. Never
claim a behavior change you didn't make.


**Last Updated**: 2026-07-25
