# example_validation

What it demonstrates: Request body and query string validation with darto_validation and zard schemas.

## Features
- `validate(schema)` middleware — validates JSON body, stores result in `c.validated()`
- `validateQuery(schema)` middleware — validates query params
- Automatic 400 response on validation failure with field-level error details

## Run
```bash
dart run bin/main.dart
```
