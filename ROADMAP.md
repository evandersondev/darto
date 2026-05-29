# Darto — Análise do Ecossistema & Roadmap

> Objetivo: tornar o **Darto** um dos frameworks de referência para backend em Dart,
> no mesmo nível de maturidade do ecossistema JS/TS (Hono, Express, Fastify, NestJS,
> Elysia).
>
> Este documento inventaria o que o Darto já faz bem, mapeia as lacunas em relação ao
> ecossistema JS/TS e propõe um roadmap priorizado.

**Panorama:** `darto 1.1.0` · Dart `>=3.0.0` · servidor HTTP via `dart:io` · plugins:
`darto_cli 1.0.2`, `darto_env 1.0.1`, `darto_static 1.0.1`, `darto_validator 1.0.1`,
`darto_view 1.0.1`, `darto_ws 1.0.1`.

**Legenda** — Prioridade: **P0** essencial para credibilidade/adoção · **P1** alto valor ·
**P2** desejável.  Esforço: **S** ~dias · **M** ~1–2 semanas · **L** semanas+.

---

## Critério: core vs plugin (guia de contribuição)

Antes de adicionar uma funcionalidade, decida onde ela deve viver.

**Vai pro CORE se TODAS forem verdadeiras:**
- Sem dependência externa (ou só usa o que o core já tem: `crypto`, `mime`).
- Útil para quase todo aplicativo.
- API estável, com pouca configuração.
- Stateless ou com estado apenas local ao processo.

**Vira PLUGIN se QUALQUER uma for verdadeira:**
- Traz dependência externa (Redis, SMTP, SDK de OAuth, engine de template, lib de schema).
- É um subsistema com ciclo de vida/config próprios e cadência de release independente.
- É opinativo/de domínio (nem todo mundo quer aquele sabor específico).
- Precisa evoluir/quebrar sem arrastar o core junto.

**Padrão de duas camadas** (quando ambas fazem sentido): exponha a *primitiva
zero-dependência no core* e deixe os *backends pesados em um plugin*. Exemplos:
`cache` (core, em memória) ↔ `darto_cache` (Redis); `rateLimit` (core, em memória) ↔
adapters de store distribuído (plugin); `jwt` (core) ↔ `darto_auth` (subsistema).

> Distinção útil: **primitiva** = responde *uma* pergunta, um tijolo de Lego (ex.: `jwt`,
> `body_limit`) → vive no core; **subsistema** = experiência montada por cima de várias
> primitivas, com dependências e fluxos próprios (ex.: `darto_auth`) → vira plugin.

O custo dos extremos: *tudo no core* → inchaço de dependências, acoplamento de versão e
raio de explosão grande a cada breaking change; *tudo em plugin* → fragmentação, fricção
de instalação e matriz de versões complicada. O equilíbrio é **kernel estável + "pilhas
inclusas" sem dependência; plugin para qualquer coisa com dep ou domínio próprio.**

---

## 1. Resumo executivo

O Darto já é um **microframework capaz, com sabor de Hono**. A camada HTTP do core,
roteamento, o modelo Context/Request/Response, o pipeline de middlewares, streaming
(incluindo SSE), cookies, JWT/JWK, CORS/CSRF/secure-headers, sessões, compressão, cache,
um gerador de client tipado e uma CLI com hot-reload já estão prontos. A paridade de
funcionalidades com o **runtime + middlewares embutidos do Hono fica em torno de 80–90%**.

As lacunas que separam o Darto de ser tratado como um **framework de backend "oficial"**
estão concentradas em três áreas:

1. **Contratos de API & documentação** — não há geração de OpenAPI/Swagger. Essa é a
   peça ausente de maior alavancagem para adoção.
2. **Robustez de produção** — sem HTTPS/TLS, sem rate limiting, sem graceful shutdown,
   sem logging estruturado/observabilidade, cache apenas em memória, roteamento linear.
