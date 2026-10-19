# Release — worked examples

Worked examples from a real project, for people reading this command. Illustrations only — not rules, and not read by the command.

The project is a static portfolio site (Astro, deployed over rsync to an nginx host).

## 1. Preflight — version sources

> **This is a static site.** There is no app binary, no store build, and no version string
> that has to agree across build configs — so there is no version-match gate. The tag is
> the only version that exists. If `package.json` is ever brought under real versioning,
> add the check back here in the same pass. When more than one surface ships (e.g. web +
> iOS), they carry the **same** version, bumped together in one commit; a mismatch between
> the sources is itself a stop.

## 3. Tag message — lead with the verdict

If the body's lede lands on *"the Webflow export is gone"*, the tag should too.

## 4. Release notes — key recap

The recap is earned when the release **changes what the site is**: a new kind of page, a
rebuild, a structural change to how content works. Ordinary content-and-fix releases skip it.

## 4. Release notes — section headers and bullets

Header: `### 📄 Case studies — the flagship study lands`

Real identifiers in backticks: `ProjectCard.astro`, `content.config.ts`, `--column`.

A concrete deciding fact: *"openrsync has no `--chmod`, so permissions are set locally"*.

## 4. Release notes — section emoji

| Emoji | Theme               | Covers                                                           |
| ----- | ------------------- | ---------------------------------------------------------------- |
| 📄    | **Case studies**    | the content collection, project pages, case-study copy           |
| 🏠    | **Home & nav**      | the project grid, tiles, the catalogue, contact                  |
| 🎨    | **Design system**   | tokens, typography, shared components, layout primitives         |
| 🎬    | **Motion**          | scroll reveals, transitions, video tiles                         |
| ⚡    | **Performance**     | images, fonts, video encoding, build output size                 |
| ♿    | **Accessibility**   | alt text, heading order, focus, reduced motion                   |
| 🔎    | **Discoverability** | metadata, OG cards, canonicals, sitemap, robots                  |
| 🔧    | **Infrastructure**  | deploy, nginx, TLS, DNS, the scripts                             |
| 📚    | **Docs & commands** | `references/`, the slash commands                                |
| 🐛    | **Fixes**           | bugs with no home above — use sparingly, prefer the owning theme |

A fix in its owning theme: a tile-blurb size fix is 🎨, not 🐛.

## 4. Style reference A — with a key recap

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

## 4. Style reference B — no key recap

```markdown
_11 commits · 2026-08-08 → 2026-08-09_

### 📄 Case studies — the flagship study lands
- **Card-only projects are now a real schema shape** — a project with no `cover` builds no
  page and must set `href`, enforced by a refinement, so a half-filled case study fails the
  build instead of rendering with holes.
```

## 5. Deploy

```bash
./deploy.sh --dry-run   # show the exact file list
./deploy.sh             # build, confirm, upload, verify
```

The real deploy uses `--delete`. The script ends with its own HTTP check; "deployed" without
that 200 is a claim, not a result.


**Last Updated**: 2026-10-19
