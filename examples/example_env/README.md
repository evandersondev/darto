# example_env

What it demonstrates: Loading and reading environment variables with darto_env.

## Features
- `DartoEnv.load()` — reads `.env` file at startup
- `DartoEnv.get`, `DartoEnv.getInt`, `DartoEnv.getBool` — typed access with defaults
- `DartoEnv.maybeGet` — returns null if key is missing (never throws)
- `.env.example` included as a template

## Run
```bash
cp .env.example .env  # already provided
dart run bin/main.dart
```