3. **Experiência de desenvolvimento para apps grandes** — sem client de teste in-memory,
   sem container de injeção de dependências, e alguns bugs de correção (veja §7).

O restante é polimento incremental. O roadmap da §8 sequencia esses pontos.

---

## 2. O que o Darto já tem (pontos fortes)

| Área | Capacidades |
|---|---|
| **Roteamento** | Todos os verbos, `all`, `on` (métodos custom/múltiplos × paths), params nomeados/opcionais/regex/wildcard, `route().get().post()` encadeado, `group`, `Router` standalone, `mount` com escopo de path, `basePath` global, modo estrito de barra final |
| **Context** | `c.body()` (response no estilo Hono), `json/text/html/redirect/binary/file/download/render`, helpers de status (`ok…internalError`), `status(code)`, `set/get`, `user`, `header`, metadados de rota (`routePath`, `basePath`, `matchedRoutes`) |
| **Request (`c.req`)** | `param*`, `query*`, `header(s)`, `json<T>`, `text`, `blob`, `arrayBuffer`, `parseBody` (uploads multipart **com streaming + saveDir**), `formData`, `body` (stream cru), `valid<T>` |
| **Respostas** | Tipo de valor `Response` imutável, codificação JSON (ciente de DateTime), bytes/empty/sent |
| **Erros** | `onError`, `notFound`, wrapper `DartoError` |
| **Middleware** | `cors`, `csrf`, `secure_headers`, `body_limit`, `compress` (gzip), `cache` (em memória), `logger`, `timing`, `timeout`, `session`, `context_storage` (async-local), `combine` (some/every), `api_key_auth`, `basic_auth`, `bearer_auth`, `jwt`, `jwk`, `require_roles`, `validator` |
| **Helpers** | `cookie` (+ cookies **assinados**), `jwt` sign/verify, `proxy`, `stream` / `streamText` / `streamSSE` (com detecção de desconexão do cliente), `dev`, `route` |
| **CLI** | `create` (scaffold), `dev` (hot restart), `build` (`dart compile exe` nativo), **`gen client`** (client de API tipado em Dart/Flutter, extraído das rotas em runtime) |
| **Plugins** | `env` (`.env` tipado), `static` (ETag/304/Range/gzip/Cache-Control), `validator` (schemas zard), `view` (engine plugável + Mustache, layout/render), `ws` (upgrade na mesma porta, onOpen/Message/Close/Error) |

Essa é uma base forte — as recomendações abaixo a complementam, em vez de substituí-la.

---

## 3. Análise de lacunas vs. ecossistema JS/TS

### 3.1 Core HTTP & servidor (robustez de produção)

| Lacuna | Por que importa | Ref (JS) | Prio | Esforço |
|---|---|---|---|---|
| ✅ **HTTPS/TLS** — via `serve(securityContext:)` / `listenSecure` | Não serve TLS diretamente; obriga proxy reverso até em deploys simples | Node `https`, Fastify `https` | ✅ 1.2.0 | — |
| ✅ **Bind de host/endereço** — `serve(host:)` + getters `port`/`address` | Bind em localhost / interface específica | todos | ✅ 1.2.0 | — |
| Suporte a **HTTP/2** | Performance moderna, gRPC-web, server push | Node http2, Fastify | P2 | M |
| ✅ **Graceful shutdown** — `stop()` drena in-flight; `serve` captura SIGINT/SIGTERM | Deploys sem downtime, k8s | Fastify `close`, stoppable | ✅ 1.2.0 | — |
| **Estrutura de dados do router** — lista linear + `RegExp.firstMatch` por rota | O(rotas) por requisição; degrada com centenas de rotas | Hono RegExpRouter/TrieRouter, Fastify find-my-way | P1 | M–L |
| **Redirect de barra final / opção case-insensitive** | Expectativa comum de SEO/UX | Express, Fastify | P2 | S |
| **Content negotiation** (`Accept`, `c.req.accepts`) | Servir JSON/HTML conforme o cliente | Express `req.accepts` | P2 | S |

