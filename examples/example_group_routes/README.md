# example_group_routes

What it demonstrates: Route grouping with `app.route()` and `app.group()`.

## Features
- `app.route('/api/v1', ...)` — inline group with v1 routes
- `app.route('/api/v2', ...)` — inline group with v2 routes
- `app.group('/admin')` — alternative group style returning a Router

## Run
```bash
dart run bin/main.dart
```
