# ── Stage 1: Build ────────────────────────────────────────────────────────────
FROM dart:stable AS build

WORKDIR /app

# Cache pub dependencies separately from source for faster rebuilds
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart pub get --offline
RUN dart compile exe bin/server.dart -o bin/server

# ── Stage 2: Minimal runtime ──────────────────────────────────────────────────
# Uses scratch + Dart /runtime/ — significantly smaller than debian:slim
FROM scratch

# Dart AOT runtime — minimal shared libs (libc, libpthread, libm, libdl)
COPY --from=build /runtime/ /

# CA certificates for outbound HTTPS requests
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

COPY --from=build /app/bin/server /app/server

EXPOSE 3000

CMD ["/app/server"]
