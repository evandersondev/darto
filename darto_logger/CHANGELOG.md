## 1.0.0

- Initial release.
- `Logger` — structured logging with levels (`debug`/`info`/`warn`/`error`),
  JSON or `pretty` output, a custom `output` sink, and `child(fields)` to bind
  contextual fields (e.g. a request id) onto every line.
- `requestLogger(logger)` middleware — logs `method`, `path`, `status` and
  `durationMs` per request, correlating with the id from `requestId()`.
