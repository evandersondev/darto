# darto_env

`.env` file loader for [Darto](https://github.com/evandersondev/darto).

---

## Install

```yaml
dependencies:
  darto: ^1.0.0
  darto_env: ^1.0.0
```

---

## Usage

```dart
import 'package:darto/darto.dart';
import 'package:darto_env/darto_env.dart';

void main() async {
  // Load .env before anything else
  DartoEnv.load();

  final app = Darto();

  app.get('/config', [], (c) => c.ok({
    'port':  DartoEnv.getInt('PORT', 3000),
    'debug': DartoEnv.getBool('DEBUG', false),
  }));

  await app.listen(DartoEnv.getInt('PORT', 3000));
}
```

---

## API

```dart
DartoEnv.load([String filePath = '.env']);  // load file — call once at startup
DartoEnv.get('KEY', [defaultValue]);        // String (throws if missing and no default)
DartoEnv.maybeGet('OPTIONAL');              // String? — null if not set
DartoEnv.getInt('PORT', 3000);             // int
DartoEnv.getDouble('RATE', 1.5);           // double
DartoEnv.getBool('DEBUG', false);          // bool
DartoEnv.getOrThrow('KEY');                // String — always throws if missing
DartoEnv.all();                            // Map<String, String> — all loaded vars
```

---

## `.env` file

```
PORT=3000
JWT_SECRET=supersecret
DEBUG=true
```

Platform environment variables (`Platform.environment`) always take priority over `.env` values.

---

## See also

- [darto](https://github.com/evandersondev/darto) — core framework
