# Setup — worked examples

Worked examples from a real project, for people reading this command. Illustrations only — not rules, and not read by the command.

## SKILL.md

### Step 1 — Say which mode you detected, in one line

> *"Astro 5 + TypeScript, 34 files under `src/`, `references/SKILL.md` already written —
> adopt: I'll wire the commands into it rather than write my own."*

### Step 2B §2 — `architecture.md`, the data contract

The data contract named in that project was a **content collection** (Astro's typed content
store), alongside schema and API shape.

## feature-doc.md

### What a feature doc is — "Write this / Not this"

| Write this                                                                                                             | Not this                                               |
| ---------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------ |
| "Both paths return the same `AuthResponse`."                                                                           | "The login function calls the API and sets the token." |
| "Dismissal requires `animationDone && webViewReady`, unless the 6-second cap forces both."                             | "There is a timer that dismisses the overlay."         |
| "Never add a handwritten 401 after soft resolution — soft swallows errors and can misclassify an outage as anonymous." | "Use `resolve_viewer` for auth."                       |

### Point at canonical code, never copy it

> *"Canonical implementation is `handles.py`. Never rederive its regex, normalization,
> reserved list, or limits."*

### The skeleton — framing paragraph

> "Supabase owns OTPs/sessions; the app stores tokens."

### Wiring — to `architecture.md`

> Link the section that owns the boundary you depend on (`architecture.md §6.1`).

### Rules 4 — One word per concept

> If the code says `Moment`, the doc says Moment — never "entry", "item", or "stop" as a
> casual synonym.

### Rules 5 — Record known violations

> *"Known violation: `AddPlacePreview.vue:187` posts multipart directly."*

**Last Updated**: 2026-10-19
