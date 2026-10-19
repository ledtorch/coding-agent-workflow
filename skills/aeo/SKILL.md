---
name: aeo
description: Audit a website for Answer/Agent Engine Optimization — AI-crawler access, raw-HTML visibility, answer-first structure, citation-worthy content, freshness, and entity signals — ending in severity-labelled, evidence-tiered findings and a plan doc. Use when you want to know whether AI assistants and answer engines can read, chunk, and cite the site. Fixes nothing.
---

# AEO

Audit the **named site** for Answer/Agent Engine Optimization: can AI crawlers reach it,
can they read it without executing JavaScript, does its content chunk into citable answers,
and do its signals support being resolved as a known entity. **Write no code, change no
config.**

**Use when:** you want to know why AI assistants don't cite the site, or whether a site is
ready for AI search before launch.
**NOT for:** classic SEO (rankings, backlinks, Core Web Vitals), auditing code quality
(`/inspect`), or applying the fixes this audit proposes (`/build`, from the plan doc).

State the target in one line so the user can interrupt: the URL, the repo (if the site's
source is local), or both.

## Scope

The named site, nothing else. No target → ask for the URL or the site's source directory;
never guess.

Two modes, used together when both are available:

- **Live mode** — the deployed URL. Fetch it the way an AI crawler does. This is the only
  mode that catches WAF blocks, CDN bot rules, and rendering reality.
- **Repo mode** — the site's source is the current repo. Read the framework config to
  determine the rendering mode, and the templates to check structure at the source. Repo
  mode alone cannot prove reachability — say so in the report if live mode was unavailable.

Reading and fetching are unrestricted. **Editing is zero** — `/aeo` never modifies a file,
a robots.txt, or a deployment.

## Step 0: Required reading (blocking)

1. `references/SKILL.md` — route to whatever covers the site's deploy and content layer
2. `references/development/architecture.md` — the rendering stack (SSR/SSG/SPA) is a
   claim this audit verifies against reality, not a fact it assumes

> **No `references/SKILL.md`?** The reference layer isn't set up here — skip Step 0 and
> audit from the site alone. **Say so at the top of the run.** [`/setup`](../setup/SKILL.md)
> builds the layer, in either mode.

## The evidence tiers

Every check below carries a tier, and the tier caps the severity a finding may claim.
The AEO industry's failure mode is selling speculative factors as critical ones; this
audit's job is to not do that.

| Tier            | Meaning                                                        | Severity ceiling |
| --------------- | -------------------------------------------------------------- | ---------------- |
| **PROVEN**      | Controlled study or first-party platform statement             | Critical         |
| **PLAUSIBLE**   | Strong mechanism + practitioner consensus, no controlled proof | Required         |
| **SPECULATIVE** | Widely recommended; evidence weak or contradicted              | Consider         |

## Step 1: Establish ground truth

Before any check, fetch the site the way the crawlers actually do — raw HTML, no
JavaScript execution, no cookies:

    curl -sL --max-time 10 -A "Mozilla/5.0 (compatible; OAI-SearchBot/1.0)" <url>

Keep the output; every content check below runs against it, not against what a browser
shows. In repo mode, also read the framework config and name the rendering mode
(SSR / SSG / client-only) with the file that proves it.

Then **state the scope in one line before proceeding** — target, modes available, pages
sampled (home + 2–3 representative content pages minimum). That is the user's interrupt
point.

## Step 2: The eight checks

Ordered by how load-bearing the evidence says each one is. Run all eight; report in this
order.

### C1 — Crawler access `PROVEN`

The single most load-bearing check, and binary: blocked is invisible. Three distinct
crawler classes exist per operator, and **blocking one class does not block the others** —
the classic finding is a `GPTBot` block added years ago for training reasons that also
never allowed `OAI-SearchBot`, silently removing the site from ChatGPT Search.

| Class                | Examples                                                                                | Blocking means                                                      |
| -------------------- | --------------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| Training             | `GPTBot` `ClaudeBot` `Google-Extended` `CCBot` `Meta-ExternalAgent` `Applebot-Extended` | Out of future training corpora — a policy choice, not an AEO defect |
| Search index         | `OAI-SearchBot` `Claude-SearchBot` `PerplexityBot`                                      | **Removed from that engine's answers and citations**                |
| User-triggered fetch | `ChatGPT-User` `Claude-User` `Perplexity-User`                                          | The assistant can't open the site's URLs live for a user            |

