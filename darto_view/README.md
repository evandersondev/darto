# darto_view

Template engine plugin for [Darto](https://github.com/evandersondev/darto) — pluggable, Hono-style renderer registration via middleware.

Ships with a **Mustache** engine out of the box. Any engine can be added by implementing the `TemplateEngine` interface.

---

## Install

```yaml
dependencies:
  darto: ^1.0.0
  darto_view: ^1.0.0
  mustache_template: ^2.0.0
  path: ^1.9.0
```

---

## Quick start

```dart
import 'package:darto/darto.dart';
import 'package:darto_view/darto_view.dart';

void main() async {
  final app = Darto();

  // Register the engine once — all handlers can call c.render().
  app.use(viewEngine(MustacheEngine(viewsPath: 'views')));

  app.get('/', [], (c) => c.render('index', {
    'title': 'Home',
    'items': ['Routing', 'Middleware', 'Validation'],
  }));

  app.get('/about', [], (c) => c.render('about', {
    'title': 'About',
    'version': '1.0.0',
  }));

  await app.listen(3000);
}
```

Place templates in the `views/` directory with a `.mustache` extension.

`views/index.mustache`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>{{title}}</title>
</head>
<body>
  <h1>{{title}}</h1>
  <ul>
    {{#items}}<li>{{.}}</li>{{/items}}
  </ul>
</body>
</html>
```

---

## `viewEngine(engine)` middleware

Registers `engine` as the view renderer for every handler downstream.  
Internally it calls `c.setRender(layout)` so `c.render(templateName, data)` works transparently.

```dart
// Global — all routes
app.use(viewEngine(MustacheEngine(viewsPath: 'views')));

// Scoped — only routes under /admin
app.mount('/admin/*', viewEngine(MustacheEngine(viewsPath: 'views/admin')));
```

---

## `MustacheEngine`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `viewsPath` | `String` | `'views'` | Directory where `.mustache` files live |

Compiled templates are **cached in memory** after the first render — no disk I/O on subsequent requests.

---

## Custom engines

Implement `TemplateEngine` to plug in any template system:

```dart
import 'package:darto_view/darto_view.dart';

class JinjaEngine implements TemplateEngine {
  final String viewsPath;
  JinjaEngine({this.viewsPath = 'views'});

  @override
  Future<String> render(String template, Map<String, dynamic> data) async {
    // load file, render with your preferred package, return HTML string
    throw UnimplementedError();
  }
}

// Register like any other engine
app.use(viewEngine(JinjaEngine(viewsPath: 'views')));
```

---

## Direct HTML (no template)

```dart
app.get('/ping', [], (c) => c.html('<h1>pong</h1>'));
```

---

## API reference

| Symbol | Description |
|---|---|
| `viewEngine(engine)` | Middleware — registers the engine on the context |
| `TemplateEngine` | Abstract class — implement to bring your own engine |
| `MustacheEngine({viewsPath})` | Built-in Mustache engine with in-memory caching |

---

## See also

- [darto](https://github.com/evandersondev/darto) — core framework
- [mustache_template](https://pub.dev/packages/mustache_template) — Mustache for Dart
- [examples/example_view_engine](../examples/example_view_engine/) — working example

<br/>

---

<br/>

### Support 💖

If you find Darto View useful, please consider supporting its development 🌟[Buy Me a Coffee](https://buymeacoffee.com/evandersondev).🌟 Your support helps us improve the package and make it even better!

<br/>
