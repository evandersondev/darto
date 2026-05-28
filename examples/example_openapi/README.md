# example_openapi

OpenAPI 3.1 spec + Scalar docs with [`darto_openapi`](../../darto_openapi/).

## What it shows
- Declaring a route **once** with `api.get/post(...)` so the schema both
  **validates** the request and **feeds** the generated spec.
- `Schema.*` builders for params, query and JSON bodies.
- Serving `GET /openapi.json` (the document) and `GET /docs` (Scalar UI) via `api.docs()`.

## Run
```bash
dart run bin/main.dart

# Open the interactive docs:
open http://localhost:3000/docs

# Fetch the spec:
curl localhost:3000/openapi.json

# Invalid body → automatic 400 with issues:
curl -X POST localhost:3000/posts -H 'Content-Type: application/json' -d '{}'

# Valid:
curl -X POST localhost:3000/posts -H 'Content-Type: application/json' \
  -d '{"title":"Hello","tags":["dart"]}'
```
