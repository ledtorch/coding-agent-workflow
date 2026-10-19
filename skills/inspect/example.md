# Inspect — worked examples

Worked examples from a real project, for people reading this command. Illustrations only — not rules, and not read by the command.

## Step 0: Required reading

The project's conventions doc had nine numbered rules: "`references/development/conventions.md` — Rules 1–9".

## D2 — Duplicated values

The project's `architecture.md` listed its shared code↔data pairs in §9: "Cross-check `architecture.md` §9 — a pair that belongs there and isn't is itself a finding."

## D5 — Logic bugs

The list of logic-bug classes was ranked by what actually bit in that codebase.

## D6 — Cost and boundaries

The quantification example came from a profile view: "one query per row, ~40 rows on the profile" beats "this could be slow."

## What the target's *kind* obliges

The table as it was written for a Vue front end with a FastAPI back end:

| Target kind         | Must hold                                                                                                                                                                   |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| View or route       | Route registered and its `name` matches the file · back-stack and origin-return behave (`features/view-return.md`) · deep-link entry works                                  |
| Store               | Registered wherever the project resets user state on sign-out · persisted drafts carry the project's save-guard · storage key follows the project's versioned naming scheme |
| Composable          | Category matches its return shape — data vs behavior (Rule 4) · no side effects on import · singletons marked                                                               |
| Component           | State at the narrowest scope (Rule 1) · no direct `fetch` (Rule 3) · overlay prefix matches its surface (Card / Sheet / Modal)                                              |
| Endpoint            | Handler is async · response model declared · 404-not-403 posture where the code shouldn't be confirmed · auth resolved the same way as its siblings                         |
| Schema or migration | Every application-enforced rule backed by a constraint, or the asymmetry recorded · pending migrations still pending                                                        |

"Dependencies point inward at every kind (Rule 2)."

## Step 4: Evidence

The three mandatory proofs were introduced as "Three proofs are mandatory, because each has burned this repo".

**Last Updated**: 2026-10-19