### 3.2 Middlewares embutidos ausentes (vs. conjunto padrão do Hono)

| Middleware | Observações | Ref | Prio | Esforço |
|---|---|---|---|---|
| ✅ **Rate limiting** (in-memory) — `package:darto/rate_limit.dart` | `rateLimit()` zero-dep no core com interface `RateLimitStore` pronta para adapters distribuídos (§5) | express-rate-limit, hono rate-limiter | ✅ 1.2.0 (core) · plugin P1 | — |
| ✅ **ETag (respostas dinâmicas)** — `package:darto/etag.dart` | Só o `darto_static` fazia ETag; agora handlers dinâmicos também | hono `etag` | ✅ 1.2.0 | — |
| ✅ **Request ID** — `package:darto/request_id.dart` | Correlação entre logs/traces | hono `requestId` | ✅ 1.2.0 | — |
| **Adapter de cache distribuído** | `cache` é só em memória → sem escala horizontal, perdido no restart | hono cache (KV), Redis | P1 | M |
| **Pretty JSON** | DX ao navegar APIs | hono `prettyJSON` | P2 | S |
| **Method override** | `_method` para formulários HTML | method-override | P2 | S |
| **Restrição de IP / allowlist** | Endpoints admin | hono `ipRestriction` | P2 | S |
| **Idioma / i18n** (`Accept-Language`) | APIs localizadas | hono `languageDetector` | P2 | S |
| **Middleware de barra final** | Normalizar paths | hono `trailingSlash` | P2 | S |

### 3.3 Contratos de API, validação & clients tipados

| Lacuna | Por que importa | Ref | Prio | Esforço |
|---|---|---|---|---|
| ✅ **OpenAPI 3.1 + Scalar UI** — pacote `darto_openapi` (+ adapter `zard→OpenAPI` em `darto_validator`) | Fonte única: descreve a rota uma vez → valida `json`/`query`/`param`/`header` (com coerção), gera o spec e serve `/docs` (Scalar). Security schemes (Bearer/JWT/apiKey/basic). Reuso de schemas zard via `schema.toOpenApiSchema()` (zard ≥1.1.2). *Falta:* `$ref`/components dedup | NestJS Swagger, Fastify Swagger, Hono `@hono/zod-openapi`, Elysia OpenAPI | ✅ 1.0.0 + adapter | — |
| **Rotas schema-first** — associar um schema a uma rota e obter validação **+** serialização da resposta **+** OpenAPI em um só lugar | Remove boilerplate; fonte única de verdade | Elysia `t`, Fastify schema, zod-openapi | P1 | M–L |
| ✅ **Client type-safe ponta a ponta** — `generateDartClient(spec)` no `darto_openapi`: models tipados (`fromJson`/`toJson`) + método por operação a partir dos schemas. *Próximo:* expor via `darto gen client` | hono/client, Eden | ✅ 1.0.0 | — |

### 3.4 Arquitetura & DX para apps maiores

| Lacuna | Por que importa | Ref | Prio | Esforço |
|---|---|---|---|---|
| ✅ **Client de teste** — pacote `darto_test` (`TestClient`/`TestResponse`) | Testes herméticos sem gerenciar servidor/porta; boot em porta efêmera de loopback (estilo supertest). *True-socketless* exigiria abstrair `HttpRequest`/`HttpResponse` no core — futuro | hono `app.request`, supertest | ✅ 1.0.0 | — |
| **Injeção de dependências** — os scaffolds da CLI usam `final _service = XService()` (manual) | Testabilidade, mocks, ciclo de vida em apps estruturados | NestJS DI, get_it | P1 | L |
| **Hooks de ciclo de vida** além de middleware (`onRequest`, `preHandler`, `onResponse`, `onSend`) | Cross-cutting concerns granulares | Fastify hooks | P2 | M |
| **Roteamento por decorators/anotações** (opcional, via `build_runner`/macros) | Familiar para quem vem de NestJS/Spring | NestJS | P2 | L |

