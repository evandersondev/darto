## Goal

Recreate the Zard docs site for the **Darto** package (minimal Dart web framework, Hono-inspired), keeping the same design language and architecture, but:

- Primary color = Dart blue (logo: `#00B4AB` / `#0175C2`, I'll use Dart's official blue `#0175C2` with cyan glow `#13B9FD`)
- Logo = uploaded `logo.png` (schnauzer mark) → `src/assets/darto-logo.png`
- Content sourced from the uploaded `README.md`
- Bilingual EN/PT toggle, same as Zard

## Stack adaptation

The reference project uses Vite + react-router-dom + Tailwind v3. This project uses **TanStack Start + Tailwind v4 + oklch tokens**. I'll port the design 1:1 but adapt:

- Routes via `src/routes/` file-based routing (`index.tsx`, `docs.tsx`) — no `BrowserRouter`.
- Tokens defined in `src/styles.css` using `oklch(...)` (matching the Dart blue palette) instead of HSL.
- `useNavigate` / `Link` imported from `@tanstack/react-router`.
- Search-modal URL state via TanStack Router `useSearch`/`useNavigate`.
- No `next-themes`; keep the simple `use-theme` hook toggling `.dark` class.
- shadcn `Button`, `Tooltip`, `Sonner`, `Toaster` already present.

## Design tokens (`src/styles.css`)

```text
Primary (light) : oklch(0.58 0.16 240)   ≈ Dart blue #0175C2
Primary glow    : oklch(0.72 0.16 215)   ≈ Dart cyan  #13B9FD
Primary (dark)  : oklch(0.70 0.14 230)   (slightly desaturated)
Base            : zinc-neutral, identical to Zard
Code surfaces   : same calm GitHub-like grays
Gradient brand  : linear-gradient(135deg, primary → primary-glow)
Gradient hero   : radial-gradient(top, primary/8%, transparent 60%)
Radius          : 0.5rem
Fonts           : Inter (UI) + JetBrains Mono (code) via @import
Selection / focus ring : primary
Dart syntax tokens (`.tok-*`) ported verbatim
Section scroll-reveal classes (.section-animate, .stagger-child) ported verbatim
```

## Routes & pages

```text
src/routes/
  __root.tsx        providers: QueryClientProvider, I18nProvider,
                    TooltipProvider, Toaster, Sonner; <Outlet/>
  index.tsx         Landing page (sections below)
  docs.tsx          Full docs page (sidebar + content + on-this-page)
```

The root route's `head()` sets default title/meta; `index` and `docs` override per-page metadata.

## Landing page sections (same composition order as Zard)

1. **Navbar** — logo + "Documentation" link + Buy me a coffee + ⌘K search (docs only) + EN/PT toggle + theme toggle.
2. **Hero** — badge "v0.1 · Dart web framework", H1 "Minimal, fast web framework — for Dart, done right.", subtitle, install pill (`dart pub add darto`), CTAs (Get Started / View Documentation), credibility row (version · MIT · pub.dev · GitHub), Dart code sample on the right (the README Quick Start handler).
3. **HowItWorks** — 3-step flow: define app → register routes → listen. Code + caption per step.
4. **Why** — value props: "One concept: Context", "Hono-style ergonomics", "Pure Dart, no JS bridges".
5. **Features** — 6 cards adapted from README capabilities:
   - Routing (params, regex, wildcards, groups)
   - Context API (single object for req/res)
   - Middleware (global, path-scoped, route-level)
   - Built-in middlewares (CORS, JWT, BasicAuth, Cache, CSRF…)
   - Validation (zValidator + Zard integration)
   - Render / View Engine (Hono-style layouts + Mustache)
6. **UsedFor** — REST APIs, file uploads/downloads, WebSocket servers, SSR with view engines.
7. **Examples** — tabbed code samples: Routes · Middleware · Validation · WebSocket (real snippets from README).
8. **RealWorld** — small end-to-end snippet (route group + middleware + validation).
9. **Performance** — short callout: "Minimal overhead. Pure Dart HttpServer under the hood." (No benchmarks table — README has none; replace the Zard perf table with a "What you ship" feature strip: zero JS bridges, native compile, hot-reloadable.)
10. **Comparison** — Darto vs raw `dart:io` vs Shelf (concise table: ergonomics, middleware, routing, context, layouts).
11. **CTA** — "Ship your next Dart API today" + Get Started / GitHub buttons.
12. **Footer** — same layout as Zard, links to pub.dev / GitHub / Docs.

## Docs page

Same 3-column layout, scrollspy, accordion sidebar groups, Cmd/Ctrl+K modal search with URL `?q=`, back-to-top button, `#hash` deep linking.

### Section groups (`DocSection["group"]`)

```text
start      → Installation, Quick Start, Core Concepts
core       → Application, Routing, Context API, Request, Response Factories
validation → Validation (zValidator, targets, custom errors)
advanced   → Middleware, Built-in Middlewares, Render/Layouts,
             View Engine, File Upload, File Download, WebSocket,
             Error Handling
reference  → Helpers (Cookie, JWT, Route, Proxy, Dev),
             HTTP Status Codes, Full Example
```

Total: ~18 sections, each authored as `Block[]` (`p | h3 | code | ul | table | note | callout`) in EN + PT inside `src/lib/docs-content.ts`. Translations follow the README structure; PT is a natural translation, not machine-literal. Callouts used for: "Use `safeParse`-style hooks", "Prefer streamed `c.file` for large files", "Always verify JWT `iss`/`exp`", "WebSocket handlers must call `c.upgradeWebSocket`".

## Components to create

```text
src/components/
  Navbar.tsx         (ported, Tanstack Link, ⌘K event, EN/PT, theme)
  Footer.tsx
  Logo.tsx           (uses imported darto-logo.png + "Darto" wordmark)
  NavLink.tsx
  CodeBlock.tsx      (Dart/yaml/sh highlight + copy + filename chrome)
  sections/
    Hero.tsx HowItWorks.tsx Why.tsx Features.tsx UsedFor.tsx
    Examples.tsx RealWorld.tsx Performance.tsx Comparison.tsx CTA.tsx

src/lib/
  docs-content.ts    (bilingual sections — Darto content)
  highlight.ts       (Dart/yaml/sh tokenizer, ported)
  i18n.ts            (EN/PT strings, Darto copy)
  i18n-context.tsx   (provider + useI18n hook, ported)

src/hooks/
  use-theme.ts       (dark-mode toggle, ported)
```

## Assets

- `src/assets/darto-logo.png` ← uploaded `logo.png`
- Favicon: same image converted, written to `public/favicon.png` and referenced in `__root.tsx` `head().links`.

## SEO per route

- `/`     — title "Darto — Minimal, fast web framework for Dart", description from README intro, og:image = logo.
- `/docs` — title "Darto — Documentation", description "Routing, Context API, middleware, validation, WebSockets and more.".

## Out of scope

- No backend / Lovable Cloud (pure static marketing + docs site).
- No interactive code runner (snippets are static `<CodeBlock>`s).
- No real search index (client-side filter over `docs-content.ts`, identical to Zard).
- No analytics integration.
- No automated tests added beyond what's already in the template.

## Deliverable

After implementation, the user gets a Darto-branded site visually and structurally indistinguishable from the Zard reference, with the full README mapped to bilingual docs.
