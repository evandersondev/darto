# example_proxy

Demonstrates Darto's `proxy()` helper as a reverse proxy / API gateway.

## Architecture

```
Client → Gateway :3000 → Upstream A :4001  (users service)
                        → Upstream B :4002  (products service)
                        → httpbin.org        (external)
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

## Routes (all through the gateway on :3000)

| Method | Path | Proxied to |
|---|---|---|
| GET | `/api/users` | `localhost:4001/users` |
| GET | `/api/users/:id` | `localhost:4001/users/:id` |
| POST | `/api/users` | `localhost:4001/users` (body forwarded) |
| GET | `/api/products` | `localhost:4002/products` |
| GET | `/api/products/:id` | `localhost:4002/products/:id` |
| GET | `/secure` | `localhost:4001/users` + injected `Authorization` header |
| GET | `/external` | `https://httpbin.org/get` |
| POST | `/force-get` | `localhost:4001/users` (method overridden to GET) |
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

# Secure route — injects internal auth header
curl http://localhost:3000/secure

# External proxy
curl http://localhost:3000/external
```

## Key concepts

```dart
import 'package:darto/proxy.dart';

// Transparent forward — method + headers + body
app.all('/api/users/*path', [], (c) =>
    proxy(c, 'http://localhost:4001${c.req.path.replaceFirst('/api', '')}'));

// Header overrides
app.get('/secure', [], (c) =>
    proxy(c, 'http://localhost:4001/users',
        options: ProxyOptions(
            headers: {
                'Authorization': 'Bearer INTERNAL_TOKEN',
                'Cookie': null,          // null = remove header
            })));

// Method override
app.post('/force-get', [], (c) =>
    proxy(c, 'http://localhost:4001/users',
        options: const ProxyOptions(method: 'GET', forwardBody: false)));
```
