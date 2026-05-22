# example_upload

What it demonstrates: Multipart file uploads with darto_upload.

## Features
- `upload.single('file')` — accepts one file, stores metadata in `c.get('file')`
- `upload.multiple('files')` — accepts multiple files, stores list in `c.get('files')`
- Files are saved to the `uploads/` directory automatically

## Run
```bash
dart run bin/main.dart
```