Note: `Google-Extended` gates Gemini training only — AI Overviews and AI Mode use plain
Googlebot and are unaffected by it.

Check, in order:
1. `curl -s <url>/robots.txt` — grep for every UA above; record which class each rule hits.
2. **The WAF reality check** — robots.txt permission is not reachability. Fetch a content
   page with an AI-crawler user-agent string and confirm a 200 with real HTML, not a 403
   or a challenge page. Cloudflare-style "block AI bots" toggles override robots.txt
   silently.
3. `curl -sI` — check `X-Robots-Tag` headers, and the page for `noindex`/`noai` meta.

### C2 — Raw-HTML visibility `PROVEN`

No major AI crawler executes JavaScript — GPTBot, ClaudeBot, and PerplexityBot read the
initial HTML response only (Vercel/MERJ, 500M+ fetches). Only Gemini, riding Googlebot's
infrastructure, renders JS. **Client-rendered content is invisible to everything else.**

Check: strip tags from the Step 1 curl output and confirm the main content — headings,
body copy, prices, the things the site wants cited — is present. A body that reduces to an
empty `<div id="root">` fails the audit outright, and that one finding outranks everything
else a JS-rendered site could fix. In repo mode, name the config line that sets the
rendering mode.

### C3 — Answer-first structure `PLAUSIBLE`

Answer engines retrieve at passage level: pages are chunked and matched per sub-question,
so the competing unit is a section, not a page. A section must survive being read alone.

Check against the raw HTML:
- Real heading elements (`<h1>`–`<h3>`), single H1, no skipped levels — not styled divs
- H2/H3s phrased as the questions users ask
- The first paragraph under a heading answers it directly, in 2–3 sentences, before any
  preamble or wind-up
- Semantic structure where it fits: tables for comparisons, lists for steps

### C4 — Citations, quotations, statistics in the content `PROVEN`

The one experimentally validated content lever: the GEO paper (Aggarwal et al., KDD 2024,
arXiv 2311.09735) black-box-tested nine methods and found cited sources, quotations, and
concrete statistics improved generative-engine visibility 30–40% relative — while keyword
optimization was flat to negative.

Check per sampled page: outbound citation links to real sources, quoted expert statements,
and numbers-with-sources in the main content. A content site whose pages assert without
citing is leaving the only proven lever unused.

### C5 — Freshness signals `PROVEN`

AI assistants have a measured freshness bias (~26% newer than what classic search serves
for the same queries — Ahrefs, ~17M citations).

Check: visible published/updated dates, `dateModified` in Article JSON-LD, sitemap
`<lastmod>` values that reflect real updates, and stale year references ("as of 2023") in
evergreen copy.

### C6 — Entity and author signals `PLAUSIBLE`

Infrastructure, not a citation lever, and no rescue for content that fails C2 or C3:
schema feeds entity resolution, and engines lean on sources they can identify. Check:
`Organization` JSON-LD with `sameAs` links, `Article` with a real author and dates, an
`/about` page, author bios. Validate what exists — JSON
parses, matches visible content, present in raw HTML not injected client-side. **Do not
promise citation gains from adding schema**: Google states none is needed for AI
Overviews, and the one natural experiment (Ahrefs, 1,885 pages) found no uplift. Bing/
Copilot is the strongest first-party case for it.

### C7 — Technical hygiene `PLAUSIBLE`

AI crawlers have short timeouts and no retry patience. Check: sitemap.xml exists and is
referenced by robots.txt · canonicals present and self-consistent · time-to-first-byte
under ~1s (`curl -w '%{time_starttransfer}'`) · meaningful `<title>` and meta description
(engines quote them) · content served without cookie walls, geo-gates, or interstitials
in the raw response.

### C8 — llms.txt `SPECULATIVE`

