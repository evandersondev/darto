# example_validator

Generic request validation using `validator()` from the core `darto` package with [zard](https://pub.dev/packages/zard) schemas — full control over the error response, no automatic 400.

## Features

- `validator('json', ...)` — validate JSON body with a zard schema
- `validator('query', ...)` — validate URL query parameters
- `validator('param', ...)` — validate route path parameters
- Custom status code per route (`400`, `401`, `422`, …) — you decide
- Retrieve validated data with `c.valid<T>(target)`

## Run

```bash
dart run bin/main.dart
```

## Routes

| Method | Path | Validates | Error |
|---|---|---|---|
| `POST` | `/users` | JSON body — name, email, age | `400` |
| `GET` | `/search?q=...` | Query param `q` | `400` |
| `GET` | `/posts/:id` | Route param `id` | `400` |
| `POST` | `/login` | JSON body — email + password | `401` |

## Difference from `zValidator`

| | `validator()` | `zValidator()` |
|---|---|---|
| Package | `darto` (core) | `darto_validator` |
| Schema library | you choose | zard (built-in) |
| Error response | you control | automatic `400` + optional hook |
| Status code | any | `400` by default |

## See also

- [`example_middleware_validator`](../example_middleware_validator/) — `zValidator()` with automatic error handling
- [darto validator docs](../../darto/README.md#validator)
- [zard](https://pub.dev/packages/zard) — schema library
