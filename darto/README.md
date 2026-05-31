<p align="center">
  <img src="./assets/logo.png" width="200px" align="center" alt="Darto logo" />
  <h1 align="center">Darto</h1>
  <p align="center">
    <a href="https://github.com/evandersondev/darto">🎯 Darto Github</a>
    <br/>
    Minimal, fast and type-safe web framework for Dart — inspired by Express and Hono.
  </p>
</p>

<br/>

Everything flows through a single concept: **Context**.

> 📚 **Official documentation:** https://darto-docs.vercel.app/

---

### Support 💖

If you find Darto useful, please consider supporting its development 🌟[Buy Me a Coffee](https://buymeacoffee.com/evandersondev).🌟 Your support helps us improve the package and make it even better!

<br/>

---

<br/>

## Installation

```yaml
dependencies:
  darto: ^1.2.0
```

<br/>

---

<br/>

## Quick Start

```dart
import 'package:darto/darto.dart';

void main() {
  final app = Darto();

  app.get('/users/:id', [], (Context c) {
    final id = c.req.param('id');

    return c.ok({'id': id});
  });

  app.listen(3000);
}
```

<br/>

---

<br/>

## Examples

Ready-to-run projects are available in the [`examples/`](https://github.com/evandersondev/darto/tree/main/examples) folder of the monorepo:

| Example                                                                                                                  | What it covers                                              |
| ------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------- |
| [`example_basic_routing`](https://github.com/evandersondev/darto/tree/main/examples/example_basic_routing)               | Route params, wildcards, optional params                    |
| [`example_group_routes`](https://github.com/evandersondev/darto/tree/main/examples/example_group_routes)                 | Route groups, nested groups, standalone routers             |
| [`example_middleware_pipeline`](https://github.com/evandersondev/darto/tree/main/examples/example_middleware_pipeline)   | Middleware chaining, short-circuit, `combine`               |
| [`example_auth_jwt`](https://github.com/evandersondev/darto/tree/main/examples/example_auth_jwt)                         | JWT middleware, sign/verify helpers, `c.user`               |
| [`example_middleware_validator`](https://github.com/evandersondev/darto/tree/main/examples/example_middleware_validator) | `zValidator` — schema-driven validation with zard           |
| [`example_validator`](https://github.com/evandersondev/darto/tree/main/examples/example_validator)                       | `validator()` + zard — full control over the error response |
| [`example_context_usage`](https://github.com/evandersondev/darto/tree/main/examples/example_context_usage)               | Full Context API, `c.req`, state, headers                   |
| [`example_response_helpers`](https://github.com/evandersondev/darto/tree/main/examples/example_response_helpers)         | `c.ok`, `c.json`, `c.html`, `c.binary`, redirects           |
| [`example_error_handling`](https://github.com/evandersondev/darto/tree/main/examples/example_error_handling)             | `app.onError`, `app.notFound`, `DartoError`                 |
| [`example_upload`](https://github.com/evandersondev/darto/tree/main/examples/example_upload)                             | In-memory and streamed-to-disk file upload                  |
| [`example_static_files`](https://github.com/evandersondev/darto/tree/main/examples/example_static_files)                 | Static file serving with `darto_static`                     |
| [`example_view_engine`](https://github.com/evandersondev/darto/tree/main/examples/example_view_engine)                   | Mustache templates with `darto_view`                        |
| [`example_websocket`](https://github.com/evandersondev/darto/tree/main/examples/example_websocket)                       | WebSocket rooms + broadcast (`WsHub`), HTTP fanout          |
| [`example_session`](https://github.com/evandersondev/darto/tree/main/examples/example_session)                           | Cookie-based signed sessions                                |
| [`example_logger`](https://github.com/evandersondev/darto/tree/main/examples/example_logger)                             | Structured logging + request logger (`darto_logger`)        |
| [`example_proxy`](https://github.com/evandersondev/darto/tree/main/examples/example_proxy)                               | Reverse proxy, header overrides                             |
| [`example_env`](https://github.com/evandersondev/darto/tree/main/examples/example_env)                                   | `.env` loading with `darto_env`                             |
| [`example_inject`](https://github.com/evandersondev/darto/tree/main/examples/example_inject)                             | Typed DI — providers, scopes, `c.read` (`darto_di`)         |
| [`example_cache`](https://github.com/evandersondev/darto/tree/main/examples/example_cache)                               | Read-through cache with `remember()` (`darto_cache`)        |
| [`example_rate_limit`](https://github.com/evandersondev/darto/tree/main/examples/example_rate_limit)                     | Distributed rate limiting (`darto_rate_limit`)              |
| [`example_auth`](https://github.com/evandersondev/darto/tree/main/examples/example_auth)                                 | Password hashing + session auth + OAuth (`darto_auth`)      |
| [`example_mailer`](https://github.com/evandersondev/darto/tree/main/examples/example_mailer)                             | Sending email — SMTP / console (`darto_mailer`)             |
| [`example_jobs`](https://github.com/evandersondev/darto/tree/main/examples/example_jobs)                                 | Background jobs + retries (`darto_jobs`)                    |
| [`example_openapi`](https://github.com/evandersondev/darto/tree/main/examples/example_openapi)                           | OpenAPI 3.1 spec + Scalar docs (`darto_openapi`)            |
| [`example_full_integration`](https://github.com/evandersondev/darto/tree/main/examples/example_full_integration)         | Full app — auth, CORS, validation, WebSocket                |

<br/>
