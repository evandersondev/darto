# darto_static

Static file serving middleware for [Darto](https://github.com/evandersondev/darto).

---

## Install

```yaml
dependencies:
  darto: ^1.0.0
  darto_static: ^1.0.0
```

---

## Usage

```dart
import 'package:darto/darto.dart';
import 'package:darto_static/darto_static.dart';

void main() async {
  final app = Darto();

  // Serve files from ./public at /public/*
  app.mount('/public/*', serveStatic('public'));

  await app.listen(3000);
}
```

---

## Custom URL prefix

Use the optional `urlPrefix` parameter when the mount path differs from the directory name:

```dart
// Files in ./dist served at /assets/*
app.mount('/assets/*', serveStatic('dist', urlPrefix: '/assets'));
```

---

## Notes

- **Path traversal protection** built-in — requests cannot escape the served directory.
- **MIME types** detected automatically via the `mime` package.
- **Falls through** to `next()` when the requested file is not found, so other routes still match.

---

## See also

- [darto](https://github.com/evandersondev/darto) — core framework
- [examples/example_static_files](../examples/example_static_files/) — working example
