# Darto — Novidades

Resumo das melhorias no **core** e dos **plugins** do ecossistema Darto. Para o
plano completo e o status por fase, veja o [`ROADMAP.md`](./ROADMAP.md).

> Cada item diz **pra que serve** e **quando usar**. As versões são as atuais no
> monorepo (algumas ainda não publicadas no pub.dev — veja "Ordem de publicação"
> no fim).

---

## Core — `darto` 1.2.0

A camada principal ganhou o que faltava para rodar em produção de verdade:
binding seguro, shutdown limpo, middlewares de operação e um router mais rápido.

### Endurecimento do servidor (produção)
- **`serve({port, host, securityContext, shutdownSignals, onListen})`** — controle
  total de bind de host e **HTTPS/TLS** (via `securityContext`).
- **`listenSecure(port, securityContext)`** — atalho para HTTPS.
- **Graceful shutdown** — `stop({drainTimeout})` para de aceitar conexões novas e
  **drena as requisições em andamento** antes de fechar. Por padrão, `serve`/
  `listen` capturam `SIGINT`/`SIGTERM` e desligam graciosamente.
- **`port` / `address`** — getters úteis para bind efêmero (`serve(port: 0)`) e testes.

### Novos middlewares e helper (no core, zero-dep)
- **`requestId()`** (`package:darto/request_id.dart`) — gera um UUID v4 por
  requisição (respeita header de entrada), guarda no contexto e ecoa na resposta.
  *Pra que serve:* correlacionar logs/traces de uma mesma requisição.
- **`etag()`** (`package:darto/etag.dart`) — ETag para respostas dinâmicas com
  `304 Not Modified` automático no `If-None-Match`. *Pra que serve:* economizar
  banda em respostas que não mudaram.
- **`rateLimit()`** (`package:darto/rate_limit.dart`) — limita requisições por
  chave numa janela; in-memory zero-dep por padrão, com interface
  `RateLimitStore` plugável. Emite headers `RateLimit-*` + `Retry-After`.
  *Pra que serve:* proteger endpoints contra abuso.
- **`health()`** (`package:darto/health.dart`) — handler de liveness/readiness que
  retorna `200`/`503` a partir de checks nomeados. *Pra que serve:* `/healthz` e
  `/readyz` para orquestradores (Kubernetes, etc.).

### Performance do router
- Rotas **literais** (sem params/wildcards/regex) casam por **comparação direta de
  string** em vez de `RegExp` — o caso mais comum no caminho quente (~100× mais
  barato por match num micro-benchmark). O dispatch também faz **short-circuit por
  método HTTP** antes de avaliar o matcher. Semântica de roteamento **inalterada**.

### Correções
- Cookie helpers leem o header **`Cookie` da requisição** (não da resposta),
  tratam valores com `=` (base64url) e emitem múltiplos `Set-Cookie`. Corrige
  também a leitura de sessão.
- `sessionContext(c).get()` retorna `null` (em vez de lançar `TypeError`) quando
  não há sessão ativa.

> **Nota (1.1.0, alinhamento com HonoJS):** `c.body()` agora é helper de
> **resposta**; a **leitura do corpo** vive em `c.req` (`json` / `text` / `blob` /
> `arrayBuffer` / `parseBody` / `body`).

---

## Plugins novos

### `darto_inject` 1.0.0 — Injeção de dependência tipada
**Pra que serve:** organizar serviços/dependências sem boilerplate, sem codegen e
sem decorators.
- `Provider<T>` / `AsyncProvider<T>` com escopo **app** (singleton) ou **request**.
- `contextProvider` para ler o `Context` dentro de uma factory de request-scope.
- `Di.middleware()` expõe o container aos handlers; `c.read(provider)` resolve.
- `override(...)` para trocar dependências em testes; `onDispose` no shutdown.
- `Feature(providers, routes)` + `app.install(...)` para agrupar fatias do app.
- Scaffolds na CLI: `darto gen feature` / `darto gen service`.

**Quando usar:** assim que o app tem mais de um serviço compartilhado (DB, cache,
mailer) e você quer testabilidade.

### `darto_cache` 1.0.0 — Cache (memória + Redis)
**Pra que serve:** guardar resultados caros (queries, chamadas externas) e
servir rápido.
- Interface `Cache` (`get/set/delete/has/clear/close`).
- `MemoryCache` zero-dep com **LRU + TTL**; `RedisCache` para cache **compartilhado**
  entre instâncias.
- Helper read-through `cache.remember(key, {ttl, builder})` — o caso de 90%.

**Quando usar:** reduzir latência/carga em dados lidos com frequência.

### `darto_rate_limit` 1.0.0 — Rate limit distribuído
**Pra que serve:** o mesmo limite valendo em **várias réplicas** atrás de um load
balancer.
- `RedisRateLimitStore` — plugue no `rateLimit()` do core via `store:`.
- Script Lua atômico (`INCR` + `PEXPIRE` + `PTTL`) — `resetAt` consistente entre
  instâncias, sem perder contagem.