### 3.5 Observabilidade & operação

| Lacuna | Ref | Prio | Esforço |
|---|---|---|---|
| ✅ **Logging estruturado** — pacote `darto_logger` (`Logger` JSON/pretty, níveis, `child()` p/ correlação + middleware `requestLogger`) | pino, winston | ✅ 1.0.0 | — |
| ✅ **Helper de health/readiness** — `health()` no core (`package:darto/health.dart`, `/healthz`/`/readyz`) | Terminus, fastify-healthcheck | ✅ 1.2.0 | — |
| **Métricas** (Prometheus `/metrics`) | prom-client | P2 | M |
| **Tracing distribuído** (OpenTelemetry) | @opentelemetry | P2 | M–L |

### 3.6 Tempo real (`darto_ws`)

| Lacuna | Ref | Prio | Esforço |
|---|---|---|---|
| **Rooms / canais / broadcast / pub-sub** | Socket.IO rooms, Bun/Elysia pub-sub | P1 | M |
| **Heartbeat (ping/pong) + timeout de inatividade + backpressure** | ws, uWebSockets | P2 | S–M |
| SSE | ✅ já existe no core (`streamSSE`) | — | — |

### 3.7 Alcance de plataforma

| Lacuna | Ref | Prio | Esforço |
|---|---|---|---|
| **Adapters serverless/edge** (AWS Lambda, Cloud Run já funciona como container, Vercel) — Darto é só `dart:io` | Os adapters multi-runtime do Hono são um grande motor de adoção | P2 | M–L |

---

## 4. Já planejado, porém ausente (sinais do próprio repositório)

O código já aponta para pacotes que ainda não existem — candidatos de baixo risco e
alto sinal, porque a intenção já está estabelecida:

- **`darto_auth`** — referenciado por `examples/example_auth_jwt/pubspec.yaml`, mas ausente.
  → Construir um pacote de auth de verdade: estratégias de sessão, OAuth2/OIDC, helpers
  de hashing de senha, "providers" no estilo Passport/Lucia/Auth.js. **P1**.
- **`darto_logger`** — referenciado por `examples/example_logger/pubspec.yaml`, mas
  ausente; um `Logger` estruturado foi removido do core no v2. → Entregar um pacote
  dedicado de logging estruturado. **P1**.
- **`darto_mailer`** — `DartoMailer` foi removido do core no v2 (`darto_mailer_test` é
  um stub deprecado). → Reintroduzir como plugin (SMTP + e-mails com template). **P1**.

> Corrigir as duas referências quebradas de exemplo (auth/logger) também é uma pequena
> vitória de higiene de docs/repo, independentemente do resto.

---

## 5. Novos plugins propostos (expansão do ecossistema)

| Pacote | Propósito | Prio |
|---|---|---|
| ✅ **`darto_openapi`** | Rota/schema → spec OpenAPI 3.1 + Scalar UI; `Schema` builder valida+documenta (MVP: json body, /docs) | ✅ 1.0.0 |
| ✅ **`darto_test`** | Client de teste (`TestClient`/`TestResponse`) — boot em porta efêmera, `get/post/...`, `json`/`headers`/`cookies` | ✅ 1.0.0 |
| **`darto_rate_limit`** | Stores **distribuídos** (Redis/Memcached) por baixo do `rateLimit()` do core; algoritmos token-bucket/janela deslizante. (A versão in-memory zero-dep fica no core — veja §3.2; pode compartilhar infra com `darto_cache`) | P1 |
| ✅ **`darto_auth`** | Hashing de senha (PBKDF2) + auth por sessão (`signIn`/`authGuard`) entregues (1.0.0). *Falta:* OAuth2/OIDC, providers | ✅ 1.0.0 (parcial) |
| **`darto_logger`** | Logging JSON estruturado, níveis, correlação de request | P1 |
| **`darto_inject`** | Container leve de DI/IoC (ou integração first-class com `get_it`) | P1 |
| **`darto_cache`** | Adapters de cache distribuído (Redis/Memcached) atrás da API `cache` | P1 |
| **`darto_mailer`** | SMTP + e-mail transacional com template | P1 |
| **`darto_jobs`** | Jobs em background / cron / filas | P2 |
| **`darto_graphql`** | Integração de handler GraphQL | P2 |
| **`darto_otel`** | Tracing/métricas OpenTelemetry | P2 |

