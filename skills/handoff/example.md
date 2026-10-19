# Handoff — worked examples

Worked examples from a real project, for people reading this command. Illustrations only — not rules, and not read by the command.

## Ground truth — at write time, item 2

Claims checked against the tree before emitting: section anchor `architecture.md §Content collection`,
count "39 cases green".

## Section 1 — Read first

### Baseline descriptions

- `references/development/conventions.md` — code rules, styling tokens, architecture rules
- `references/development/architecture.md` — stack, project structure, content-collection contract

### Conditional attachments

| Session touched…                       | Attach                                 |
| -------------------------------------- | -------------------------------------- |
| The content collection or a case study | `architecture.md` § Content collection |
| Motion, reveals, transitions           | `references/development/animation.md`  |
| Deploy, the server, DNS, TLS           | `references/ops/deploy.md`             |

## Section 2 — What shipped, "Include"

- Architecture decision: *"switched Adapt response to SSE with `targets`/`result` event split"*
- Discovery: *"`structuredClone` fails on Vue reactive Proxies — must use JSON round-trip in stores"*

## Section 3 — Where to look, "Promised but deferred"

> anything the user explicitly said "later" or "post-demo" about.

## Argument handling

> `/handoff .claude/handoffs/2026-05-23-journey-sse.md`

**Last Updated**: 2026-10-19
