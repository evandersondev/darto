---
name: darto-scaffold-project
description: Scaffold, run, and build a Darto (Dart) web project using the darto_cli — create a new project with a NestJS-style module structure, run a hot-reload dev server, compile a production binary, and generate a typed API client. Use when starting a new Darto app, setting up the project layout, or configuring dev/build commands.
---

# Scaffold & run a Darto project

The official `darto_cli` scaffolds projects and provides dev/build tooling.
Use it when starting a new app or wiring up run/build commands.

## Install the CLI (once)

```sh
dart pub global activate darto_cli
```

Make sure `~/.pub-cache/bin` is on your `PATH` (otherwise the `darto` command
won't be found).

## Create a project

```sh
darto create my_api
cd my_api
dart pub get
```

This generates a ready-to-run project with a **NestJS-style module structure**:

```
my_api/
  bin/server.dart            # entrypoint — boots the app and listens
  lib/
    app.dart                 # createApp() — registers modules/routes; CLI introspects this
    config/env.dart          # environment config
    modules/
      user/
        user_controller.dart # route handlers (Context-based)
        user_service.dart    # business logic
        user_repository.dart # data access
        user_routes.dart     # wires the module's routes onto a Router/group
```

Convention: one folder per **module** under `lib/modules/`, each splitting
routes → controller → service → repository. New features = a new module folder
following the same split, mounted in `app.dart`.

## Develop with hot reload

```sh
darto dev                 # watches lib/, bin/, src/; auto-restarts on .dart change
darto dev bin/main.dart   # specify a custom entrypoint
```

## Build for production

```sh
darto build                                   # compile to build/server + generate Dockerfile
darto build --output build/my_server --no-docker
darto start                                   # run the compiled binary
```

## Generate a typed client (optional)

`darto_cli` can read `createApp()` from `lib/app.dart`, introspect every
registered route, and emit a fully typed Dart/Flutter API client:

```sh
darto gen client flutter
darto gen client flutter --output lib/src/api_client.dart --base-url https://api.example.com
```

```dart
final api = ApiClient(baseUrl: 'https://api.example.com');
api.setToken(accessToken);
final users = await api.users.getAll();
final user  = await api.users.getById('42');
```

## Minimal manual setup (no CLI)

If you'd rather not use the CLI, a project only needs the `darto` dependency and
an entrypoint:

```yaml
# pubspec.yaml
dependencies:
  darto: ^1.2.0
```

```dart
// bin/main.dart
import 'package:darto/darto.dart';

void main() {
  final app = Darto();
  app.get('/', [], (Context c) => c.ok({'status': 'up'}));
  app.listen(3000, () => print('http://localhost:3000'));
}
```

Run it with `dart run bin/main.dart`.

## After scaffolding

- Add endpoints → use the `darto-add-route` skill.
- Add validation → `darto-validate-request`.
- Add middleware / error handling → `darto-write-middleware`.
- Pull in ecosystem packages as needed: `darto_validator`, `darto_ws`,
  `darto_view`, `darto_static`, `darto_env`, `darto_auth`, `darto_inject`,
  `darto_cache`, `darto_jobs`, `darto_mailer`, `darto_openapi`, `darto_logger`.