Além de uma **história de dados first-class**: um guia (e um adapter fino, se útil)
integrando o **Dartonic** (query builder/ORM já existente) aos handlers do Darto e à DI.

---

## 6. Quick wins (alto valor / baixo esforço — boas "good first issues")

1. **HTTPS via `listenSecure(port, SecurityContext)`** e um parâmetro `host`/`address` no `listen`. *(S)*
2. **Graceful shutdown**: capturar SIGTERM/SIGINT, parar de aceitar, drenar em andamento e sair. *(S)*
3. **Request ID + ETag (dinâmico) + Pretty JSON** — três middlewares pequenos e familiares. *(S cada)*
4. **Helper de health-check** (`app.health('/healthz')`). *(S)*
5. **Corrigir o bug de leitura de cookies** (veja §7) e adicionar testes de leitura de cookie assinado. *(S)*
6. **Reparar deps de exemplo quebradas** (`darto_auth`, `darto_logger`) ou converter esses exemplos para as APIs existentes. *(S)*

---

## 7. Problemas de correção encontrados nesta revisão

- ✅ **[CORRIGIDO] A leitura de cookies lia do response, não do request.**
  Em `darto/lib/src/helpers/cookie.dart`, `getCookies()` lia de
  `c.res.header('cookie')` — os cookies recebidos chegam no **request**. Como efeito
  colateral, `getCookie`/`getSignedCookie` e **as sessões** (`sessionMiddleware`) não
  conseguiam ler o cookie do cliente. Corrigido em três frentes: (1) ler de
  `c.req.header('cookie')`; (2) parsear no **primeiro `=`** (valores base64url contêm
  `=`); (3) `setCookie`/`setSignedCookie` usam `headers.add` em vez de `set`, para que
  múltiplos cookies gerem múltiplos `Set-Cookie`. Coberto por `test/src/cookie_test.dart`
  (cookies + round-trip assinado + regressão de sessão).
- **`cache` é em memória e local ao processo** — ok como padrão, mas documente a
  limitação e ofereça uma interface de store para que um adapter Redis possa plugar
  (veja §5).

---

## 8. Roadmap sugerido (sequenciado)

**Fase 1 — Credibilidade de produção (P0/P1)** — ✅ **concluída**
- ✅ `darto_openapi` (OpenAPI 3.1 + Scalar UI; MVP: valida o json body, gera o spec, serve `/docs`)
- ✅ `darto_test` (client de teste, boot em porta efêmera estilo supertest)
- ✅ `rateLimit()` in-memory zero-dep **no core** (darto 1.2.0; adapters distribuídos → Fase 2)
- ✅ HTTPS/TLS + bind de host + graceful shutdown — `serve`/`listenSecure` (darto 1.2.0)
- ✅ Bug de cookie corrigido + middlewares Request ID e ETag dinâmico (darto 1.2.0)

