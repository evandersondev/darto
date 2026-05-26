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
