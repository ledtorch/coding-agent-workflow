# Build — worked examples

Worked examples from a real project, for people reading this command. Illustrations only — not rules, and not read by the command.

## Scope

- `/build references/build-place-contact-action.md` → **all** remaining unchecked tasks, in plan order, until done or interrupted.
- `/build references/build-place-contact-action.md 3` → **Task 3 only**, dependencies permitting, then stop.

## B.0 Required reading

- `references/development/conventions.md` — code rules, design tokens, component patterns.
- `references/development/architecture.md` — where the code goes, and the content-collection contract.

## The run loop

Step 6: "New shared code↔doc data pairs go in architecture.md §9."

## Verification

The project was a static site built from a content collection, with no test runner ("There is **no test-runner in this repo** — don't claim 'tests pass.'") and a `deploy.sh` script. Its table:

| Surface                              | Check                                                                                                                                                                  |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Any change                           | `npm run build` — must complete clean and build the expected page count                                                                                                |
| Content collection                   | A schema violation fails the build. Confirm the page count changed the way you intended — a card-only project builds no page                                           |
| Anything observable                  | Drive it in the Browser pane and read the result back. A screenshot of the changed state is the proof                                                                  |
| Layout / responsive                  | Measure with `getComputedStyle` at 1280 / 900 / 600 / 400, don't eyeball a screenshot. Confirm `document.documentElement.scrollWidth <= innerWidth`                    |
| Images                               | Check the emitted `srcset` and that `sizes` holds no CSS variable — the attribute is parsed by the preload scanner, which knows nothing about custom properties        |
| Anything behind IntersectionObserver | The Browser pane suspends the rendering lifecycle when hidden, and IO delivery with it. `document.visibilityState` is the first thing to check before believing a zero |
| Deploy                               | `./deploy.sh --dry-run` shows the exact file list. Never claim deployed without the HTTP 200 check the script runs                                                     |

**Last Updated**: 2026-10-19
