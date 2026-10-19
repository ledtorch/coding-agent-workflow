# The feature doc

**Read by `/setup`.** It writes `references/features/example.md` from this — tailored to the
project it is setting up, citing that project's real files, not these generic ones. Nothing
here is copied verbatim; this is the shape and the reasoning behind it.

The file `/setup` produces stays in place as the project's own template. Every feature doc
written afterwards follows it: one doc per feature, and a feature earns one when someone
would otherwise have to read three files to answer "what is supposed to happen here."

---

## What a feature doc is

**A contract, not a description.** The code already describes itself; re-narrating it produces
a file that goes stale the first time someone refactors and helps nobody in between. Write
what must hold — the invariants, the boundaries, the decisions and why they went that way.

| Write this                                                                                                             | Not this                                               |
| ---------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------ |
| "Both paths return the same `AuthResponse`."                                                                           | "The login function calls the API and sets the token." |
| "Dismissal requires `animationDone && webViewReady`, unless the 6-second cap forces both."                             | "There is a timer that dismisses the overlay."         |
| "Never add a handwritten 401 after soft resolution — soft swallows errors and can misclassify an outage as anonymous." | "Use `resolve_viewer` for auth."                       |

The test: **would this line still be true after a refactor that changed every function name?**
If yes, it belongs. If no, it belongs in the code.

**Point at canonical code, never copy it.** When one file owns a rule, name it and forbid
rederiving it: *"Canonical implementation is `handles.py`. Never rederive its regex,
normalization, reserved list, or limits."* A copied regex is a second source of truth that
drifts silently.

## The skeleton

Sections are a menu, not a mandate — take the ones the feature has. Order matters: framing,
then the flow, then the contracts, then what isn't done.

```markdown
# <Feature name>

<2–4 dense sentences: what this is, who owns what, and what this document owns.
Name the boundary explicitly — "Supabase owns OTPs/sessions; the app stores tokens."
If a sibling doc owns an adjacent concern, say so here and link it.>

Status: <shipped | live | partial — and what "partial" excludes>

Related sources:
- <sibling feature doc, and what it owns instead>
- <schema / SQL file>
- <architecture.md §N for the boundary this depends on>

## Architecture

<An ASCII flow in a ```text fence. Every feature with more than one hop gets one —
it is the highest-value thing in the doc, and the fastest thing to check against reality.>

<Then the invariants the diagram can't show: what is ordered, what is idempotent,
what races and what guards it.>

## <The surfaces — UI, endpoints, jobs, whatever this feature is made of>

<Tables. See below for the shapes that recur.>

## <Data and platform boundaries>

<What state lives where, what survives a logout / restart / reinstall, and which
platform behaves differently. Anything a change here could silently break elsewhere.>

## Open work

<What is designed but unbuilt, what is known-broken, what was deferred and why.
A doc that only describes the working parts is the one that gets trusted wrongly.>

---

**Last Updated**: YYYY-MM-DD
```

## The tables that carry the weight

Five shapes cover almost everything. Reach for a table the moment prose starts listing.

```markdown
| Method | Endpoint | Contract |          ← APIs: one row per route, contract not description
| Signal | Source | Effect |              ← coordination: what fires, from where, what it forces
| Layer | Owns |                          ← responsibility splits, the antidote to "who does X"
| Rule | Contract |                       ← validation, naming, limits
| Condition | Contract |                  ← recovery, edge cases, failure handling
```

## Maturity markers

A doc mixing shipped behavior with intended behavior misleads every reader unless it marks
which is which. Two ways, pick one and use it consistently:

- **Whole-doc:** `Status: shipped` in the framing paragraph. Use when the feature is one thing.
- **Per-section:** 🟢 live · 🔵 intent, not built · 🟠 under revision, target conflicts with runtime.
  Use when a design doc runs ahead of the code.

Then state the tie-break once, plainly: **code is runtime truth; this document is design-intent
truth.** Without that line, a 🔵 section reads as a bug report.

## Wiring

A feature doc that doesn't connect is a file nobody finds.

| Wire                           | How                                                                                                                                                                            |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Into `references/SKILL.md`** | Add one line under Features, grouped with its neighbours. A doc missing from the router is invisible to every command.                                                         |
| **To `architecture.md`**       | Link the section that owns the boundary you depend on (`architecture.md §6.1`). If your feature *creates* a load-bearing boundary, add it there — don't describe it only here. |
| **To `conventions.md`**        | Cite rules by number when behavior depends on one. If the feature needs a rule that doesn't exist, that's a conventions change, not a paragraph here.                          |
| **To siblings**                | Where two docs touch, each names the other and says which owns what. Two docs claiming one concern is the drift `/inspect` exists to catch.                                    |
| **To code**                    | `file:line` for canonical instances and known violations alike. A named path is checkable; "the auth service" is not.                                                          |

## Rules

1. **Verify before writing.** `grep` every file, route, flag, and constant you name. Docs drift
   in the specific direction of understating scope — re-derive counts, don't repeat them.
2. **Update in the same pass as the behavior.** A change that makes this doc wrong is not done
   until the doc is fixed. Bump the footer date.
3. **The `**Last Updated**` footer is mandatory.** A doc without one is a bug, not a style choice.
4. **One word per concept.** If the code says `Moment`, the doc says Moment — never "entry",
   "item", or "stop" as a casual synonym.
5. **Record known violations, don't hide them.** *"Known violation: `AddPlacePreview.vue:187`
   posts multipart directly."* An honest exception list is what makes the rule trustworthy.
6. **Flag conflicts instead of resolving them silently.** If the code contradicts this doc,
   both are suspect — say so and let a human pick.
7. **No parallel docs.** If a concern already has a home, link it. Never open a second one.

## Before saving

- [ ] Framing paragraph states what this doc owns — and what it doesn't
- [ ] Every named file, route, and flag verified against the code
- [ ] Flow diagram matches the current implementation, not the original design
- [ ] Shipped and intended behavior distinguishable at a glance
- [ ] Listed in `references/SKILL.md`
- [ ] Boundaries cross-linked to `architecture.md`; rules cited by number from `conventions.md`
- [ ] Open work section exists, even if it says "none"
- [ ] `**Last Updated**` footer present and today's date

---

**Last Updated**: 2026-10-19
