# example_proxy

Reverse-proxy / API gateway using Darto's `proxy()` helper.

## Architecture

```
Client → Gateway :3000 → users service    :4001
                        → products service :4002
```

## Running

Open **three terminals**:

```bash
# Terminal 1 — users service
dart run bin/upstream_a.dart

# Terminal 2 — products service
dart run bin/upstream_b.dart

# Terminal 3 — gateway
dart run bin/server.dart
```

## Routes

| Method | Path | Proxied to |
|---|---|---|
| ANY | `/api/users/*` | `localhost:4001/api/users/*` |
| ANY | `/api/products/*` | `localhost:4002/api/products/*` |
| ANY | `/v1/*` | `https://example.com/v1/*` + header overrides |
| GET | `/health` | gateway health check (not proxied) |

## Try it

```bash
# List users
curl http://localhost:3000/api/users

# Get user by id
curl http://localhost:3000/api/users/1

# Create user (body forwarded)
curl -X POST http://localhost:3000/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Carol","role":"editor"}'

# List products
curl http://localhost:3000/api/products

# Gateway health
curl http://localhost:3000/health
```

## Key concepts

```dart
import 'package:darto/proxy.dart';

// Transparent forward — method + headers + body
// /*  matches both the exact path (/api/users) and any sub-path (/api/users/1)
app.all('/api/users/*', [], (Context c) =>
    proxy(c, 'http://localhost:4001${c.req.path}'));

// With header overrides (inject auth, strip cookies)
app.all('/v1/*', [], (Context c) =>
    proxy(c, 'https://example.com${c.req.path}',
        options: ProxyOptions(
          headers: {
            'X-Proxy-By': 'darto-gateway',
            'Authorization': 'Bearer INTERNAL_SECRET',
            'Cookie': null, // null = remove header
          },
        )));
```

`proxy()` automatically:
- Forwards the original HTTP method and request body
- Strips hop-by-hop headers (`Connection`, `Transfer-Encoding`, etc.)
- Removes `Content-Encoding` / `Content-Length` from the upstream response

## See also

- [darto proxy docs](../../darto/README.md#proxy)
