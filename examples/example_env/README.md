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

<br/>

---

<br/>

### Support 💖

If you find Darto useful, please consider supporting its development 🌟[Buy Me a Coffee](https://buymeacoffee.com/evandersondev).🌟 Your support helps us improve the package and make it even better!

<br/>