The most over-sold item in AEO. Server-log studies put AI-bot hits on `/llms.txt` around
0.1% of AI crawler traffic; no major engine commits to consuming it for search, and
Google explicitly says none is needed. Where it does earn its place: agentic browsing and
docs-heavy developer sites (Anthropic's agent guidance recommends it; Lighthouse now
checks it).

Check if present: valid structure per llmstxt.org (H1 first, blockquote summary, H2 link
lists), links resolve. If absent: **at most a Consider, and only for docs/agent-facing
sites.** An audit that flags a missing llms.txt as critical is selling something.

## Step 3: Evidence — a finding is a claim until proven

Every finding carries the command that was run, the relevant output, and a **failure
scenario**: which engine, doing what, fails to see or cite what. "Structured data could be
richer" is not a finding.

- **Before calling the site blocked:** show the robots.txt lines *and* the live fetch —
  the two disagree often, in both directions.
- **Before calling content invisible:** show the raw-HTML extract that lacks it, not the
  framework's reputation. An SPA with prerendering passes; an "SSR" site with a
  client-only content island fails. Reality over config.

## Step 4: Severity

| Label        | Meaning here                                                                   |
| ------------ | ------------------------------------------------------------------------------ |
| **Critical** | Engines cannot reach or cannot read the site today (C1/C2 failures)            |
| **Required** | Content reachable but structurally uncitable; fix before investing in content  |
| **Consider** | Proven-lever opportunities (C4, C5) and infrastructure gaps — the user decides |
| **Nit**      | Hygiene that costs little and buys little                                      |
| **FYI**      | Policy choices (e.g. training-bot blocks) recorded, not judged                 |

**Lead with what matters.** A C1 or C2 failure *is* the report — ten content findings on
an unreachable site are noise.

## Step 5: Output — report, then plan, then attack it

**First, in chat:** a per-check verdict table — C1–C8, pass/warn/fail, one-line evidence
each — then findings ordered by severity, each with its tier, command, output, failure
scenario, and proposed fix. **No composite score.** A 0-to-100 number laundered from
unweighed factors is precision the evidence doesn't support; the verdict table says more.
Say plainly what was not verified (repo mode only? pages sampled?) and why. If the site is
genuinely sound, report that in one line rather than manufacturing findings.

**Then, one plan doc**, following [plan](../plan/SKILL.md) — its Task Template, its "Small Enough"
definition, its naming rule. Each task cites the finding (and tier) that motivated it;
fixes ordered by the check order above, because a C1 fix changes what every later check is
worth.

**Then red-team the report** before the user sees it, on the lines that bite here:
- **Overselling** — does any severity exceed its tier's ceiling? Is llms.txt or schema
  promised as a citation lever anywhere?
- **Sampling** — would a different 3 pages have changed a verdict? Say which pages carry
  each conclusion.
- **Its own claims** — re-run the load-bearing curls; a WAF verdict from one fetch at one
  time is a hypothesis.

## The gate

Stop at the plan. `/aeo` does not edit robots.txt, does not generate llms.txt, does not
touch templates, and does not roll into `/build`. The user reads the findings and decides
what is worth doing — including the policy calls (training-bot access) that were never
the audit's to make.

## Verification

- [ ] Step 0 reading done and listed, or its absence declared
- [ ] Target and mode(s) stated before auditing; live mode used, or its absence declared
- [ ] Ground-truth fetch done with a crawler UA; all content checks ran against raw HTML
- [ ] All eight checks ran, reported in C1–C8 order
- [ ] Every finding has its command, output, failure scenario, tier, and severity
- [ ] No severity exceeds its tier's ceiling
- [ ] WAF reality check performed, not inferred from robots.txt
- [ ] Verdict table in chat; no composite score invented
- [ ] Plan doc passes [plan](../plan/SKILL.md)'s own verification list; every task cites a finding
- [ ] Report red-teamed for overselling, sampling, and its own claims
- [ ] Nothing was edited

## See Also

[plan](../plan/SKILL.md) (task and plan-doc templates) · [build](../build/SKILL.md)
(executes the fixes) · [inspect](../inspect/SKILL.md) (same contract, aimed at code) · GEO
paper (C4) · llmstxt.org · Vercel "The rise of the AI crawler"

**Last Updated**: 2026-10-19
