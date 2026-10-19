---
name: label
description: Rename the layer names of a selected Figma frame and its children to clear, role-based names matching the design-system convention — names only
---


## Context

- Naming convention source of truth: [`references/development/conventions.md`](references/development/conventions.md).
- **Convention in one line:** PascalCase, role-based, compound `Category + Qualifier` — same shape as the library components (`<Category><Qualifier>`).
- **Design-system categories** (the prefix vocabulary): the prefixes `conventions.md` defines.

## Purpose

Rename **only the layer names** of one Figma frame and all of its renameable descendants. Give each layer a clear, role-based name that matches the library and design-token convention.

> **Hard invariant — names only.** Never change design, content, text, fills, size, layout, auto-layout, structure, order, or any property other than `name`. If a step would touch anything but a node's `name`, stop and report instead.

## Input

The input — `/label <url>` (Claude Code) or `$label <url>` (Codex) — is a Figma node URL: `https://figma.com/design/:fileKey/:fileName?node-id=:int1-:int2`. Extract `fileKey` and `nodeId` (convert `1-2` → `1:2`).

If no URL is given, operate on the **current selection** (`get_selection`). If neither resolves, ask for a node-specific URL.

## Tooling

- **Default: official Figma MCP** — works directly from the file key, no plugin channel.
  - Read structure: `get_metadata` (tree overview) → `get_design_context` (screenshot + roles).
  - Read live names + rename: `use_figma` (runs Figma Plugin API JS). **Load the `figma-use` guidance before the first `use_figma` write call** (`/figma-use` skill, or the `skill://figma/figma-use/SKILL.md` resource).
- **Fallback: TalkToFigma** — only for live-selection work; needs the "Talk to Figma" plugin open and a `join_channel`.

## Workflow

1. **Resolve target** (see Input).
2. **Read the subtree** — dump every descendant's `id`, `type`, `name`, and (for text) `characters`. Pull the screenshot for visual role, and the parent's siblings to learn how this file already names peers.
3. **Classify each node:**
   - **Renameable** — frames, groups, text, vectors, and **instance roots** you own.
   - **Instance-internal — DO NOT rename.** Any node whose id contains `;` (e.g. `I1:2;3:4`). Its name comes from the source component and can't be overridden on the instance. Skip and list as skipped.
   - **Already correct** — a layer already matching the convention (e.g. `<Category><Qualifier>`). Leave it; note "unchanged."
4. **Derive role-based names** — name by *what the layer is for*, not its template default (`Frame 13`, `Data`, `Group 2`, a full sentence). Match the convention above. Common roles: `Title`, `Body`, `TextGroup`, `IconBadge`, `Icon<Glyph>`, `EmptyState<Feature>`.
5. **Apply** — one idempotent pass.
6. **Report** a before → after tree, plus a list of skipped (instance-internal) and unchanged (already-correct) nodes.

## Rules

1. **A main component / component-set root** can be renamed, but flag it — renaming it changes the component's library/asset name (still name-only, no design change). Confirm intent if it wasn't the explicit target.
2. **Don't invent names that fight the file.** If peers use a clear local pattern, match it over a generic guess.
3. **If unsure between two good names** for the root (the one judgment call that carries weight), apply your best pick and offer the alternative in the report — renaming is cheap and reversible.
4. **No design discussion needed** for the obvious default/auto names — just fix them.


**Last Updated**: 2026-10-19