**Fase 2 — Robustez & DX**
- ✅ `darto_logger` estruturado (1.0.0) + helper de health-check no core (darto 1.2.0)
- ✅ `darto_auth` (1.0.0 — hashing PBKDF2 + auth por sessão)
- ✅ `darto_auth` 1.1.0 — OAuth2/OIDC (`OAuthProvider`, PKCE S256 + state CSRF, attach com `/start` e `/callback` em um liner, OIDC discovery via `.well-known`, factories `OAuthProvider.google` / `OAuthProvider.github`, decode de claims do `id_token`). Verificação de assinatura JWKS → fatia futura opcional.
- ✅ `darto_cache` 1.0.0 — interface `Cache` (get/set/delete/has/clear/close), `MemoryCache` zero-dep com LRU + TTL lazy, `RedisCache` (driver `redis` pure-Dart) com prefixo + codec JSON + `clear()` via SCAN+DEL, e helper `cache.remember(key, {ttl, builder})` read-through. Suite Redis sobe container Docker em porta efêmera.
- ✅ `darto_rate_limit` 1.0.0 — `RedisRateLimitStore` distribuído (script Lua: `INCR` + `PEXPIRE` condicional + `PTTL` em um round-trip; resetAt consistente entre instâncias). Plug-and-play no `rateLimit()` do core via `RateLimitStore`. Memcached adapter → futuro, se necessário.
- ✅ Client tipado ponta a ponta — `generateDartClient(spec)` no `darto_openapi` (gera models + client a partir dos schemas)
- ✅ Otimização de performance do router — matcher compilado: rotas literais (sem params/wildcards) casam por comparação direta de string (sem `RegExp`) e o dispatch faz short-circuit por método HTTP antes de avaliar o matcher (darto 1.2.0; semântica de roteamento inalterada). Trie/radix completo → futuro, se necessário.

**Fase 3 — Arquitetura para escalar**
- ✅ `darto_inject` 1.0.0 — `Provider<T>` / `AsyncProvider<T>` com escopo app/request, `contextProvider`, lifecycle (`onDispose` em ordem reversa), `override` para testes, `Feature(providers, routes)` + `app.install(...)` e scaffolds `darto gen feature/service` no `darto_cli` 1.1.0.
- ✅ `darto_ws` 1.1.0 — Rooms/broadcast via `WsHub` (registry de conexões, `to(room).except(ws)`/`broadcast()`, helpers `ws.id`/`join`/`leave`/`to`/`broadcast`), `hub.middleware()` para wiring automático, e `RedisWsAdapter` para fanout multi-instância (Pub/Sub com origin-id tagging). Breaking: `onClose`/`onError` agora recebem o socket. 10 testes (7 hub end-to-end + 3 Redis via Docker).
- ✅ `darto_mailer` 1.0.0 — `Mailer` + `Message`/`Attachment`, `SmtpTransport` (via package `mailer`, com `SmtpSecurity none/ssl/starttls`) e transports `ConsoleTransport`/`MemoryTransport` para dev/teste. 14 testes (12 unit + 2 SMTP via Mailpit no Docker). Templates → BYO (combina com `darto_view`).
- ✅ `darto_jobs` 1.0.0 — `JobQueue` (`add` imediato/`delay`/`scheduledAt`, `handle`, `work`, `onFailed`) + `Worker` (concorrência, sweep periódico, `stop()` com drain). Retry com backoff exponencial + dead-letter. `MemoryJobStore` (dev) e `RedisJobStore` at-least-once (reserve atômico via Lua + lease/sweep para crash recovery). 12 testes (7 memory + 5 Redis via Docker: durabilidade, dead-letter, recovery, sem double-processing entre workers).

**Fase 4 — Alcance & avançado**
- Métricas + OpenTelemetry (`darto_otel`)
- Adapters serverless/edge; HTTP/2
- `darto_graphql`; roteamento por decorators (build_runner/macros)

---

## 9. Checklist de "framework oficial"

- [ ] OpenAPI/Swagger pronto de fábrica
- [ ] Testes first-class (client in-memory)
- [ ] HTTPS, graceful shutdown, rate limiting
- [ ] Logging estruturado + health checks (+ métricas/tracing)
- [ ] Pacote de auth (sessões/OAuth/OIDC)
- [ ] História de DI para apps grandes
- [ ] Adapters de cache distribuído
- [ ] Client type-safe ponta a ponta
- [ ] Router performático em escala
- [ ] Rooms/broadcast em tempo real
- [ ] 1.x estável com disciplina de semver, docs ricas e uma página de benchmarks
