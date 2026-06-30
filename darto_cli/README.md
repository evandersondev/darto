# darto_cli

Official CLI for the [Darto](https://github.com/evandersondev/darto) framework. Scaffold projects, run a development server, compile to a native binary, and generate typed API clients.

---

## Installation

```sh
dart pub global activate darto_cli
```

Make sure `~/.pub-cache/bin` is on your `PATH`.

---

## Usage

```sh
darto <command> [arguments]
```

```sh
darto --help     # Show help
darto --version  # Show version
```

---

## Commands

### `darto create <name>`

Scaffold a new Darto project with a ready-to-run directory structure and a starter `user` module.

```sh
darto create my_api
```

**Generated structure:**

```
my_api/
  bin/
    server.dart
  lib/
    app.dart
    modules/
      user/
        user_controller.dart   ← handlers + route registration
        user_service.dart      ← business logic
  pubspec.yaml
  analysis_options.yaml
```

Runs `dart pub get` automatically after scaffolding.

---

### `darto create <name> --template <t>`

Choose a project template with `--template` (`-t`). Available templates:

| Template  | What you get |
| --------- | ------------ |
| `default` | Starter project with an example `user` module (controller + service). |
| `blank`   | Minimal project — just a `/health` route. |
| `openapi` | REST API where **one zard schema validates the request AND generates the OpenAPI 3.1 docs**, served with the Scalar UI at `/docs`. Includes tests. |

```sh
darto create my_api                      # default
darto create my_api --template openapi   # validation + OpenAPI docs
darto create my_api --template blank
```

#### `--template openapi` structure

```
my_api/
  bin/
    server.dart
  lib/
    app.dart                  ← OpenAPIDarto(app) + routes + /docs (Scalar)
    schemas/
      user_schema.dart        ← one schema: validates AND documents
  test/
    app_test.dart             ← boots the app, asserts validation + spec
  pubspec.yaml                ← darto + darto_zard_openapi
  analysis_options.yaml
  .gitignore
```

### `darto create <name> --blank`

Alias for `--template blank`: a minimal project with no starter module — just the
server entry point and a `/health` route.

```sh
darto create my_api --blank
darto create my_api -b
```

**Generated structure:**

```
my_api/
  bin/
    server.dart
  lib/
    app.dart    ← GET /health only
  pubspec.yaml
  analysis_options.yaml
```

---

### `darto dev [entrypoint]`

Start the server in development mode with automatic hot restart on file changes.

```sh
darto dev
darto dev bin/server.dart
```

- Watches `lib/`, `bin/`, and `src/` recursively for `.dart` changes.
- Batches multiple simultaneous saves into a single restart (350 ms debounce).
- Shows which files changed and how long the restart took.
- Kills the previous process with SIGTERM (300 ms grace period) then SIGKILL.
- Default entrypoints tried in order: `bin/server.dart`, `bin/main.dart`, `lib/main.dart`.

---

### `darto build [entrypoint]`

Compile the server to a native self-contained executable and generate Docker deployment artifacts.

```sh
darto build
darto build bin/server.dart --output build/my_server
darto build --no-docker   # skip Dockerfile generation
```

| Flag | Description |
|------|-------------|
| `--output`, `-o` | Output path (default: `build/server`) |
| `--no-docker` | Skip Dockerfile and .dockerignore generation |

**Docker artifacts generated (only if not already present):**

- `Dockerfile` — optimized multi-stage image: compiles inside Docker using `dart:stable`, then copies to a minimal `scratch` image with only the Dart `/runtime/` libraries (~25–35 MB final image).
- `.dockerignore` — excludes source and dev files from the Docker build context.

```sh
# Build and run with Docker
docker build -t my_app .
docker run -p 3000:3000 my_app
```

---

### `darto start [binary]`

Run a pre-compiled binary.

```sh
darto start
darto start build/my_server
```

Default binary path: `build/server`.

---

### `darto gen client flutter`

Generate a typed, modular Dart/Flutter HTTP client from your Darto server's route metadata.

```sh
darto gen client flutter
darto gen client flutter --output lib/src/api_client.dart --base-url https://api.example.com
```

| Flag | Default | Description |
|------|---------|-------------|
| `--input`, `-i` | `lib/app.dart` | File that exports `createApp()` returning a `Darto` instance |
| `--output`, `-o` | `lib/api_client.dart` | Where to write the generated file |
| `--base-url`, `-b` | `http://localhost:3000` | Default base URL embedded in the client |
| `--class` | `ApiClient` | Root class name |

The `http` package is added to `pubspec.yaml` automatically if not already present.

**What is generated:**

- A root `ApiClient` class with `setToken` / `clearToken` helpers.
- One sub-module class per route group (e.g. `UsersModule`, `AuthModule`).
- Typed async methods for every route.
- An `ApiException` class for HTTP error responses.

**Example output usage:**

```dart
final api = ApiClient(baseUrl: 'https://api.example.com');
api.setToken(accessToken);

final users = await api.users.getAll();
final user  = await api.users.getById('42');
await api.users.create(body: {'name': 'Alice', 'email': 'alice@example.com'});
await api.auth.login(body: {'email': 'alice@example.com', 'password': 'secret'});
```

---

## Example workflow

```sh
# 1. Create a new project
darto create shop_api
cd shop_api

# 2. Start the dev server (auto-restarts on file changes)
darto dev

# 3. Generate a Flutter client
darto gen client flutter --base-url http://localhost:3000

# 4. Compile for production (also generates Dockerfile)
darto build

# 5. Run the compiled binary
darto start

# Or deploy with Docker
docker build -t shop_api .
docker run -p 3000:3000 shop_api
```

---

## See also

- [darto](https://github.com/evandersondev/darto) — core framework

<br/>

---

<br/>

### Support 💖

If you find Darto CLI useful, please consider supporting its development 🌟[Buy Me a Coffee](https://buymeacoffee.com/evandersondev).🌟 Your support helps us improve the package and make it even better!

<br/>
