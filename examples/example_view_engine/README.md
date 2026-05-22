# example_view_engine

What it demonstrates: Server-side Mustache template rendering with darto_view.

## Features
- `ViewEngine(viewsPath: 'views')` — points to the views directory
- `view.render(c, 'template', data)` — renders a `.mustache` template and returns HTML
- Templates: `views/index.mustache`, `views/about.mustache`

## Run
```bash
dart run bin/main.dart
```
Then visit: http://localhost:3000/ and http://localhost:3000/about