**Quando usar:** quando o app roda em mais de um processo/máquina.

### `darto_auth` 1.1.0 — Autenticação
**Pra que serve:** login com senha, sessão e **OAuth/OIDC** sem reinventar cripto.
- Hash de senha **PBKDF2-HMAC-SHA256** (`hashPassword` / `verifyPassword`),
  verificação em tempo constante.
- Sessão: `signIn` / `signOut` / `authUser` + middleware `authGuard()`.
- **OAuth 2.0 / OIDC** (novo): `OAuthProvider` com PKCE + state, discovery OIDC,
  factories `OAuthProvider.google(...)` / `.github(...)`, `attach(app, prefix, onSignIn)`.

**Quando usar:** qualquer app com usuários — login local e/ou "entrar com Google/GitHub".

### `darto_logger` 1.0.0 — Logging estruturado
**Pra que serve:** logs em **JSON** (ou pretty no dev) com níveis e campos,
prontos para agregadores.
- `Logger` (níveis debug/info/warn/error, JSON/pretty, `child(fields)`).
- Middleware `requestLogger(logger)` que correlaciona com o `requestId()` do core.

**Quando usar:** observabilidade — saber o que aconteceu em produção.

### `darto_mailer` 1.0.0 — Envio de e-mail
**Pra que serve:** mandar e-mail (boas-vindas, reset de senha, magic-link).
- `Mailer` + `Message` / `Attachment`.
- `SmtpTransport` (qualquer provedor SMTP, `none/ssl/starttls`) + `ConsoleTransport`
  e `MemoryTransport` para dev/teste sem rede.

**Quando usar:** notificações transacionais. Combine com `darto_jobs` para enviar
em background.

### `darto_jobs` 1.0.0 — Filas de jobs em background
**Pra que serve:** tirar trabalho lento do caminho da resposta HTTP (e-mail,
relatórios, webhooks).
- `JobQueue` (`add` imediato/`delay`/`scheduledAt`, `handle`, `work`, `onFailed`).
- `Worker` com concorrência e `stop()` que drena.
- Retry com **backoff exponencial** → dead-letter.
- `MemoryJobStore` (dev) e `RedisJobStore` **at-least-once** (lease + sweep para
  sobreviver a crash de worker; múltiplos processos compartilham a fila).

**Quando usar:** quando uma rota faria o cliente esperar por algo demorado.

---

## Plugins atualizados

### `darto_ws` 1.1.0 — WebSocket com rooms e broadcast
**Pra que serve:** real-time (chat, notificações ao vivo) na mesma porta do HTTP.
- **`WsHub`** — registry de conexões + rooms: `ws.join(room)`,
  `ws.to(room).except(ws).send(...)`, `hub.broadcast()`, `ws.id`/`ws.rooms`.
- `hub.middleware()` para wiring automático nas factories.
- **`RedisWsAdapter`** — Pub/Sub para fanout **multi-instância** (broadcasts
  cruzam réplicas, com supressão de echo por origin-id).
- *Breaking:* `onClose`/`onError` agora recebem o socket.

### `darto_cli` 1.1.0 — CLI
- Novos scaffolds `darto gen feature <name>` e `darto gen service <name>`
  (geram o boilerplate de `darto_inject`).

### `darto_validator` 1.1.0 / `darto_static` 1.0.2 / `darto_view` 1.0.2
- Requerem `darto: ^1.2.0` (e `darto_validator` ganhou `toOpenApiSchema()`).

---

## Local-only (ainda não no pub.dev)

- **`darto_openapi` 1.0.0** — gera spec **OpenAPI 3.1** + docs **Scalar** a partir
  de rotas descritas uma vez (valida o request **e** documenta), e gera um
  **client Dart tipado** a partir do spec. *Pra que serve:* documentação viva +
  contrato de API.
- **`darto_test` 1.1.0** — client de teste estilo supertest (sobe o app numa porta
  efêmera e faz asserts). *Pra que serve:* testar rotas de ponta a ponta sem
  gerenciar servidor; usado como `dev_dependency` pelos outros packages.

---

## Ordem de publicação (pub.dev)

Plugins versionam suas deps internas, então a ordem importa:

1. **`darto`** (core) — todos dependem dele.
2. **`zard`** (repo separado) — antes do `darto_validator`.
3. **`darto_test`** — usado como `dev_dependency` por vários.
4. **Demais plugins** — `darto_inject`, `darto_cache`, `darto_rate_limit`,
   `darto_auth`, `darto_logger`, `darto_mailer`, `darto_jobs`, `darto_ws`,
   `darto_openapi`, `darto_cli`, `darto_static`, `darto_validator`, `darto_view`,
   `darto_env`.

> `darto_cache`, `darto_mailer` e `darto_jobs` **não dependem do darto** e podem
> ser publicados de forma independente. Os `dependency_overrides` (caminhos locais)
> são ignorados pelo pub.dev no momento da publicação.
