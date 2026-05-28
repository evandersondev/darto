# darto_logger

Structured logging for the [Darto](https://pub.dev/packages/darto) web framework —
JSON or pretty output, levels, bound fields, and a request-logging middleware with
request-id correlation.

## Install

```yaml
dependencies:
  darto_logger: ^1.0.0
```

## Usage

```dart
import 'package:darto/darto.dart';
import 'package:darto/request_id.dart';
import 'package:darto_logger/darto_logger.dart';

final log = Logger(minLevel: LogLevel.debug);

void main() async {
  final app = Darto();

  app.use(requestId());        // adds X-Request-Id
  app.use(requestLogger(log)); // logs each request with that id

  app.get('/', [], (c) => c.ok({'ok': true}));
  await app.listen(3000, () => log.info('listening', {'port': 3000}));
}
```

Each request logs one structured line:

```json
{"ts":"2026-05-27T12:00:00.000Z","level":"info","msg":"request","requestId":"…","method":"GET","path":"/","status":200,"durationMs":2}
```

## Logger

```dart
final log = Logger(minLevel: LogLevel.info, pretty: false);

log.debug('cache miss', {'key': k});
log.info('user created', {'id': id});
log.warn('slow query', {'ms': 820});
log.error('db failed', error: e, stackTrace: s);

// Bind fields onto every subsequent line
final reqLog = log.child({'requestId': id});
reqLog.info('handled', {'status': 200});
```

| Member | Description |
|---|---|
| `Logger({minLevel, pretty, output})` | Create a logger. `pretty` → human line; `output` → custom sink (defaults to stdout) |
| `debug / info / warn / error(msg, [fields])` | Log at a level; `error` also takes `error` / `stackTrace` |
| `child(fields)` | A logger that binds `fields` to every line |
| `LogLevel` | `debug` · `info` · `warn` · `error` |

## requestLogger(logger)

Middleware that logs `method`, `path`, `status` and `durationMs` per request. When
`requestId()` ran before it, the id is bound to the line.

<br/>

---

<br/>

### Support 💖

If you find Darto Logger useful, please consider supporting its development 🌟[Buy Me a Coffee](https://buymeacoffee.com/evandersondev).🌟 Your support helps us improve the package and make it even better!

<br/>
