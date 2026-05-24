# example_static_files

What it demonstrates: Serving static files from a directory with darto_static.

## Features
- `serveStatic('public')` middleware serves files from the `public/` folder
- Mounted at `/public` path prefix
- Includes `public/index.html` and `public/style.css`

## Run
```bash
dart run bin/main.dart
```
Then visit: http://localhost:3000/public/index.html
