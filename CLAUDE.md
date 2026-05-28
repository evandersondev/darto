# CLAUDE.md — working agreement for the Darto monorepo

Guidance for Claude (and contributors) when working in this repository. Read this
before making changes.

## ⭐ Golden rule: keep docs in sync with code

**Any change to public API, behavior, a middleware/helper, or adding/removing a
feature MUST update the docs in the same change.** Do not consider a change done
until the docs reflect it. Specifically:

1. **Package README** — the affected package's `README.md`
   (`darto/README.md`, `darto_<plugin>/README.md`).
2. **darto-docs** — `darto-docs/src/lib/docs-content.ts` (and `i18n.ts` for
   labels/version). Docs are **bilingual** — update **both** EN and PT.
3. **Root `README.md`** — only when packages, versions or the package table change.
4. **`CHANGELOG.md`** of the affected package — add an entry.
5. **`ROADMAP.md`** — tick/adjust items when a roadmap feature lands.

When in doubt, update the README *and* darto-docs.

## Repository layout

```
darto/            Core framework (package: darto) — routing, Context, middleware, helpers
darto_cli/        CLI: scaffold, dev, build, gen client
darto_env/        .env loader (no darto dependency)
darto_static/     Static file serving
darto_validator/  zValidator (zard-backed) + zardToOpenApiSchema()
darto_view/       Template engine (Mustache)
darto_ws/         WebSocket (same-port upgrade)
darto_openapi/    OpenAPI 3.1 + Scalar docs        ← local only (not on pub.dev yet)
darto_test/       In-app-style test client          ← local only (not on pub.dev yet)
darto-docs/       Documentation site (React + TanStack Router + Vite)
examples/         Runnable examples
```

- GitHub: **`evandersondev/darto`** (default branch `main`). Plugins are
  subdirectories → link them as `https://github.com/evandersondev/darto/tree/main/<pkg>`.
- **`zard`** (the schema library) lives in a **separate repo at `/home/pc005/www/zard`**,
  published to pub.dev. Edit it there when introspection/features are needed.

## darto-docs conventions

Content lives in `darto-docs/src/lib/docs-content.ts`:

- `SECTIONS: BiSection[]` — each section has `id`, `group`
  (`start | core | validation | advanced | reference | plugins | migration`),
  `title: bi(en, pt)` and `blocks: bi([...en], [...pt])`. **Always fill both languages.**
- Block kinds: `p`, `code` (lang `dart|yaml|sh|html`, optional `filename`), `h3`
  (give it an `id` — it feeds the "On this page" panel), `ul`, `table`
  (`headers` + `rows`), `note`, `callout` (`tip|warning|success`), `links`
  (external pub.dev/GitHub), `ref` (internal link to another section by `id`).
- **Describe, don't dump.** Prefer `h3` + a `table` (Member | Description) so each
  API entry says *what it does*. More `h3`s = a richer "On this page".
- **Plugins group = package cards.** Each plugin page: `links` (pub.dev + GitHub)
  + short description + install. If a thematic guide already covers it
  (CLI Tools, Validation, WebSocket, View Engine), **`ref` to that guide instead of
  duplicating usage**; the guide carries a reverse `ref` back to the package.
- Group labels live in `i18n.ts` (`t.docs.groups.*`) and the `groupLabels` map in
  `routes/docs.tsx`.

Validate darto-docs after editing:

```sh
cd darto-docs
bunx prettier --write src/lib/docs-content.ts   # the file uses prettier formatting
./node_modules/.bin/tsc --noEmit                # use the LOCAL tsc — `bunx tsc` fetches a wrong shim
bun run build
```

## Dart package conventions

- Validate every package you touch: `dart analyze` (expect 0 issues) and `dart test`.
- Tests use light integration (`HttpServer` on an ephemeral port) — see
  `darto/test/support/harness.dart`.
- **Versioning (semver):** new backward-compatible feature → minor; bug fix → patch;
  breaking → major. Update the package `pubspec.yaml` version + `CHANGELOG.md`.
- **Local dev across the monorepo:** plugins resolve `darto` (and `zard`) via
  `dependency_overrides` pointing to the local path. Keep these overrides; they are
  ignored by consumers of the published package.

## Publishing (pub.dev) — irreversible

- **Never publish without explicit confirmation.** A published version cannot be
  removed or overwritten.
- Flow: `dart pub publish --dry-run` → review → `dart pub publish --force`.
- Order matters: publish `darto` before packages that depend on it; publish `zard`
  before `darto_validator`.

## Key facts & gotchas

- **`validator` (core) vs `zValidator` (plugin):** the core `validator` middleware
  (`package:darto/validator.dart`) needs **no** extra package — bring any logic. To
  use zard schemas with it, add only **`zard`** (not `darto_validator`).
  `zValidator` is the one that needs `darto_validator`.
- **Request body / Context:** read the body once. `c.body()` is a **response** helper
  (Hono-style); read the request via `c.req` (`json/text/blob/arrayBuffer/parseBody`).
  Cookie helpers read the **request** `Cookie` header.
- **`zard` introspection (≥1.1.2):** `ZList.element`, `ZEnum.values`, and exported
  `ZOptional`/`ZNullable`/`ZUnion` enable `darto_validator`'s `toOpenApiSchema()`.
- `darto_openapi` and `darto_test` are **local only** for now — their pub.dev links
  404 until published; their docs carry a "publishing soon" callout.
- See **`ROADMAP.md`** for the ecosystem plan and what's done.
