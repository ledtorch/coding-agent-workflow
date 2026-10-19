# Plan — worked examples

Worked examples from a real project, for people reading this command. Illustrations only — not rules, and not read by the command.

## Step 0: Required reading

For a site built from a content collection: "`references/development/architecture.md` — the layer map and the content-collection contract; a task that changes the schema changes every case study."

## Step 3: Build the Logic Map

The dependency graph for an Astro site:

```
Content schema (src/content.config.ts)
    │
    ├── Content entries (src/content/projects/*.mdx)
    │       │
    │       └── Page / route (src/pages, src/pages/project/[...slug].astro)
    │               │
    │               └── Layout (src/layouts/BaseLayout.astro)
    │                       │
    │                       └── Component (src/components)
    │                               │
    │                               └── Design tokens (src/styles/global.css)
    │
    └── Assets (src/assets/images — optimised; public/ — served raw)
```

**Last Updated**: 2026-10-19
