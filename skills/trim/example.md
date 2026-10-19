# Trim — worked examples

Worked examples from a real project, for people reading this command. Illustrations only — not rules, and not read by the command.

## P2 — the file re-implements a source of truth

moment.md claimed "24 columns" in one section and "26 → 27 columns" in another while
`moment.sql` had 27 — a contradiction inside one file.

## P4 — decision archaeology

Archaeology hiding as a trailing parenthetical: "NO author_role gate (dropped 2026-06-22,
owner; a future `quality` column filters)".

A precedence rule that stays while the superseded model is still in the doc: journey.md's
"Supersedes the older '3 components' model in §Architecture where they conflict".

## P5 — changelog embedded in contract prose

A load-bearing date that stays: "case studies written before 2026-08-08 predate the card-only
schema split".

## P8 — comments that earn nothing

"No `@click` here because…" — documents an absence.

A trimmer removes a redundant handler and adds
`<!-- No click handler: the glyph is a <button>, so its click bubbles to the card. -->`.
It documents an absence, restates generic DOM behaviour, and sits beside genuinely
hard-won comments (why the reveal observer is inline, why `sizes` cannot take a CSS
variable) — diluting the ones worth reading. Net line saving: zero.

## P9 — CSS that restates an inherited value

The positive form lived in that project's `references/development/conventions.md`
§ Color inheritance.

Teleported content — anything inside `<Teleport to="body">` inherits from `<body>`, not from
the `.page` it reads as being nested in (`ModalCityPicker`, `PanelStopEditor`, and the
confirm-modal blocks in `MomentComposer` / `JourneyExplore` / `JourneyFlightEditor`).

`.photos-title` in `MomentComposer.vue` carried `color: var(--primary)` while its `.page`
ancestor already set exactly that. The class existed *only* to restate an inherited value,
so deleting the declaration took the whole class with it.

## P10 — Figma node ids

`13037:21804`-style ids, and comments like `// … (Figma 13292-23033)`. The human names kept
instead: "the Location group", "Segment Control", "JourneyDayHeader".

## P11 — finished todo whose outcome is already a fact

roadmap.md's Next track held `- [x] Ship to App Store — done: v0.02.3 live, v0.02.4 in review`
while Current position already read "v0.02.3 live; v0.02.4 submitted, in review." Two homes
for one status; deleting the box lost nothing.

## T.3 — a guard that earns its line

follow.md's two route entries stay: `router.js` has no catch-all, so deleting the redirect
blank-pages every old bookmark.


**Last Updated**: 2026-10-19
