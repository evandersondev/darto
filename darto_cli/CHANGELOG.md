## 1.2.0

- New `darto create --template <default|blank|openapi>` (`-t`). The `openapi`
  template scaffolds a REST API where a single `zard` schema validates the
  request **and** generates the OpenAPI 3.1 document (Scalar UI at `/docs`),
  with tests included. `--blank` is now an alias for `--template blank`.
- Generated projects now include a `.gitignore`.
- Fix: the project scaffold pinned `darto: ^0.1.0`; new projects now require
  `darto: ^1.2.0`.

## 1.1.0

- Require `darto: ^1.2.0`.
- New `darto gen feature <name>` — scaffolds a single-file `darto_inject` Feature
  (service + provider + routes wired together) under `lib/features/<name>/`.
- New `darto gen service <name>` — scaffolds a standalone service + provider
  under `lib/services/`.

## 1.0.2

- Require `darto: ^1.1.0`.

## 1.0.1

- Module template uses `c.req.json()` instead of the removed `c.body()`
  request reader (aligns generated code with darto 1.1.0).

## 0.0.1

- Initial release
- `darto create <name>` — scaffold a full project with a starter user module
- `darto dev` — hot-restart dev server watching lib/ and bin/
- `darto build` — compile to native executable via `dart compile exe`
- `darto start` — run the compiled binary
- `darto g module <name>` — generate controller + service + repository + routes + schema
- `darto g controller|service|repository|route|schema <name>` — individual file generators
