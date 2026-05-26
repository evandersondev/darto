# example_middleware_validator

Schema-driven request validation using `zValidator` from `darto_validator` — backed by [zard](https://pub.dev/packages/zard), a Zod-inspired schema library for Dart.

## Features

- `zValidator('json', schema)` — validates JSON body, stores result in `c.req.valid('json')`
- `zValidator('query', schema)` — validates URL query parameters
- `zValidator('param', schema)` — validates route path parameters
- Custom error hook — return `422` instead of the default `400`
- Retrieve validated data with `c.req.valid<T>(target)`

## Run

```bash
dart run bin/main.dart
```

## Routes

| Method | Path | Validates |
|---|---|---|
| `POST` | `/users` | JSON body |
| `GET` | `/search?q=...` | Query params |
| `GET` | `/posts/:id` | Route params |
| `POST` | `/items` | JSON body with custom 422 hook |

## See also

- [`example_validator`](../example_validator/) — generic `validator()` from the core `darto` package
- [darto_validator README](../../darto_validator/README.md)

<br/>

---

<br/>

### Support 💖

If you find Darto useful, please consider supporting its development 🌟[Buy Me a Coffee](https://buymeacoffee.com/evandersondev).🌟 Your support helps us improve the package and make it even better!

<br/>
