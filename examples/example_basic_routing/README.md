# example_basic_routing

What it demonstrates: Core routing — GET/POST, route params, and query strings.

## Features
- `GET /` — simple response
- `GET /users/:id` — route parameter via `c.param` / `c.paramInt`
- `GET /search?q=...&page=...` — query strings via `c.query` / `c.queryInt`
- `POST /users` — reading JSON body via `c.req.json()`

## Run
```bash
dart run bin/main.dart
```

<br/>

---

<br/>

### Support 💖

If you find Darto useful, please consider supporting its development 🌟[Buy Me a Coffee](https://buymeacoffee.com/evandersondev).🌟 Your support helps us improve the package and make it even better!

<br/>
