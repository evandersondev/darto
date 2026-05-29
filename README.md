<div align="center">

# 🎯 Darto Framework

**Minimal, fast and type-safe web framework for Dart — inspired by Express and Hono.**

Everything flows through a single concept: **Context**.

[![pub.dev](https://img.shields.io/pub/v/darto.svg?label=darto)](https://pub.dev/packages/darto)
[![pub.dev](https://img.shields.io/pub/v/darto_cli.svg?label=darto_cli)](https://pub.dev/packages/darto_cli)
[![Dart](https://img.shields.io/badge/Dart-3.x-blue.svg)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

</div>

---

## 📦 Packages

This repository is a **monorepo** containing the entire Darto ecosystem.

| Package                                 | Description                                            | Version                                                                                              |
| --------------------------------------- | ------------------------------------------------------ | ---------------------------------------------------------------------------------------------------- |
| [`darto`](./darto/)                     | Core framework — routing, middleware, context, helpers | [![pub](https://img.shields.io/pub/v/darto.svg)](https://pub.dev/packages/darto)                     |
| [`darto_cli`](./darto_cli/)             | CLI — scaffold, dev server, build, client generator    | [![pub](https://img.shields.io/pub/v/darto_cli.svg)](https://pub.dev/packages/darto_cli)             |
| [`darto_validator`](./darto_validator/) | Request validation via `zValidator` (Zod-style)        | [![pub](https://img.shields.io/pub/v/darto_validator.svg)](https://pub.dev/packages/darto_validator) |
| [`darto_ws`](./darto_ws/)               | WebSocket support — same port, route-integrated        | [![pub](https://img.shields.io/pub/v/darto_ws.svg)](https://pub.dev/packages/darto_ws)               |
| [`darto_view`](./darto_view/)           | Pluggable template engine (Mustache, Jinja, …)         | [![pub](https://img.shields.io/pub/v/darto_view.svg)](https://pub.dev/packages/darto_view)           |
| [`darto_static`](./darto_static/)       | Static file serving middleware                         | [![pub](https://img.shields.io/pub/v/darto_static.svg)](https://pub.dev/packages/darto_static)       |
| [`darto_env`](./darto_env/)             | `.env` file loader                                     | [![pub](https://img.shields.io/pub/v/darto_env.svg)](https://pub.dev/packages/darto_env)             |
| [`darto_openapi`](./darto_openapi/)     | OpenAPI 3.1 spec generation + Scalar API docs          | [![pub](https://img.shields.io/pub/v/darto_openapi.svg)](https://pub.dev/packages/darto_openapi)     |
| [`darto_test`](./darto_test/)           | Ergonomic test client (boot + assert, supertest-style) | [![pub](https://img.shields.io/pub/v/darto_test.svg)](https://pub.dev/packages/darto_test)           |
| [`darto_logger`](./darto_logger/)       | Structured logging + request-logging middleware        | [![pub](https://img.shields.io/pub/v/darto_logger.svg)](https://pub.dev/packages/darto_logger)       |
| [`darto_auth`](./darto_auth/)           | Password hashing (PBKDF2) + session-based auth guards   | [![pub](https://img.shields.io/pub/v/darto_auth.svg)](https://pub.dev/packages/darto_auth)           |
| [`darto_di`](./darto_di/)               | Typed DI — `Provider<T>` + request scope + overrides   | [![pub](https://img.shields.io/pub/v/darto_di.svg)](https://pub.dev/packages/darto_di)               |
| [`darto_cache`](./darto_cache/)         | Cache interface + `MemoryCache` (LRU/TTL) + `RedisCache` | [![pub](https://img.shields.io/pub/v/darto_cache.svg)](https://pub.dev/packages/darto_cache)         |
| [`darto_rate_limit`](./darto_rate_limit/) | Distributed `RateLimitStore` (Redis) for the core rateLimit() | [![pub](https://img.shields.io/pub/v/darto_rate_limit.svg)](https://pub.dev/packages/darto_rate_limit) |
| [`darto_mailer`](./darto_mailer/)       | Email — `Mailer` + SMTP / console / memory transports   | [![pub](https://img.shields.io/pub/v/darto_mailer.svg)](https://pub.dev/packages/darto_mailer)       |
| [`darto_jobs`](./darto_jobs/)           | Background jobs — queue + retries, Memory / Redis stores | [![pub](https://img.shields.io/pub/v/darto_jobs.svg)](https://pub.dev/packages/darto_jobs)           |

---

## ⚡ Quick Start

```sh
# Install the CLI
dart pub global activate darto_cli

# Scaffold a new project
darto create my_api
cd my_api

# Start development server (hot-reload)
darto dev
```

Or add manually to your `pubspec.yaml`:

```yaml
dependencies:
  darto: ^1.2.0
```

```dart
import 'package:darto/darto.dart';

void main() {
  final app = Darto();

  app.get('/hello', [], (Context c) => c.ok({'message': 'Hello, Darto!'}));

  app.listen(3000, () => print('🚀 Listening on http://localhost:3000'));
}
```

---

## 🗂️ Repository Structure

```
darto/
├── darto/              # Core framework
├── darto_cli/          # CLI tool
├── darto_validator/    # Request validation
├── darto_ws/           # WebSocket support
├── darto_view/         # Template engines
├── darto_static/       # Static file serving
├── darto_env/          # .env loader
├── darto_openapi/      # OpenAPI 3.1 + Scalar docs
├── darto_test/         # Test client
├── darto_logger/       # Structured logging
├── darto_auth/         # Password hashing + session auth
├── darto_di/           # Typed DI (Provider<T> + request scope)
├── darto_cache/        # Cache primitives (Memory + Redis)
├── darto_rate_limit/   # Distributed RateLimitStore (Redis)
├── darto_mailer/       # Email (SMTP + console/memory transports)
├── darto_jobs/         # Background jobs (Memory + Redis)
├── darto-docs/         # Documentation site
└── examples/           # Example projects (see below)
```

---

## 🧪 Examples

Explore ready-to-run examples inside the [`examples/`](./examples/) folder:

| Example                                                                    | Description                                                 |
| -------------------------------------------------------------------------- | ----------------------------------------------------------- |
| [`example_basic_routing`](./examples/example_basic_routing/)               | Route params, wildcards, optional params                    |
| [`example_group_routes`](./examples/example_group_routes/)                 | Route groups, nested groups, standalone routers             |
| [`example_middleware_pipeline`](./examples/example_middleware_pipeline/)   | Middleware chaining, short-circuit, `combine`               |
| [`example_auth_jwt`](./examples/example_auth_jwt/)                         | JWT middleware, sign/verify helpers, `c.user`               |
| [`example_middleware_validator`](./examples/example_middleware_validator/) | `zValidator` — schema-driven validation with zard           |
| [`example_validator`](./examples/example_validator/)                       | `validator()` + zard — full control over the error response |
| [`example_context_usage`](./examples/example_context_usage/)               | Full Context API, `c.req`, state, headers                   |
| [`example_response_helpers`](./examples/example_response_helpers/)         | `c.ok`, `c.json`, `c.html`, `c.binary`, redirects           |
| [`example_error_handling`](./examples/example_error_handling/)             | `app.onError`, `app.notFound`, `DartoError`                 |
| [`example_upload`](./examples/example_upload/)                             | In-memory and streamed-to-disk file upload                  |
| [`example_static_files`](./examples/example_static_files/)                 | Static file serving with `darto_static`                     |
| [`example_view_engine`](./examples/example_view_engine/)                   | Mustache templates with `darto_view`                        |
| [`example_websocket`](./examples/example_websocket/)                       | WebSocket echo, JSON messages, room chat                    |
| [`example_session`](./examples/example_session/)                           | Cookie-based signed sessions                                |
| [`example_logger`](./examples/example_logger/)                             | Built-in logger middleware, custom printer                  |
| [`example_proxy`](./examples/example_proxy/)                               | Reverse proxy, header overrides                             |
| [`example_env`](./examples/example_env/)                                   | `.env` loading with `darto_env`                             |
| [`example_full_integration`](./examples/example_full_integration/)         | Full app — auth, CORS, validation, WebSocket                |

---

## 📚 Documentation

- **Full API docs:** [darto README](./darto/README.md)
- **pub.dev:** [pub.dev/packages/darto](https://pub.dev/packages/darto)
- **Docs site:** [darto-docs](./darto-docs/)

---

## 🤝 Contributing

Contributions are welcome! Please open an issue or PR on [GitHub](https://github.com/evandersondev/darto).

---

## 📄 License

MIT — see [LICENSE](LICENSE) for details.

<br/>

---

<br/>

### Support 💖

If you find Darto useful, please consider supporting its development 🌟[Buy Me a Coffee](https://buymeacoffee.com/evandersondev).🌟 Your support helps us improve the package and make it even better!

<br/>
