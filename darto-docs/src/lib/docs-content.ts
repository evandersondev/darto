export type Lang = "en" | "pt";

export type Block =
  | { kind: "p"; text: string }
  | { kind: "code"; lang?: "dart" | "yaml" | "sh" | "html"; code: string; filename?: string }
  | { kind: "h3"; text: string; id?: string }
  | { kind: "ul"; items: string[] }
  | { kind: "table"; headers: string[]; rows: string[][] }
  | { kind: "note"; text: string }
  | { kind: "callout"; variant: "tip" | "warning" | "success"; text: string }
  | { kind: "links"; links: { label: string; href: string }[] }
  | { kind: "ref"; to: string; label: string };

export interface DocSection {
  id: string;
  title: string;
  group: "start" | "api" | "helpers" | "middlewares" | "plugins" | "advanced" | "migration";
  blocks: Block[];
}

type Bi<T> = { en: T; pt: T };
const bi = <T>(en: T, pt: T): Bi<T> => ({ en, pt });

interface BiSection {
  id: string;
  group: DocSection["group"];
  title: Bi<string>;
  blocks: Bi<Block[]>;
}

const SECTIONS: BiSection[] = [
  {
    id: "installation",
    group: "start",
    title: bi("Installation", "Instalação"),
    blocks: bi(
      [
        { kind: "p", text: "Add Darto to your pubspec.yaml:" },
        {
          kind: "code",
          lang: "yaml",
          filename: "pubspec.yaml",
          code: `dependencies:\n  darto: ^1.2.0`,
        },
        { kind: "p", text: "Or use the pub command directly:" },
        { kind: "code", lang: "sh", code: `dart pub add darto` },
      ],
      [
        { kind: "p", text: "Adicione o Darto ao seu pubspec.yaml:" },
        {
          kind: "code",
          lang: "yaml",
          filename: "pubspec.yaml",
          code: `dependencies:\n  darto: ^1.2.0`,
        },
        { kind: "p", text: "Ou use o comando pub diretamente:" },
        { kind: "code", lang: "sh", code: `dart pub add darto` },
      ],
    ),
  },
  {
    id: "quick-start",
    group: "start",
    title: bi("Quick Start", "Início rápido"),
    blocks: bi(
      [
        {
          kind: "p",
          text: "Spin up a server in under a minute. Define a Darto instance, register a route, listen on a port.",
        },
        {
          kind: "code",
          code: `import 'package:darto/darto.dart';\n\nvoid main() {\n  final app = Darto();\n\n  app.get('/users/:id', [], (Context c) {\n    final id = c.req.param('id');\n    return c.ok({'id': id});\n  });\n\n  app.listen(3000, () => print('Listening on http://localhost:3000'));\n}`,
        },
        {
          kind: "callout",
          variant: "tip",
          text: "Use response helpers (c.ok, c.created, c.badRequest…) for clean status-code handling without manual headers.",
        },
      ],
      [
        {
          kind: "p",
          text: "Suba um servidor em menos de um minuto. Defina uma instância de Darto, registre uma rota e ouça uma porta.",
        },
        {
          kind: "code",
          code: `import 'package:darto/darto.dart';\n\nvoid main() {\n  final app = Darto();\n\n  app.get('/users/:id', [], (Context c) {\n    final id = c.req.param('id');\n    return c.ok({'id': id});\n  });\n\n  app.listen(3000, () => print('Listening on http://localhost:3000'));\n}`,
        },
        {
          kind: "callout",
          variant: "tip",
          text: "Use os helpers de resposta (c.ok, c.created, c.badRequest…) para tratar status sem montar headers manualmente.",
        },
      ],
    ),
  },
  {
    id: "core-concepts",
    group: "start",
    title: bi("Core Concepts", "Conceitos centrais"),
    blocks: bi(
      [
        { kind: "p", text: "Three typedefs are all you need to understand the entire framework:" },
        {
          kind: "code",
          code: `typedef Handler    = FutureOr<Response>? Function(Context c);\ntypedef Middleware = FutureOr<void>      Function(Context c, Next next);\ntypedef Next       = Future<void>        Function();`,
        },
        {
          kind: "ul",
          items: [
            "A handler receives a Context and returns a Response.",
            "A middleware receives a Context and a Next callback.",
            "Call await next() to continue the pipeline; return without it to short-circuit.",
          ],
        },
        {
          kind: "callout",
          variant: "success",
          text: "If you've used Hono, you already know Darto — the mental model is identical.",
        },
      ],
      [
        {
          kind: "p",
          text: "Três typedefs são tudo o que você precisa entender para usar o framework inteiro:",
        },
        {
          kind: "code",
          code: `typedef Handler    = FutureOr<Response>? Function(Context c);\ntypedef Middleware = FutureOr<void>      Function(Context c, Next next);\ntypedef Next       = Future<void>        Function();`,
        },
        {
          kind: "ul",
          items: [
            "Um handler recebe um Context e retorna uma Response.",
            "Um middleware recebe um Context e um callback Next.",
            "Chame await next() para continuar a pipeline; retorne sem chamar para parar.",
          ],
        },
        {
          kind: "callout",
          variant: "success",
          text: "Se você já usou Hono, já conhece Darto — o modelo mental é idêntico.",
        },
      ],
    ),
  },
  {
    id: "application",
    group: "api",
    title: bi("Application", "Aplicação"),
    blocks: bi(
      [
        { kind: "h3", text: "Creating the app", id: "app-create" },
        {
          kind: "code",
          code: `final app = Darto();             // default (non-strict trailing slash)\nfinal app = Darto(strict: true); // /users ≠ /users/`,
        },
        { kind: "h3", text: "Global base path", id: "app-basepath" },
        {
          kind: "code",
          code: `final app = Darto().basePath('/v1');\n\napp.get('/users', [], handler); // registered as /v1/users`,
        },
        { kind: "h3", text: "Starting and stopping", id: "app-listen" },
        {
          kind: "code",
          code: `app.listen(3000);\napp.listen(3000, () => print('ready'));\n\n// Host binding, HTTPS/TLS and graceful-shutdown signals\nawait app.serve(port: 8080, host: 'localhost');\nawait app.listenSecure(443, securityContext);\n\nawait app.stop();                 // graceful drain of in-flight requests\nint? port = app.port;             // bound port (e.g. after serve(port: 0))\nbool running = app.isRunning;`,
        },
        {
          kind: "p",
          text: "By default serve / listen trap SIGINT/SIGTERM and shut down gracefully — pass shutdownSignals: false to opt out.",
        },
        { kind: "ref", to: "routing", label: "HTTP verbs (app.get / post / …) → see Routing" },
      ],
      [
        { kind: "h3", text: "Criando o app", id: "app-create" },
        {
          kind: "code",
          code: `final app = Darto();             // padrão (trailing slash não-estrito)\nfinal app = Darto(strict: true); // /users ≠ /users/`,
        },
        { kind: "h3", text: "Base path global", id: "app-basepath" },
        {
          kind: "code",
          code: `final app = Darto().basePath('/v1');\n\napp.get('/users', [], handler); // registrado como /v1/users`,
        },
        { kind: "h3", text: "Subindo e parando", id: "app-listen" },
        {
          kind: "code",
          code: `app.listen(3000);\napp.listen(3000, () => print('pronto'));\n\n// Bind de host, HTTPS/TLS e sinais de graceful shutdown\nawait app.serve(port: 8080, host: 'localhost');\nawait app.listenSecure(443, securityContext);\n\nawait app.stop();                 // drena requisições em andamento\nint? port = app.port;             // porta vinculada (ex.: serve(port: 0))\nbool running = app.isRunning;`,
        },
        {
          kind: "p",
          text: "Por padrão serve / listen capturam SIGINT/SIGTERM e desligam graciosamente — passe shutdownSignals: false para desativar.",
        },
        { kind: "ref", to: "routing", label: "Verbos HTTP (app.get / post / …) → veja Roteamento" },
      ],
    ),
  },
  {
    id: "routing",
    group: "api",
    title: bi("Routing", "Roteamento"),
    blocks: bi(
      [
        { kind: "h3", text: "HTTP verbs", id: "routing-verbs" },
        {
          kind: "p",
          text: "All verb methods take the middleware list as the second argument (required — pass [] for no middleware) and the handler last.",
        },
        {
          kind: "code",
          code: `app.get(path, [], handler);\napp.post(path, [], handler);\napp.put(path, [], handler);\napp.patch(path, [], handler);\napp.delete(path, [], handler);\n\napp.all(path, [], handler);\napp.on(['GET', 'POST'], ['/a', '/b'], [], handler);`,
        },
        { kind: "h3", text: "Route parameters", id: "routing-params" },
        {
          kind: "code",
          code: `app.get('/users/:id', [], (c) => c.ok({'id': c.req.param('id')}));\napp.get('/posts/:slug?', [], handler);          // optional\napp.get('/items/:id(\\d+)', [], handler);        // regex constraint\napp.get('/files/*path', [], handler);           // named wildcard\napp.get('/assets/*', [], handler);              // unnamed wildcard`,
        },
        { kind: "h3", text: "Route groups", id: "routing-groups" },
        {
          kind: "code",
          code: `// Fluent chain\napp.route('/users')\n  .get([], listUsers)\n  .post([auth()], createUser);\n\n// Builder callback\napp.route('/users', (r) {\n  r.get('/', [], listUsers);\n  r.post('/', [auth()], createUser);\n  r.get('/:id', [], getUser);\n});\n\n// group() prefix\nfinal api = app.group('/api');\napi.get('/status', [], (c) => c.ok({'ok': true}));`,
        },
        {
          kind: "callout",
          variant: "tip",
          text: "Groups compose: app.group('/api').group('/v2').get('/ping', [], …) registers GET /api/v2/ping.",
        },
        {
          kind: "callout",
          variant: "success",
          text: "Fast matcher: literal routes (no params or wildcards) match by a direct string compare on the dispatch hot path — only dynamic routes use the compiled matcher — and dispatch short-circuits on the HTTP method first. No configuration needed.",
        },
        { kind: "ref", to: "context", label: "Handler signature → see Context" },
        { kind: "ref", to: "request", label: "Reading params / query → see Request" },
      ],
      [
        { kind: "h3", text: "Verbos HTTP", id: "routing-verbs" },
        {
          kind: "p",
          text: "Todos os métodos de verbo recebem a lista de middlewares como segundo argumento (obrigatório — passe [] para nenhum middleware) e o handler por último.",
        },
        {
          kind: "code",
          code: `app.get(path, [], handler);\napp.post(path, [], handler);\napp.put(path, [], handler);\napp.patch(path, [], handler);\napp.delete(path, [], handler);\n\napp.all(path, [], handler);\napp.on(['GET', 'POST'], ['/a', '/b'], [], handler);`,
        },
        { kind: "h3", text: "Parâmetros de rota", id: "routing-params" },
        {
          kind: "code",
          code: `app.get('/users/:id', [], (c) => c.ok({'id': c.req.param('id')}));\napp.get('/posts/:slug?', [], handler);          // opcional\napp.get('/items/:id(\\d+)', [], handler);        // restrição regex\napp.get('/files/*path', [], handler);           // wildcard nomeado\napp.get('/assets/*', [], handler);              // wildcard sem nome`,
        },
        { kind: "h3", text: "Grupos de rotas", id: "routing-groups" },
        {
          kind: "code",
          code: `// Fluent chain\napp.route('/users')\n  .get([], listUsers)\n  .post([auth()], createUser);\n\n// Builder callback\napp.route('/users', (r) {\n  r.get('/', [], listUsers);\n  r.post('/', [auth()], createUser);\n  r.get('/:id', [], getUser);\n});\n\n// Prefixo com group()\nfinal api = app.group('/api');\napi.get('/status', [], (c) => c.ok({'ok': true}));`,
        },
        {
          kind: "callout",
          variant: "tip",
          text: "Grupos compõem: app.group('/api').group('/v2').get('/ping', [], …) registra GET /api/v2/ping.",
        },
        {
          kind: "callout",
          variant: "success",
          text: "Matcher rápido: rotas literais (sem parâmetros ou wildcards) casam por comparação direta de string no caminho quente do dispatch — apenas rotas dinâmicas usam o matcher compilado — e o dispatch faz short-circuit pelo método HTTP primeiro. Sem configuração necessária.",
        },
        { kind: "ref", to: "context", label: "Assinatura do handler → veja Context" },
        { kind: "ref", to: "request", label: "Leitura de params / query → veja Request" },
      ],
    ),
  },
  {
    id: "context",
    group: "api",
    title: bi("Context", "Context"),
    blocks: bi(
      [
        {
          kind: "p",
          text: "The Context (c) is the single object every handler and middleware receives. It exposes per-request state, shortcuts to the incoming request and outgoing response, and metadata about the matched route.",
        },
        { kind: "h3", text: "Reading the request", id: "ctx-req" },
        {
          kind: "p",
          text: "URL, headers, params, query and body — everything inbound lives on c.req.",
        },
        { kind: "ref", to: "request", label: "Full guide: Request (c.req)" },
        { kind: "h3", text: "Writing the response", id: "ctx-res" },
        {
          kind: "p",
          text: "Status codes, JSON / text / HTML / binary helpers, redirects, file sending and Response factories — everything outbound lives on c (and Response.*).",
        },
        { kind: "ref", to: "response", label: "Full guide: Response" },
        { kind: "h3", text: "Per-request state", id: "ctx-state" },
        {
          kind: "table",
          headers: ["Member", "Description"],
          rows: [
            ["c.set('key', value)", "Store per-request state for later middleware/handlers"],
            ["c.get<T>('key')", "Read state back, typed"],
            [
              "c.user",
              "Authenticated-user shortcut (Map<String, dynamic>?) — set by auth middleware",
            ],
          ],
        },
        {
          kind: "code",
          code: `c.set('userId', '42');\nfinal id = c.get<String>('userId');\n\nc.user = {'id': '42', 'role': 'admin'};`,
        },
        { kind: "h3", text: "Route metadata", id: "ctx-meta" },
        {
          kind: "table",
          headers: ["Member", "Description"],
          rows: [
            ["c.routePath", "The matched route pattern, e.g. '/posts/:id'"],
            ["c.basePath", "The app's base path, e.g. '/api'"],
            ["c.matchedRoutes", "Every route that matched the request (middleware + handler)"],
          ],
        },
      ],
      [
        {
          kind: "p",
          text: "O Context (c) é o objeto único que todo handler e middleware recebe. Ele expõe estado por requisição, atalhos para o request de entrada e response de saída, e metadata da rota casada.",
        },
        { kind: "h3", text: "Leitura do request", id: "ctx-req" },
        {
          kind: "p",
          text: "URL, headers, params, query e body — tudo do request fica em c.req.",
        },
        { kind: "ref", to: "request", label: "Guia completo: Request (c.req)" },
        { kind: "h3", text: "Escrita do response", id: "ctx-res" },
        {
          kind: "p",
          text: "Status codes, helpers JSON / texto / HTML / binário, redirects, envio de arquivos e factories de Response — tudo do response vive em c (e em Response.*).",
        },
        { kind: "ref", to: "response", label: "Guia completo: Response" },
        { kind: "h3", text: "Estado por requisição", id: "ctx-state" },
        {
          kind: "table",
          headers: ["Membro", "Descrição"],
          rows: [
            [
              "c.set('key', value)",
              "Guarda estado por requisição para middlewares/handlers seguintes",
            ],
            ["c.get<T>('key')", "Lê o estado de volta, tipado"],
            [
              "c.user",
              "Atalho do usuário autenticado (Map<String, dynamic>?) — definido por middleware de auth",
            ],
          ],
        },
        {
          kind: "code",
          code: `c.set('userId', '42');\nfinal id = c.get<String>('userId');\n\nc.user = {'id': '42', 'role': 'admin'};`,
        },
        { kind: "h3", text: "Metadata da rota", id: "ctx-meta" },
        {
          kind: "table",
          headers: ["Membro", "Descrição"],
          rows: [
            ["c.routePath", "O padrão da rota casada, ex.: '/posts/:id'"],
            ["c.basePath", "O base path do app, ex.: '/api'"],
            ["c.matchedRoutes", "Todas as rotas que casaram a requisição (middleware + handler)"],
          ],
        },
      ],
    ),
  },
  {
    id: "request",
    group: "api",
    title: bi("Request (c.req)", "Request (c.req)"),
    blocks: bi(
      [
        {
          kind: "p",
          text: "Everything about the incoming request lives on c.req — URL, path parameters, query string, headers, body and per-request state.",
        },
        { kind: "h3", text: "URL & method", id: "req-url" },
        {
          kind: "table",
          headers: ["Member", "Description"],
          rows: [
            ["c.req.method", "HTTP method (String) — GET, POST, …"],
            ["c.req.path", "Request path without the query string, e.g. /users/42"],
            ["c.req.url", "The full request Uri (path, query and fragment)"],
            ["c.req.ip", "Remote client IP address (String)"],
          ],
        },
        { kind: "h3", text: "Path parameters", id: "req-params" },
        { kind: "p", text: "Values captured from the route pattern, e.g. /users/:id." },
        {
          kind: "table",
          headers: ["Member", "Description"],
          rows: [
            ["c.req.param('id')", "Named path param as String? (null when absent)"],
            ["c.req.paramInt('id')", "Same, parsed as int? (null if missing/not a number)"],
            ["c.req.paramDouble('id')", "Parsed as double?"],
            ["c.req.params()", "All captured values as List<String?>"],
            ["c.req.paramsMap", "All params as an unmodifiable Map<String, String>"],
          ],
        },
        { kind: "h3", text: "Query parameters", id: "req-query" },
        { kind: "p", text: "Read from the URL query string, e.g. ?page=2&active=true." },
        {
          kind: "table",
          headers: ["Member", "Description"],
          rows: [
            ["c.req.query('q')", "Query value as String?"],
            ["c.req.queryInt('page')", "Parsed as int?"],
            ["c.req.queryDouble('rate')", "Parsed as double?"],
            ["c.req.queryBool('active')", "true for 'true', '1', 'yes' or 'on' (case-insensitive)"],
            ["c.req.queries()", "All query values as List<String>"],
          ],
        },
        { kind: "h3", text: "Headers", id: "req-headers" },
        {
          kind: "table",
          headers: ["Member", "Description"],
          rows: [
            ["c.req.header('authorization')", "Header value as String? (name is case-insensitive)"],
            [
              "c.req.headers",
              "All headers as an unmodifiable Map<String, String> (multi-values joined by ', ')",
            ],
          ],
        },
        { kind: "h3", text: "Body", id: "req-body" },
        { kind: "p", text: "Read the request body once, in the shape you need." },
        {
          kind: "table",
          headers: ["Member", "Description"],
          rows: [
            ["await c.req.json()", "Parse a JSON body → Map<String, dynamic>"],
            ["await c.req.json<User>(User.fromJson)", "Parse a JSON body into a typed object"],
            ["await c.req.text()", "Body decoded as a UTF-8 String"],
            ["await c.req.blob()", "Body as raw bytes (Uint8List)"],
            ["await c.req.arrayBuffer()", "Body as a ByteBuffer"],
            [
              "await c.req.parseBody({saveDir})",
              "multipart / urlencoded → Map; files come back as UploadedFile (pass saveDir to stream them to disk)",
            ],
            ["await c.req.formData()", "Form body — Map for urlencoded, String for multipart"],
            ["c.req.body", "The raw body stream (Stream<List<int>>), consumed once"],
          ],
        },
        {
          kind: "code",
          code: `final data   = await c.req.json();\nfinal user   = await c.req.json<User>(User.fromJson);\nfinal upload = await c.req.parseBody(saveDir: 'uploads');`,
        },
        {
          kind: "callout",
          variant: "warning",
          text: "Read the body once: json(), text(), blob() and arrayBuffer() share a single cached read, but the raw body stream and multipart parseBody() consume the stream directly — don't mix the two on the same request.",
        },
        { kind: "h3", text: "Validated data & state", id: "req-state" },
        {
          kind: "table",
          headers: ["Member", "Description"],
          rows: [
            [
              "c.req.valid<T>('json')",
              "Data stored by validator() / zValidator() for a target ('json', 'query', 'param', 'form', 'header')",
            ],
            ["c.req.get('key')", "Read per-request state set earlier in the pipeline"],
            ["c.req.set('key', value)", "Store per-request state for later middleware/handlers"],
          ],
        },
        { kind: "ref", to: "file-upload", label: "Multipart bodies → see File Upload" },
      ],
      [
        {
          kind: "p",
          text: "Tudo sobre a requisição que chega vive em c.req — URL, parâmetros de rota, query string, headers, body e estado por requisição.",
        },
        { kind: "h3", text: "URL & método", id: "req-url" },
        {
          kind: "table",
          headers: ["Membro", "Descrição"],
          rows: [
            ["c.req.method", "Método HTTP (String) — GET, POST, …"],
            ["c.req.path", "Caminho da requisição sem a query string, ex.: /users/42"],
            ["c.req.url", "O Uri completo da requisição (path, query e fragment)"],
            ["c.req.ip", "Endereço IP do cliente remoto (String)"],
          ],
        },
        { kind: "h3", text: "Parâmetros de rota", id: "req-params" },
        { kind: "p", text: "Valores capturados do padrão da rota, ex.: /users/:id." },
        {
          kind: "table",
          headers: ["Membro", "Descrição"],
          rows: [
            ["c.req.param('id')", "Param de rota nomeado como String? (null se ausente)"],
            [
              "c.req.paramInt('id')",
              "O mesmo, convertido para int? (null se faltar/não for número)",
            ],
            ["c.req.paramDouble('id')", "Convertido para double?"],
            ["c.req.params()", "Todos os valores capturados como List<String?>"],
            ["c.req.paramsMap", "Todos os params como Map<String, String> imutável"],
          ],
        },
        { kind: "h3", text: "Query parameters", id: "req-query" },
        { kind: "p", text: "Lidos da query string da URL, ex.: ?page=2&active=true." },
        {
          kind: "table",
          headers: ["Membro", "Descrição"],
          rows: [
            ["c.req.query('q')", "Valor da query como String?"],
            ["c.req.queryInt('page')", "Convertido para int?"],
            ["c.req.queryDouble('rate')", "Convertido para double?"],
            [
              "c.req.queryBool('active')",
              "true para 'true', '1', 'yes' ou 'on' (case-insensitive)",
            ],
            ["c.req.queries()", "Todos os valores da query como List<String>"],
          ],
        },
        { kind: "h3", text: "Headers", id: "req-headers" },
        {
          kind: "table",
          headers: ["Membro", "Descrição"],
          rows: [
            [
              "c.req.header('authorization')",
              "Valor do header como String? (nome case-insensitive)",
            ],
            [
              "c.req.headers",
              "Todos os headers como Map<String, String> imutável (multi-valores juntados por ', ')",
            ],
          ],
        },
        { kind: "h3", text: "Body", id: "req-body" },
        { kind: "p", text: "Leia o corpo da requisição uma vez, no formato que precisar." },
        {
          kind: "table",
          headers: ["Membro", "Descrição"],
          rows: [
            ["await c.req.json()", "Parseia um body JSON → Map<String, dynamic>"],
            ["await c.req.json<User>(User.fromJson)", "Parseia um body JSON para um objeto tipado"],
            ["await c.req.text()", "Body decodificado como String UTF-8"],
            ["await c.req.blob()", "Body como bytes crus (Uint8List)"],
            ["await c.req.arrayBuffer()", "Body como ByteBuffer"],
            [
              "await c.req.parseBody({saveDir})",
              "multipart / urlencoded → Map; arquivos voltam como UploadedFile (passe saveDir para gravar em disco via stream)",
            ],
            [
              "await c.req.formData()",
              "Body de formulário — Map para urlencoded, String para multipart",
            ],
            ["c.req.body", "O stream cru do body (Stream<List<int>>), consumido uma vez"],
          ],
        },
        {
          kind: "code",
          code: `final data   = await c.req.json();\nfinal user   = await c.req.json<User>(User.fromJson);\nfinal upload = await c.req.parseBody(saveDir: 'uploads');`,
        },
        {
          kind: "callout",
          variant: "warning",
          text: "Leia o body uma vez: json(), text(), blob() e arrayBuffer() compartilham uma única leitura em cache, mas o stream cru do body e o parseBody() multipart consomem o stream diretamente — não misture os dois na mesma requisição.",
        },
        { kind: "h3", text: "Dados validados & estado", id: "req-state" },
        {
          kind: "table",
          headers: ["Membro", "Descrição"],
          rows: [
            [
              "c.req.valid<T>('json')",
              "Dados guardados por validator() / zValidator() para um target ('json', 'query', 'param', 'form', 'header')",
            ],
            ["c.req.get('key')", "Lê o estado por requisição definido antes no pipeline"],
            [
              "c.req.set('key', value)",
              "Guarda estado por requisição para middlewares/handlers seguintes",
            ],
          ],
        },
        { kind: "ref", to: "file-upload", label: "Corpos multipart → veja File Upload" },
      ],
    ),
  },
  {
    id: "response",
    group: "api",
    title: bi("Response", "Response"),
    blocks: bi(
      [
        {
          kind: "p",
          text: "Two layers for sending a response. c.* helpers cover the common cases ergonomically; Response.* factories give you full control over status, content-type and headers when you need it.",
        },
        { kind: "h3", text: "Helpers on c.*", id: "res-helpers" },
        {
          kind: "table",
          headers: ["Helper", "Description"],
          rows: [
            ["c.ok([body])", "200 OK"],
            ["c.created([body])", "201 Created"],
            ["c.noContent()", "204 No Content"],
            ["c.badRequest([body])", "400 Bad Request"],
            ["c.unauthorized([body])", "401 Unauthorized"],
            ["c.forbidden([body])", "403 Forbidden"],
            ["c.notFound([body])", "404 Not Found"],
            ["c.conflict([body])", "409 Conflict"],
            ["c.internalError([body])", "500 Internal Server Error"],
            ["c.json(data, [status])", "JSON response (application/json)"],
            ["c.text(str, [status])", "Plain text (text/plain)"],
            ["c.html(str, [status])", "HTML (text/html)"],
            ["c.status(code)", "Set the status, then chain .json() / .text() / .html()"],
            ["c.redirect(url, [status])", "Redirect (302 by default)"],
            ["c.binary(bytes, {status, contentType})", "Binary response"],
            ["c.body(data, [status], [headers])", "HonoJS-style raw body — text / bytes / null"],
          ],
        },
        {
          kind: "code",
          code: `app.get('/users/:id', [], (c) {\n  final user = users[c.req.param('id')];\n  return user == null ? c.notFound({'error': 'not found'}) : c.ok(user);\n});`,
        },
        { kind: "h3", text: "Response headers", id: "res-headers" },
        {
          kind: "table",
          headers: ["Member", "Description"],
          rows: [
            ["c.header(name, value)", "Set a response header"],
            ["c.statusCode", "Current response status code (int)"],
          ],
        },
        { kind: "h3", text: "Response factories", id: "res-factories" },
        {
          kind: "p",
          text: "Build a Response directly when you need full control over status, content-type and headers — the c.* helpers above call these internally.",
        },
        {
          kind: "table",
          headers: ["Factory", "Description"],
          rows: [
            [
              "Response.json(data, {status, headers})",
              "JSON response (application/json); encodes Maps/Lists and converts DateTime to ISO-8601",
            ],
            ["Response.text(str, {status, headers})", "Plain text (text/plain; charset=utf-8)"],
            ["Response.html(str, {status, headers})", "HTML (text/html; charset=utf-8)"],
            [
              "Response.bytes(bytes, {status, contentType, headers})",
              "Binary body with a custom content-type (default application/octet-stream)",
            ],
            ["Response.empty({status})", "No body (defaults to 204 No Content)"],
          ],
        },
        {
          kind: "code",
          code: `app.get('/raw', [], (c) => Response.json({'ok': true}, status: 201));`,
        },
        { kind: "h3", text: "Sending files", id: "res-files" },
        {
          kind: "table",
          headers: ["Helper", "Description"],
          rows: [
            [
              "await c.file(path, {contentType})",
              "Stream a file — sets Content-Length automatically",
            ],
            ["await c.download(path, {filename})", "Force download via Content-Disposition"],
          ],
        },
        { kind: "ref", to: "file-download", label: "Full guide: File Download" },
      ],
      [
        {
          kind: "p",
          text: "Duas camadas para enviar uma resposta. Os helpers em c.* cobrem os casos comuns com ergonomia; as factories em Response.* dão controle total sobre status, content-type e headers quando você precisa.",
        },
        { kind: "h3", text: "Helpers em c.*", id: "res-helpers" },
        {
          kind: "table",
          headers: ["Helper", "Descrição"],
          rows: [
            ["c.ok([body])", "200 OK"],
            ["c.created([body])", "201 Created"],
            ["c.noContent()", "204 No Content"],
            ["c.badRequest([body])", "400 Bad Request"],
            ["c.unauthorized([body])", "401 Unauthorized"],
            ["c.forbidden([body])", "403 Forbidden"],
            ["c.notFound([body])", "404 Not Found"],
            ["c.conflict([body])", "409 Conflict"],
            ["c.internalError([body])", "500 Internal Server Error"],
            ["c.json(data, [status])", "Resposta JSON (application/json)"],
            ["c.text(str, [status])", "Texto puro (text/plain)"],
            ["c.html(str, [status])", "HTML (text/html)"],
            ["c.status(code)", "Define o status e encadeia .json() / .text() / .html()"],
            ["c.redirect(url, [status])", "Redireciona (302 por padrão)"],
            ["c.binary(bytes, {status, contentType})", "Resposta binária"],
            ["c.body(data, [status], [headers])", "Body cru estilo HonoJS — texto / bytes / null"],
          ],
        },
        {
          kind: "code",
          code: `app.get('/users/:id', [], (c) {\n  final user = users[c.req.param('id')];\n  return user == null ? c.notFound({'error': 'not found'}) : c.ok(user);\n});`,
        },
        { kind: "h3", text: "Headers da resposta", id: "res-headers" },
        {
          kind: "table",
          headers: ["Membro", "Descrição"],
          rows: [
            ["c.header(name, value)", "Define um header de resposta"],
            ["c.statusCode", "Status code atual da resposta (int)"],
          ],
        },
        { kind: "h3", text: "Factories de Response", id: "res-factories" },
        {
          kind: "p",
          text: "Construa um Response diretamente quando precisar de controle total sobre status, content-type e headers — os helpers c.* acima usam essas factories internamente.",
        },
        {
          kind: "table",
          headers: ["Factory", "Descrição"],
          rows: [
            [
              "Response.json(data, {status, headers})",
              "Resposta JSON (application/json); codifica Maps/Lists e converte DateTime para ISO-8601",
            ],
            ["Response.text(str, {status, headers})", "Texto puro (text/plain; charset=utf-8)"],
            ["Response.html(str, {status, headers})", "HTML (text/html; charset=utf-8)"],
            [
              "Response.bytes(bytes, {status, contentType, headers})",
              "Body binário com content-type custom (padrão application/octet-stream)",
            ],
            ["Response.empty({status})", "Sem body (padrão 204 No Content)"],
          ],
        },
        {
          kind: "code",
          code: `app.get('/raw', [], (c) => Response.json({'ok': true}, status: 201));`,
        },
        { kind: "h3", text: "Envio de arquivos", id: "res-files" },
        {
          kind: "table",
          headers: ["Helper", "Descrição"],
          rows: [
            [
              "await c.file(path, {contentType})",
              "Envia um arquivo em stream — define Content-Length automaticamente",
            ],
            ["await c.download(path, {filename})", "Força download via Content-Disposition"],
          ],
        },
        { kind: "ref", to: "file-download", label: "Guia completo: File Download" },
      ],
    ),
  },
  {
    id: "middleware",
    group: "middlewares",
    title: bi("Middleware", "Middleware"),
    blocks: bi(
      [
        { kind: "h3", text: "Registering", id: "mw-register" },
        {
          kind: "p",
          text: "use(middleware) registers a global middleware that runs on every request. mount(path, middleware) registers a path-scoped middleware — it only runs when the request path starts with path (supports * wildcards).",
        },
        {
          kind: "code",
          code: `app.use(logger());               // global — runs on every request\napp.use(cors());                 // call separately per middleware\napp.mount('/api/*', jwt(...));   // path-scoped\napp.get('/admin', [requireAdmin()], handler); // route-level`,
        },
        { kind: "h3", text: "Writing one", id: "mw-write" },
        {
          kind: "code",
          code: `Middleware timer() => (Context c, Next next) async {\n  final sw = Stopwatch()..start();\n  await next();\n  print('\${c.req.method} \${c.req.path}  \${sw.elapsedMilliseconds}ms');\n};`,
        },
        { kind: "h3", text: "Short-circuit", id: "mw-short" },
        {
          kind: "code",
          code: `Middleware requireAdmin() => (c, next) async {\n  if (c.user?['role'] != 'admin') {\n    c.forbidden({'error': 'Admins only'});\n    return; // pipeline stops here\n  }\n  await next();\n};`,
        },
      ],
      [
        { kind: "h3", text: "Registrando", id: "mw-register" },
        {
          kind: "p",
          text: "use(middleware) registra um middleware global que roda em toda request. mount(path, middleware) registra um middleware por caminho — só roda quando o path da request começa com path (suporta wildcards *).",
        },
        {
          kind: "code",
          code: `app.use(logger());               // global — roda em toda request\napp.use(cors());                 // chame separadamente por middleware\napp.mount('/api/*', jwt(...));   // por caminho\napp.get('/admin', [requireAdmin()], handler); // por rota`,
        },
        { kind: "h3", text: "Criando um", id: "mw-write" },
        {
          kind: "code",
          code: `Middleware timer() => (Context c, Next next) async {\n  final sw = Stopwatch()..start();\n  await next();\n  print('\${c.req.method} \${c.req.path}  \${sw.elapsedMilliseconds}ms');\n};`,
        },
        { kind: "h3", text: "Short-circuit", id: "mw-short" },
        {
          kind: "code",
          code: `Middleware requireAdmin() => (c, next) async {\n  if (c.user?['role'] != 'admin') {\n    c.forbidden({'error': 'Somente admins'});\n    return; // pipeline para aqui\n  }\n  await next();\n};`,
        },
      ],
    ),
  },
  {
    id: "middleware-builtin",
    group: "middlewares",
    title: bi("Built-in Middlewares", "Middlewares embutidos"),
    blocks: bi(
      [
        {
          kind: "p",
          text: "Darto ships with batteries: logger, CORS, JWT, Basic & Bearer auth, cache, compress, CSRF, body-limit, rate-limit, request ID, ETag, RBAC and more.",
        },
        {
          kind: "code",
          code: `import 'package:darto/logger.dart';\nimport 'package:darto/cors.dart';\nimport 'package:darto/jwt.dart';\nimport 'package:darto/basic_auth.dart';\nimport 'package:darto/bearer_auth.dart';\nimport 'package:darto/cache.dart';\n\napp.use(logger());\napp.mount('/api/*', cors(origin: 'https://example.com'));\napp.mount('/api/*', jwt(secret: env.jwtSecret));\napp.mount('/admin/*', basicAuth(username: 'admin', password: 'secret'));\napp.mount('/api/*', bearerAuth(token: ['key1', 'key2']));`,
        },
        { kind: "h3", text: "RBAC", id: "mw-rbac" },
        {
          kind: "code",
          code: `import 'package:darto/require_roles.dart';\napp.delete('/users/:id', [requireRoles(['admin'])], handler);`,
        },
        { kind: "h3", text: "Body limit", id: "mw-bodylimit" },
        {
          kind: "code",
          code: `app.post('/upload', [bodyLimit(maxSize: 5 * 1024 * 1024)], handler);`,
        },
        { kind: "h3", text: "Rate limit", id: "mw-ratelimit" },
        {
          kind: "code",
          code: `import 'package:darto/rate_limit.dart';\n\n// 100 requests / minute per client IP (in-memory, zero-dep)\napp.use(rateLimit(max: 100, window: Duration(minutes: 1)));\n\n// Per-user, custom rejection — pass a RateLimitStore for a distributed backend\napp.mount('/api/*', rateLimit(\n  max: 20,\n  keyGenerator: (c) => c.user?['id'] ?? c.req.ip,\n  onLimitExceeded: (c) => c.status(429).json({'error': 'slow down'}),\n));`,
        },
        { kind: "h3", text: "Request ID", id: "mw-requestid" },
        {
          kind: "code",
          code: `import 'package:darto/request_id.dart';\n\napp.use(requestId()); // honors an incoming X-Request-Id, else a UUID v4\napp.get('/', [], (c) => c.ok({'id': requestIdOf(c)}));`,
        },
        { kind: "h3", text: "ETag", id: "mw-etag" },
        {
          kind: "code",
          code: `import 'package:darto/etag.dart';\n\napp.use(etag()); // hashes dynamic responses → ETag + 304 on If-None-Match`,
        },
        { kind: "h3", text: "Health check", id: "mw-health" },
        {
          kind: "p",
          text: "health() is a handler factory (package:darto/health.dart). Returns 200 when every named check passes, or 503 with the failing checks.",
        },
        {
          kind: "code",
          code: `import 'package:darto/health.dart';\n\napp.get('/healthz', [], health());\napp.get('/readyz', [], health(\n  checks: {'db': () => db.ping(), 'cache': () => redis.ping()},\n  info: () => {'version': '1.2.0'},\n));`,
        },
        {
          kind: "callout",
          variant: "warning",
          text: "When using jwt, always set verifyOptions (iss, exp, nbf) for production deployments.",
        },
      ],
      [
        {
          kind: "p",
          text: "O Darto vem com baterias: logger, CORS, JWT, Basic & Bearer auth, cache, compress, CSRF, body-limit, rate-limit, request ID, ETag, RBAC e mais.",
        },
        {
          kind: "code",
          code: `import 'package:darto/logger.dart';\nimport 'package:darto/cors.dart';\nimport 'package:darto/jwt.dart';\nimport 'package:darto/basic_auth.dart';\nimport 'package:darto/bearer_auth.dart';\nimport 'package:darto/cache.dart';\n\napp.use(logger());\napp.mount('/api/*', cors(origin: 'https://example.com'));\napp.mount('/api/*', jwt(secret: env.jwtSecret));\napp.mount('/admin/*', basicAuth(username: 'admin', password: 'secret'));\napp.mount('/api/*', bearerAuth(token: ['key1', 'key2']));`,
        },
        { kind: "h3", text: "RBAC", id: "mw-rbac" },
        {
          kind: "code",
          code: `import 'package:darto/require_roles.dart';\napp.delete('/users/:id', [requireRoles(['admin'])], handler);`,
        },
        { kind: "h3", text: "Limite de body", id: "mw-bodylimit" },
        {
          kind: "code",
          code: `app.post('/upload', [bodyLimit(maxSize: 5 * 1024 * 1024)], handler);`,
        },
        { kind: "h3", text: "Rate limit", id: "mw-ratelimit" },
        {
          kind: "code",
          code: `import 'package:darto/rate_limit.dart';\n\n// 100 requisições / minuto por IP do cliente (in-memory, zero-dep)\napp.use(rateLimit(max: 100, window: Duration(minutes: 1)));\n\n// Por usuário, rejeição custom — passe um RateLimitStore p/ backend distribuído\napp.mount('/api/*', rateLimit(\n  max: 20,\n  keyGenerator: (c) => c.user?['id'] ?? c.req.ip,\n  onLimitExceeded: (c) => c.status(429).json({'error': 'devagar'}),\n));`,
        },
        { kind: "h3", text: "Request ID", id: "mw-requestid" },
        {
          kind: "code",
          code: `import 'package:darto/request_id.dart';\n\napp.use(requestId()); // respeita X-Request-Id recebido, senão gera um UUID v4\napp.get('/', [], (c) => c.ok({'id': requestIdOf(c)}));`,
        },
        { kind: "h3", text: "ETag", id: "mw-etag" },
        {
          kind: "code",
          code: `import 'package:darto/etag.dart';\n\napp.use(etag()); // gera hash de respostas dinâmicas → ETag + 304 no If-None-Match`,
        },
        { kind: "h3", text: "Health check", id: "mw-health" },
        {
          kind: "p",
          text: "health() é uma factory de handler (package:darto/health.dart). Retorna 200 quando todos os checks passam, ou 503 com os que falharam.",
        },
        {
          kind: "code",
          code: `import 'package:darto/health.dart';\n\napp.get('/healthz', [], health());\napp.get('/readyz', [], health(\n  checks: {'db': () => db.ping(), 'cache': () => redis.ping()},\n  info: () => {'version': '1.2.0'},\n));`,
        },
        {
          kind: "callout",
          variant: "warning",
          text: "Ao usar jwt, sempre configure verifyOptions (iss, exp, nbf) em produção.",
        },
      ],
    ),
  },
  {
    id: "session",
    group: "middlewares",
    title: bi("Session", "Sessão"),
    blocks: bi(
      [
        {
          kind: "p",
          text: "Cookie-based signed sessions. Data is JSON-serialised, base64url-encoded, and signed with HMAC-SHA256 — tamper-proof but not encrypted. Store only non-sensitive identifiers (e.g. userId) in the session.",
        },
        {
          kind: "code",
          code: `import 'package:darto/session.dart';\n\n// Register once globally — reads and validates the session cookie on every request\napp.use(sessionMiddleware(\n  secret: 'at-least-32-chars-long-secret!!',\n  duration: 60 * 30,           // cookie maxAge in seconds (default: 1800)\n  cookieName: 'darto.session', // optional, this is the default\n));`,
        },
        { kind: "h3", text: "Write / Read / Delete", id: "session-api" },
        {
          kind: "code",
          code: `app.post('/login', [], (c) async {\n  final body = await c.req.json();\n  await sessionContext(c).update({'userId': body['id'], 'role': 'user'});\n  return c.ok({'message': 'logged in'});\n});\n\napp.get('/me', [], (c) {\n  final data = sessionContext(c).get(); // null if no active session\n  if (data == null) return c.unauthorized({'error': 'no session'});\n  return c.ok(data);\n});\n\napp.post('/logout', [], (c) {\n  sessionContext(c).delete();\n  return c.ok({'message': 'logged out'});\n});`,
        },
        {
          kind: "table",
          headers: ["Method", "Returns", "Description"],
          rows: [
            [
              "sessionContext(c).get()",
              "Map<String, dynamic>?",
              "Session data — null if no valid session",
            ],
            [
              "sessionContext(c).update(data)",
              "Future<void>",
              "Replace data and write the signed cookie",
            ],
            ["sessionContext(c).delete()", "void", "Clear data and remove the cookie"],
          ],
        },
        {
          kind: "callout",
          variant: "warning",
          text: "Session data is visible (base64-decoded) but not alterable — the HMAC signature prevents tampering. Do not store passwords or secrets inside the session.",
        },
      ],
      [
        {
          kind: "p",
          text: "Sessões baseadas em cookie assinado. Os dados são serializados em JSON, codificados em base64url e assinados com HMAC-SHA256 — à prova de adulteração, mas não criptografados. Armazene apenas identificadores não sensíveis (ex.: userId) na sessão.",
        },
        {
          kind: "code",
          code: `import 'package:darto/session.dart';\n\n// Registre uma vez globalmente — lê e valida o cookie de sessão em toda request\napp.use(sessionMiddleware(\n  secret: 'chave-com-pelo-menos-32-caracteres!!',\n  duration: 60 * 30,           // maxAge do cookie em segundos (padrão: 1800)\n  cookieName: 'darto.session', // opcional, este é o padrão\n));`,
        },
        { kind: "h3", text: "Gravar / Ler / Apagar", id: "session-api" },
        {
          kind: "code",
          code: `app.post('/login', [], (c) async {\n  final body = await c.req.json();\n  await sessionContext(c).update({'userId': body['id'], 'role': 'user'});\n  return c.ok({'message': 'logado'});\n});\n\napp.get('/me', [], (c) {\n  final data = sessionContext(c).get(); // null se não houver sessão ativa\n  if (data == null) return c.unauthorized({'error': 'sem sessão'});\n  return c.ok(data);\n});\n\napp.post('/logout', [], (c) {\n  sessionContext(c).delete();\n  return c.ok({'message': 'deslogado'});\n});`,
        },
        {
          kind: "table",
          headers: ["Método", "Retorna", "Descrição"],
          rows: [
            [
              "sessionContext(c).get()",
              "Map<String, dynamic>?",
              "Dados da sessão — null se não houver sessão válida",
            ],
            [
              "sessionContext(c).update(data)",
              "Future<void>",
              "Substitui os dados e escreve o cookie assinado",
            ],
            ["sessionContext(c).delete()", "void", "Limpa os dados e remove o cookie"],
          ],
        },
        {
          kind: "callout",
          variant: "warning",
          text: "Os dados da sessão são visíveis (decodificáveis via base64) mas não alteráveis — a assinatura HMAC impede adulteração. Não armazene senhas ou segredos dentro da sessão.",
        },
      ],
    ),
  },
  {
    id: "validator",
    group: "middlewares",
    title: bi("Validator (core)", "Validator (core)"),
    blocks: bi(
      [
        {
          kind: "p",
          text: "validator is the core validation middleware (from package:darto/validator.dart) — no extra package needed. You pass a callback that receives the raw value and the Context: return a Response to short-circuit with any status code, or return data to store it for c.req.valid().",
        },
        { kind: "h3", text: "Bring your own logic", id: "val-validator" },
        {
          kind: "p",
          text: "To validate with zard schemas, just add the zard package — you do NOT need darto_validator (that one is only for zValidator). See the zValidator section under Plugins for the schema-driven alternative.",
        },
        {
          kind: "code",
          code: `import 'package:darto/validator.dart';\nimport 'package:zard/zard.dart'; // add zard to pubspec — for z.*\n\nfinal loginSchema = z.map({\n  'email':    z.string().email(),\n  'password': z.string().min(6),\n});\n\n// 401 on failure — you decide the status code\napp.post('/login', [\n  validator('json', (value, c) {\n    final result = loginSchema.safeParse(value);\n    if (!result.success) return c.status(401).json({'errors': result.error?.format()});\n    return result.data;\n  }),\n], (c) {\n  final credentials = c.req.valid<Map<String, dynamic>>('json');\n  return c.ok({'message': 'Welcome, \${credentials[\\'email\\']}!'});\n});`,
        },
        { kind: "h3", text: "Targets", id: "val-targets" },
        {
          kind: "ul",
          items: [
            "'json' — request body",
            "'query' — query string",
            "'param' — path parameters",
            "'form' — url-encoded / multipart",
            "'header' — request headers",
          ],
        },
        {
          kind: "callout",
          variant: "warning",
          text: "Always validate untrusted input at the edges — bodies, queries, headers and uploaded files.",
        },
        {
          kind: "ref",
          to: "plugin-validator",
          label: "Schema-driven alternative: zValidator (darto_validator)",
        },
      ],
      [
        {
          kind: "p",
          text: "validator é o middleware de validação do core (de package:darto/validator.dart) — sem pacote extra. Você passa um callback que recebe o valor bruto e o Context: retorne uma Response para encerrar com qualquer status, ou retorne os dados para guardá-los em c.req.valid().",
        },
        { kind: "h3", text: "Traga sua própria lógica", id: "val-validator" },
        {
          kind: "p",
          text: "Para validar com schemas zard, basta adicionar o pacote zard — você NÃO precisa do darto_validator (esse é só para o zValidator). Veja a seção do zValidator em Plugins para a alternativa baseada em schema.",
        },
        {
          kind: "code",
          code: `import 'package:darto/validator.dart';\nimport 'package:zard/zard.dart'; // adicione zard ao pubspec — para z.*\n\nfinal loginSchema = z.map({\n  'email':    z.string().email(),\n  'password': z.string().min(6),\n});\n\n// 401 em caso de falha — você decide o status\napp.post('/login', [\n  validator('json', (value, c) {\n    final result = loginSchema.safeParse(value);\n    if (!result.success) return c.status(401).json({'errors': result.error?.format()});\n    return result.data;\n  }),\n], (c) {\n  final credentials = c.req.valid<Map<String, dynamic>>('json');\n  return c.ok({'message': 'Bem-vindo, \${credentials[\\'email\\']}!'});\n});`,
        },
        { kind: "h3", text: "Targets", id: "val-targets" },
        {
          kind: "ul",
          items: [
            "'json' — body da request",
            "'query' — query string",
            "'param' — parâmetros de path",
            "'form' — url-encoded / multipart",
            "'header' — headers da request",
          ],
        },
        {
          kind: "callout",
          variant: "warning",
          text: "Sempre valide input não confiável nas bordas — bodies, queries, headers e arquivos enviados.",
        },
        {
          kind: "ref",
          to: "plugin-validator",
          label: "Alternativa baseada em schema: zValidator (darto_validator)",
        },
      ],
    ),
  },
  {
    id: "render-layouts",
    group: "advanced",
    title: bi("Render / Layouts", "Render / Layouts"),
    blocks: bi(
      [
        { kind: "p", text: "Two-step rendering modelled after Hono's setRenderer / c.render." },
        {
          kind: "code",
          code: `app.use((Context c, Next next) async {\n  c.setRender((content, props) => c.html('''\n    <!DOCTYPE html>\n    <html><head><title>\${props['title'] ?? 'Darto'}</title></head>\n    <body>\$content</body></html>\n  '''));\n  await next();\n});\n\napp.get('/', [], (c) => c.render('<h1>Welcome</h1>', {'title': 'Home'}));`,
        },
        {
          kind: "callout",
          variant: "tip",
          text: "Register a different layout via app.mount('/admin/*', …) to override for a path scope.",
        },
      ],
      [
        {
          kind: "p",
          text: "Renderização em duas etapas, inspirada no setRenderer / c.render do Hono.",
        },
        {
          kind: "code",
          code: `app.use((Context c, Next next) async {\n  c.setRender((content, props) => c.html('''\n    <!DOCTYPE html>\n    <html><head><title>\${props['title'] ?? 'Darto'}</title></head>\n    <body>\$content</body></html>\n  '''));\n  await next();\n});\n\napp.get('/', [], (c) => c.render('<h1>Bem-vindo</h1>', {'title': 'Home'}));`,
        },
        {
          kind: "callout",
          variant: "tip",
          text: "Registre um layout diferente via app.mount('/admin/*', …) para sobrescrever em um escopo.",
        },
      ],
    ),
  },
  {
    id: "view-engine",
    group: "advanced",
    title: bi("View Engine", "View Engine"),
    blocks: bi(
      [
        { kind: "ref", to: "plugin-view", label: "Package: darto_view" },
        {
          kind: "p",
          text: "For file-based templates (Mustache, Jinja…) use the darto_view package. Register an engine once via middleware, then call c.render() in any handler.",
        },
        {
          kind: "code",
          code: `import 'package:darto/darto.dart';\nimport 'package:darto_view/darto_view.dart';\n\nfinal app = Darto();\napp.use(viewEngine(MustacheEngine(viewsPath: 'views')));\n\napp.get('/', [], (c) => c.render('index', {\n  'title': 'Home',\n  'items': ['Routing', 'Middleware', 'Validation'],\n}));`,
        },
        { kind: "h3", text: "Template file", id: "view-template" },
        {
          kind: "p",
          text: "Templates live in the viewsPath directory (here views/) with a .mustache extension. c.render('index', data) renders views/index.mustache with data.",
        },
        {
          kind: "code",
          lang: "html",
          filename: "views/index.mustache",
          code: `<!DOCTYPE html>\n<html>\n  <head><title>{{title}}</title></head>\n  <body>\n    <h1>{{title}}</h1>\n    <ul>\n      {{#items}}<li>{{.}}</li>{{/items}}\n    </ul>\n  </body>\n</html>`,
        },
      ],
      [
        { kind: "ref", to: "plugin-view", label: "Pacote: darto_view" },
        {
          kind: "p",
          text: "Para templates em arquivos (Mustache, Jinja…) use o pacote darto_view. Registre o engine via middleware uma vez e use c.render() em qualquer handler.",
        },
        {
          kind: "code",
          code: `import 'package:darto/darto.dart';\nimport 'package:darto_view/darto_view.dart';\n\nfinal app = Darto();\napp.use(viewEngine(MustacheEngine(viewsPath: 'views')));\n\napp.get('/', [], (c) => c.render('index', {\n  'title': 'Home',\n  'items': ['Roteamento', 'Middleware', 'Validação'],\n}));`,
        },
        { kind: "h3", text: "Arquivo de template", id: "view-template" },
        {
          kind: "p",
          text: "Os templates ficam no diretório viewsPath (aqui views/) com extensão .mustache. c.render('index', data) renderiza views/index.mustache com os dados.",
        },
        {
          kind: "code",
          lang: "html",
          filename: "views/index.mustache",
          code: `<!DOCTYPE html>\n<html>\n  <head><title>{{title}}</title></head>\n  <body>\n    <h1>{{title}}</h1>\n    <ul>\n      {{#items}}<li>{{.}}</li>{{/items}}\n    </ul>\n  </body>\n</html>`,
        },
      ],
    ),
  },
  {
    id: "file-upload",
    group: "advanced",
    title: bi("File Upload", "Upload de arquivo"),
    blocks: bi(
      [
        { kind: "h3", text: "In-memory", id: "fu-memory" },
        {
          kind: "code",
          code: `app.post('/upload', [], (c) async {\n  final form = await c.req.formData();\n  final file = (form as Map)['avatar'] as UploadedFile;\n  print(file.filename); // logo.png\n  print(file.size);     // bytes\n  return c.created({'name': file.filename});\n});`,
        },
        { kind: "h3", text: "Streamed to disk", id: "fu-stream" },
        {
          kind: "code",
          code: `app.post('/upload', [], (c) async {\n  final form = await c.req.formData();\n  final file = (form as Map)['video'] as UploadedFile;\n  await file.saveTo('uploads/\${file.filename}');\n  return c.created({'ok': true});\n});`,
        },
        {
          kind: "callout",
          variant: "tip",
          text: "Prefer saveTo for files larger than a few MB — it streams instead of buffering the entire body.",
        },
      ],
      [
        { kind: "h3", text: "Em memória", id: "fu-memory" },
        {
          kind: "code",
          code: `app.post('/upload', [], (c) async {\n  final form = await c.req.formData();\n  final file = (form as Map)['avatar'] as UploadedFile;\n  print(file.filename);\n  print(file.size);\n  return c.created({'name': file.filename});\n});`,
        },
        { kind: "h3", text: "Streamed para disco", id: "fu-stream" },
        {
          kind: "code",
          code: `app.post('/upload', [], (c) async {\n  final form = await c.req.formData();\n  final file = (form as Map)['video'] as UploadedFile;\n  await file.saveTo('uploads/\${file.filename}');\n  return c.created({'ok': true});\n});`,
        },
        {
          kind: "callout",
          variant: "tip",
          text: "Use saveTo para arquivos maiores que alguns MB — ele faz stream em vez de bufferizar tudo.",
        },
      ],
    ),
  },
  {
    id: "file-download",
    group: "advanced",
    title: bi("File Download", "Download de arquivo"),
    blocks: bi(
      [
        {
          kind: "code",
          code: `// Inline (browser tries to render it)\nawait c.file('/path/to/report.pdf');\n\n// Force download with Content-Disposition\nawait c.download('/path/to/report.csv', filename: 'export.csv');`,
        },
      ],
      [
        {
          kind: "code",
          code: `// Inline (browser tenta renderizar)\nawait c.file('/path/to/report.pdf');\n\n// Forçar download com Content-Disposition\nawait c.download('/path/to/report.csv', filename: 'export.csv');`,
        },
      ],
    ),
  },
  {
    id: "websocket",
    group: "advanced",
    title: bi("WebSocket", "WebSocket"),
    blocks: bi(
      [
        { kind: "ref", to: "plugin-ws", label: "Package: darto_ws" },
        {
          kind: "p",
          text: "Use the darto_ws package to upgrade any route to a WebSocket — same port, same middleware pipeline as HTTP routes. Add it to your pubspec: darto_ws: ^1.1.0.",
        },
        {
          kind: "code",
          code: `import 'package:darto/darto.dart';\nimport 'package:darto_ws/darto_ws.dart';\n\napp.get('/chat', [], upgradeWebSocket((c) => WSHandler(\n  onOpen:    (ws) => ws.send('hello'),\n  onMessage: (event, ws) => ws.send('echo: \${event.text}'),\n  onClose:   (ws) => print('\${ws.id} disconnected'),\n)));`,
        },
        { kind: "h3", text: "Path params and state", id: "ws-state" },
        {
          kind: "code",
          code: `// Middleware runs before the upgrade — path params and state are available inside WSHandler\napp.get('/rooms/:id', [bearerAuth(token: env.token)], upgradeWebSocket((c) {\n  final room = c.req.param('id');\n  return WSHandler(\n    onOpen: (ws) => ws.send('joined room \$room'),\n    onMessage: (event, ws) => ws.sendJson({'echo': event.json}),\n  );\n}));`,
        },
        {
          kind: "callout",
          variant: "success",
          text: "Middleware (auth, logging) runs before the upgrade — protect WS endpoints just like HTTP routes.",
        },
        { kind: "h3", text: "Rooms and broadcast — WsHub", id: "ws-hub" },
        {
          kind: "p",
          text: "A WsHub is the connection registry — group sockets in rooms and fan messages out. Install one per app via middleware so every upgradeWebSocket factory picks it up automatically.",
        },
        {
          kind: "code",
          code: `final hub = WsHub();\nfinal app = Darto()..use(hub.middleware());\n\napp.get('/chat/:room', [], upgradeWebSocket((c) {\n  final room = c.req.param('room')!;\n  return WSHandler(\n    onOpen: (ws) {\n      ws.join(room);\n      ws.to(room).except(ws).send('\${ws.id} joined');\n    },\n    onMessage: (ev, ws) =>\n      ws.to(room).sendJson({'from': ws.id, 'text': ev.text}),\n    onClose: (ws) { /* ws.leave(room) is automatic */ },\n  );\n}));\n\n// Server-initiated broadcast — works from any HTTP route or cron\napp.post('/announce', [], (c) async {\n  hub.to('lobby').send('shutdown soon');\n  return c.noContent();\n});`,
        },
        {
          kind: "table",
          headers: ["Symbol", "Description"],
          rows: [
            ["hub.middleware()", "Exposes the hub to factories via wsHub(c)"],
            [
              "hub.to(room) / hub.broadcast()",
              "Fluent fanout — chain .except(ws), then send / sendJson / sendBytes",
            ],
            ["hub.connections / roomSize / rooms", "Membership stats"],
            ["ws.id / ws.rooms", "Per-connection UUID + rooms it is in"],
            ["ws.join(room) / ws.leave(room)", "Mutate membership (auto-leave on close)"],
            ["ws.to(room) / ws.broadcast()", "Shortcuts to hub.to / hub.broadcast"],
          ],
        },
        { kind: "h3", text: "Multi-instance fanout — RedisWsAdapter", id: "ws-redis" },
        {
          kind: "p",
          text: "When two replicas behind a load balancer hold sockets in the same room, attach the Redis adapter so broadcasts cross instances. Origin-id tagging suppresses self-echo.",
        },
        {
          kind: "code",
          code: `final hub = WsHub();\nawait hub.attachAdapter(await RedisWsAdapter.connect(\n  host: 'localhost',\n  port: 6379,\n));\n\nfinal app = Darto()..use(hub.middleware());`,
        },
        { kind: "h3", text: "WSHandler & DartoWebSocket", id: "ws-api" },
        {
          kind: "table",
          headers: ["WSHandler callback", "Description"],
          rows: [
            ["onOpen: (ws)", "Connection established"],
            ["onMessage: (event, ws)", "A frame arrived — read event.text or event.json"],
            ["onClose: (ws)", "Connection closed — read ws.id / ws.rooms here"],
            ["onError: (err, ws)", "An error occurred"],
          ],
        },
        {
          kind: "callout",
          variant: "warning",
          text: "Breaking in 1.1.0: onClose and onError now receive the closing socket — old `onClose: () => …` becomes `onClose: (_) => …`.",
        },
        {
          kind: "table",
          headers: ["ws / event member", "Description"],
          rows: [
            ["ws.send(text)", "Send a text frame to this client"],
            ["ws.sendJson(map)", "Encode a Map as JSON and send it"],
            ["ws.sendBytes(bytes)", "Send a binary frame"],
            ["ws.close([code, reason])", "Close the connection"],
            ["ws.closeCode", "Peer close code (null while open)"],
            ["ws.id", "Unique per-connection UUID v4"],
            ["ws.rooms / join / leave / to / broadcast", "Hub helpers (require hub.middleware())"],
            ["event.text", "Frame data as a String"],
            ["event.json", "Frame data parsed as a JSON Map"],
          ],
        },
      ],
      [
        { kind: "ref", to: "plugin-ws", label: "Pacote: darto_ws" },
        {
          kind: "p",
          text: "Use o pacote darto_ws para fazer upgrade de qualquer rota para WebSocket — mesma porta, mesmo pipeline de middleware das rotas HTTP. Adicione ao pubspec: darto_ws: ^1.1.0.",
        },
        {
          kind: "code",
          code: `import 'package:darto/darto.dart';\nimport 'package:darto_ws/darto_ws.dart';\n\napp.get('/chat', [], upgradeWebSocket((c) => WSHandler(\n  onOpen:    (ws) => ws.send('hello'),\n  onMessage: (event, ws) => ws.send('echo: \${event.text}'),\n  onClose:   (ws) => print('\${ws.id} desconectou'),\n)));`,
        },
        { kind: "h3", text: "Params e estado", id: "ws-state" },
        {
          kind: "code",
          code: `// Middleware roda antes do upgrade — params e estado disponíveis no WSHandler\napp.get('/rooms/:id', [bearerAuth(token: env.token)], upgradeWebSocket((c) {\n  final room = c.req.param('id');\n  return WSHandler(\n    onOpen: (ws) => ws.send('entrou na sala \$room'),\n    onMessage: (event, ws) => ws.sendJson({'echo': event.json}),\n  );\n}));`,
        },
        {
          kind: "callout",
          variant: "success",
          text: "Middlewares (auth, log) rodam antes do upgrade — proteja endpoints WS como rotas HTTP.",
        },
        { kind: "h3", text: "Rooms e broadcast — WsHub", id: "ws-hub" },
        {
          kind: "p",
          text: "Um WsHub é o registry de conexões — agrupa sockets em rooms e faz fanout de mensagens. Instale um por app via middleware para que toda factory de upgradeWebSocket o pegue automaticamente.",
        },
        {
          kind: "code",
          code: `final hub = WsHub();\nfinal app = Darto()..use(hub.middleware());\n\napp.get('/chat/:room', [], upgradeWebSocket((c) {\n  final room = c.req.param('room')!;\n  return WSHandler(\n    onOpen: (ws) {\n      ws.join(room);\n      ws.to(room).except(ws).send('\${ws.id} entrou');\n    },\n    onMessage: (ev, ws) =>\n      ws.to(room).sendJson({'from': ws.id, 'text': ev.text}),\n    onClose: (ws) { /* ws.leave(room) é automático */ },\n  );\n}));\n\n// Broadcast iniciado pelo servidor — funciona de qualquer rota HTTP ou cron\napp.post('/announce', [], (c) async {\n  hub.to('lobby').send('shutdown em breve');\n  return c.noContent();\n});`,
        },
        {
          kind: "table",
          headers: ["Símbolo", "Descrição"],
          rows: [
            ["hub.middleware()", "Expõe o hub aos factories via wsHub(c)"],
            [
              "hub.to(room) / hub.broadcast()",
              "Fanout fluente — encadeie .except(ws), depois send / sendJson / sendBytes",
            ],
            ["hub.connections / roomSize / rooms", "Estatísticas de membership"],
            ["ws.id / ws.rooms", "UUID por conexão + rooms onde está"],
            ["ws.join(room) / ws.leave(room)", "Muda membership (auto-leave no close)"],
            ["ws.to(room) / ws.broadcast()", "Atalhos para hub.to / hub.broadcast"],
          ],
        },
        { kind: "h3", text: "Fanout multi-instância — RedisWsAdapter", id: "ws-redis" },
        {
          kind: "p",
          text: "Quando duas réplicas atrás de um load balancer têm sockets no mesmo room, anexe o adapter Redis para que broadcasts cruzem instâncias. A marcação de origem evita echo do próprio remetente.",
        },
        {
          kind: "code",
          code: `final hub = WsHub();\nawait hub.attachAdapter(await RedisWsAdapter.connect(\n  host: 'localhost',\n  port: 6379,\n));\n\nfinal app = Darto()..use(hub.middleware());`,
        },
        { kind: "h3", text: "WSHandler & DartoWebSocket", id: "ws-api" },
        {
          kind: "table",
          headers: ["Callback do WSHandler", "Descrição"],
          rows: [
            ["onOpen: (ws)", "Conexão estabelecida"],
            ["onMessage: (event, ws)", "Chegou um frame — leia event.text ou event.json"],
            ["onClose: (ws)", "Conexão fechada — leia ws.id / ws.rooms aqui"],
            ["onError: (err, ws)", "Ocorreu um erro"],
          ],
        },
        {
          kind: "callout",
          variant: "warning",
          text: "Breaking em 1.1.0: onClose e onError agora recebem o socket que está fechando — o antigo `onClose: () => …` vira `onClose: (_) => …`.",
        },
        {
          kind: "table",
          headers: ["Membro ws / event", "Descrição"],
          rows: [
            ["ws.send(text)", "Envia um frame de texto para este cliente"],
            ["ws.sendJson(map)", "Codifica um Map como JSON e envia"],
            ["ws.sendBytes(bytes)", "Envia um frame binário"],
            ["ws.close([code, reason])", "Fecha a conexão"],
            ["ws.closeCode", "Código de fechamento do peer (null enquanto aberto)"],
            ["ws.id", "UUID v4 único da conexão"],
            [
              "ws.rooms / join / leave / to / broadcast",
              "Helpers do hub (requerem hub.middleware())",
            ],
            ["event.text", "Dados do frame como String"],
            ["event.json", "Dados do frame parseados como Map JSON"],
          ],
        },
      ],
    ),
  },
  {
    id: "error-handling",
    group: "advanced",
    title: bi("Error Handling", "Tratamento de erros"),
    blocks: bi(
      [
        {
          kind: "code",
          code: `app.onError((err, c) {\n  print('error: \$err');\n  return c.internalError({'error': 'something went wrong'});\n});\n\napp.notFound((c) => c.notFound({'error': 'route not found'}));`,
        },
      ],
      [
        {
          kind: "code",
          code: `app.onError((err, c) {\n  print('erro: \$err');\n  return c.internalError({'error': 'algo deu errado'});\n});\n\napp.notFound((c) => c.notFound({'error': 'rota não encontrada'}));`,
        },
      ],
    ),
  },
  {
    id: "helpers",
    group: "helpers",
    title: bi("Helpers", "Helpers"),
    blocks: bi(
      [
        { kind: "h3", text: "Cookie", id: "helpers-cookie" },
        {
          kind: "p",
          text: "Cookie helpers are standalone functions imported from package:darto/cookie.dart.",
        },
        {
          kind: "code",
          code: `import 'package:darto/cookie.dart';\n\nsetCookie(c, 'session', token,\n  CookieOptions(maxAge: 3600, httpOnly: true, secure: true));\nfinal sid = getCookie(c, 'session');\ndeleteCookie(c, 'session');\n\n// Signed cookies (HMAC-SHA256)\nawait setSignedCookie(c, 'session', token, secret);\nfinal val = await getSignedCookie(c, secret, 'session');`,
        },
        {
          kind: "table",
          headers: ["Function", "Description"],
          rows: [
            [
              "setCookie(c, name, value, [opts])",
              "Add a Set-Cookie header (multiple cookies stack)",
            ],
            ["getCookie(c, name)", "Read a cookie sent by the client (String?)"],
            ["getCookies(c)", "All client cookies as Map<String, String>"],
            ["deleteCookie(c, name)", "Expire a cookie"],
            ["setSignedCookie(c, name, value, secret, [opts])", "Set an HMAC-SHA256 signed cookie"],
            [
              "getSignedCookie(c, secret, name)",
              "Read & verify a signed cookie — null if tampered",
            ],
            [
              "CookieOptions(path, domain, maxAge, expires, httpOnly, secure, sameSite)",
              "Cookie attributes",
            ],
          ],
        },
        { kind: "h3", text: "JWT helpers", id: "helpers-jwt" },
        {
          kind: "p",
          text: "sign() and verify() are async. Include exp in the payload to set an expiry.",
        },
        {
          kind: "code",
          code: `import 'package:darto/jwt.dart';\n\nfinal token = await sign(\n  {'sub': '42', 'exp': DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000},\n  env.jwtSecret,\n);\nfinal payload = await verify(token, env.jwtSecret);`,
        },
        { kind: "h3", text: "Proxy", id: "helpers-proxy" },
        {
          kind: "p",
          text: "proxy() is a route handler helper — call it inside a handler and return its result. A single wildcard route covers exact and deep paths.",
        },
        {
          kind: "code",
          code: `import 'package:darto/proxy.dart';\n\n// /* matches both the exact path and any sub-path:\n// /api/users  •  /api/users/1  •  /api/users/1/posts\napp.all('/api/users/*', [], (Context c) =>\n    proxy(c, 'https://backend.com\${c.req.path}'));\n\n// With header overrides\napp.all('/v1/*', [], (Context c) =>\n    proxy(c, 'https://example.com\${c.req.path}',\n        options: ProxyOptions(\n          headers: {\n            'X-Proxy-By': 'darto-gateway',\n            'Authorization': 'Bearer INTERNAL_SECRET',\n            'Cookie': null, // null = remove header\n          },\n        )));`,
        },
        { kind: "h3", text: "Health checks", id: "helpers-health" },
        {
          kind: "p",
          text: "health() builds a liveness/readiness Handler. Returns 200 {status: 'ok'} when every check passes, or 503 {status: 'unavailable', checks: {...}} when any fails. A throwing check counts as down.",
        },
        {
          kind: "code",
          code: `import 'package:darto/health.dart';\n\n// Liveness — 200 while the process is up\napp.get('/healthz', [], health());\n\n// Readiness — 503 until dependencies are reachable\napp.get('/readyz', [], health(\n  checks: {'db': () => db.ping(), 'cache': () => redis.ping()},\n  info: () => {'version': '1.0.0'},\n));`,
        },
        { kind: "h3", text: "Streaming (binary, text, SSE)", id: "helpers-stream" },
        {
          kind: "p",
          text: "Return one of stream() / streamText() / streamSSE() from a handler to push response chunks over a kept-alive connection. The writer exposes write / pipe / sleep, and onAbort fires when the client disconnects.",
        },
        {
          kind: "code",
          code: `import 'package:darto/stream.dart';\n\n// Server-Sent Events — push live updates to the browser\napp.get('/sse', [], (c) => streamSSE(c, (w) async {\n  w.onAbort(() => print('client gone'));\n  for (var i = 0; i < 5; i++) {\n    await w.writeSSE(SseEvent(event: 'tick', data: '\$i'));\n    await w.sleep(const Duration(seconds: 1));\n  }\n}));\n\n// Text stream — line-by-line\napp.get('/log', [], (c) => streamText(c, (w) async {\n  await w.writeln('starting…');\n  await w.pipe(linesOf('build.log'));\n}));`,
        },
        {
          kind: "table",
          headers: ["Helper", "Description"],
          rows: [
            [
              "stream(c, cb, {onError})",
              "Binary stream — writer is DartoStreamWriter (write / pipe)",
            ],
            [
              "streamText(c, cb, {onError})",
              "Text stream — writer is DartoTextStreamWriter (write / writeln / pipe)",
            ],
            [
              "streamSSE(c, cb, {onError})",
              "Server-Sent Events — writer is DartoSSEWriter (writeSSE / sleep)",
            ],
            ["SseEvent({data, event, id, retry})", "Payload for one SSE message"],
            ["writer.onAbort(cb)", "Fires when the client closes the connection"],
          ],
        },
        { kind: "h3", text: "Route introspection", id: "helpers-route" },
        {
          kind: "p",
          text: "Inspect the routing decision the framework made for the current request — useful for logging, metrics or debugging.",
        },
        {
          kind: "code",
          code: `import 'package:darto/route.dart';\n\napp.get('/posts/:id', [], (c) {\n  print(routePath(c));      // '/posts/:id'\n  print(basePath(c));       // '/' (or the app's basePath)\n  print(matchedRoutes(c));  // every route that fired, mw + handler\n  return c.ok({});\n});`,
        },
        {
          kind: "table",
          headers: ["Function", "Description"],
          rows: [
            [
              "matchedRoutes(c)",
              "List<RouteSpec> of every route that matched (middleware + handler)",
            ],
            ["routePath(c)", "Pattern of the matched handler — e.g. '/posts/:id'"],
            ["baseRoutePath(c)", "Group prefix pattern of the matched route"],
            ["basePath(c)", "The app's base path"],
          ],
        },
        { kind: "h3", text: "Dev — routes printer", id: "helpers-dev" },
        {
          kind: "p",
          text: "showRoutes(app) pretty-prints every registered route with colored HTTP verbs — handy during development to verify wiring at a glance.",
        },
        {
          kind: "code",
          code: `import 'package:darto/dev.dart';\n\nfinal app = Darto();\napp.get('/users', [], handler);\napp.post('/users', [], handler);\n\nshowRoutes(app); // GET  /users\n                 // POST /users\napp.listen(3000);`,
        },
      ],
      [
        { kind: "h3", text: "Cookie", id: "helpers-cookie" },
        {
          kind: "p",
          text: "Os helpers de cookie são funções standalone importadas de package:darto/cookie.dart.",
        },
        {
          kind: "code",
          code: `import 'package:darto/cookie.dart';\n\nsetCookie(c, 'session', token,\n  CookieOptions(maxAge: 3600, httpOnly: true, secure: true));\nfinal sid = getCookie(c, 'session');\ndeleteCookie(c, 'session');\n\n// Cookies assinados (HMAC-SHA256)\nawait setSignedCookie(c, 'session', token, secret);\nfinal val = await getSignedCookie(c, secret, 'session');`,
        },
        {
          kind: "table",
          headers: ["Função", "Descrição"],
          rows: [
            [
              "setCookie(c, name, value, [opts])",
              "Adiciona um header Set-Cookie (múltiplos cookies acumulam)",
            ],
            ["getCookie(c, name)", "Lê um cookie enviado pelo cliente (String?)"],
            ["getCookies(c)", "Todos os cookies do cliente como Map<String, String>"],
            ["deleteCookie(c, name)", "Expira um cookie"],
            [
              "setSignedCookie(c, name, value, secret, [opts])",
              "Define um cookie assinado com HMAC-SHA256",
            ],
            [
              "getSignedCookie(c, secret, name)",
              "Lê e verifica um cookie assinado — null se adulterado",
            ],
            [
              "CookieOptions(path, domain, maxAge, expires, httpOnly, secure, sameSite)",
              "Atributos do cookie",
            ],
          ],
        },
        { kind: "h3", text: "JWT helpers", id: "helpers-jwt" },
        {
          kind: "p",
          text: "sign() e verify() são assíncronos. Inclua exp no payload para definir expiração.",
        },
        {
          kind: "code",
          code: `import 'package:darto/jwt.dart';\n\nfinal token = await sign(\n  {'sub': '42', 'exp': DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000},\n  env.jwtSecret,\n);\nfinal payload = await verify(token, env.jwtSecret);`,
        },
        { kind: "h3", text: "Proxy", id: "helpers-proxy" },
        {
          kind: "p",
          text: "proxy() é um helper de handler — chame dentro de um handler e retorne o resultado. Uma única rota wildcard cobre caminhos exatos e profundos.",
        },
        {
          kind: "code",
          code: `import 'package:darto/proxy.dart';\n\n// Forward transparente — método + headers + body\napp.all('/api/*', [], (Context c) =>\n    proxy(c, 'https://backend.com\${c.req.path}'));\n\n// Com sobrescrita de headers\napp.all('/v1/*', [], (Context c) =>\n    proxy(c, 'https://example.com\${c.req.path}',\n        options: ProxyOptions(\n          headers: {\n            'X-Proxy-By': 'darto-gateway',\n            'Authorization': 'Bearer INTERNAL_SECRET',\n            'Cookie': null, // null = remove o header\n          },\n        )));`,
        },
        { kind: "h3", text: "Health checks", id: "helpers-health" },
        {
          kind: "p",
          text: "health() constrói um Handler de liveness/readiness. Devolve 200 {status: 'ok'} quando todos os checks passam, ou 503 {status: 'unavailable', checks: {...}} quando algum falha. Um check que lança conta como down.",
        },
        {
          kind: "code",
          code: `import 'package:darto/health.dart';\n\n// Liveness — 200 enquanto o processo está de pé\napp.get('/healthz', [], health());\n\n// Readiness — 503 até as dependências estarem acessíveis\napp.get('/readyz', [], health(\n  checks: {'db': () => db.ping(), 'cache': () => redis.ping()},\n  info: () => {'version': '1.0.0'},\n));`,
        },
        { kind: "h3", text: "Streaming (binário, texto, SSE)", id: "helpers-stream" },
        {
          kind: "p",
          text: "Retorne um de stream() / streamText() / streamSSE() de um handler para empurrar chunks de resposta sobre uma conexão mantida aberta. O writer expõe write / pipe / sleep, e onAbort dispara quando o cliente desconecta.",
        },
        {
          kind: "code",
          code: `import 'package:darto/stream.dart';\n\n// Server-Sent Events — empurra updates pro navegador\napp.get('/sse', [], (c) => streamSSE(c, (w) async {\n  w.onAbort(() => print('cliente saiu'));\n  for (var i = 0; i < 5; i++) {\n    await w.writeSSE(SseEvent(event: 'tick', data: '\$i'));\n    await w.sleep(const Duration(seconds: 1));\n  }\n}));\n\n// Stream de texto — linha a linha\napp.get('/log', [], (c) => streamText(c, (w) async {\n  await w.writeln('iniciando…');\n  await w.pipe(linesOf('build.log'));\n}));`,
        },
        {
          kind: "table",
          headers: ["Helper", "Descrição"],
          rows: [
            [
              "stream(c, cb, {onError})",
              "Stream binário — writer é DartoStreamWriter (write / pipe)",
            ],
            [
              "streamText(c, cb, {onError})",
              "Stream de texto — writer é DartoTextStreamWriter (write / writeln / pipe)",
            ],
            [
              "streamSSE(c, cb, {onError})",
              "Server-Sent Events — writer é DartoSSEWriter (writeSSE / sleep)",
            ],
            ["SseEvent({data, event, id, retry})", "Payload de uma mensagem SSE"],
            ["writer.onAbort(cb)", "Dispara quando o cliente fecha a conexão"],
          ],
        },
        { kind: "h3", text: "Introspecção de rota", id: "helpers-route" },
        {
          kind: "p",
          text: "Inspecione a decisão de roteamento que o framework tomou para a requisição atual — útil para logging, métricas ou debug.",
        },
        {
          kind: "code",
          code: `import 'package:darto/route.dart';\n\napp.get('/posts/:id', [], (c) {\n  print(routePath(c));      // '/posts/:id'\n  print(basePath(c));       // '/' (ou o basePath do app)\n  print(matchedRoutes(c));  // toda rota que disparou, mw + handler\n  return c.ok({});\n});`,
        },
        {
          kind: "table",
          headers: ["Função", "Descrição"],
          rows: [
            ["matchedRoutes(c)", "List<RouteSpec> de toda rota que casou (middleware + handler)"],
            ["routePath(c)", "Padrão do handler casado — ex.: '/posts/:id'"],
            ["baseRoutePath(c)", "Padrão do prefixo de grupo da rota casada"],
            ["basePath(c)", "O base path do app"],
          ],
        },
        { kind: "h3", text: "Dev — printer de rotas", id: "helpers-dev" },
        {
          kind: "p",
          text: "showRoutes(app) imprime todas as rotas registradas com os verbos HTTP coloridos — útil em dev pra conferir o wiring de relance.",
        },
        {
          kind: "code",
          code: `import 'package:darto/dev.dart';\n\nfinal app = Darto();\napp.get('/users', [], handler);\napp.post('/users', [], handler);\n\nshowRoutes(app); // GET  /users\n                 // POST /users\napp.listen(3000);`,
        },
      ],
    ),
  },
  {
    id: "cli-tools",
    group: "plugins",
    title: bi("CLI Tools", "Ferramentas CLI"),
    blocks: bi(
      [
        { kind: "ref", to: "plugin-cli", label: "Package: darto_cli" },
        { kind: "p", text: "Install the Darto CLI globally with pub:" },
        { kind: "code", lang: "sh", code: `dart pub global activate darto_cli` },
        { kind: "p", text: "Make sure ~/.pub-cache/bin is on your PATH." },
        { kind: "h3", text: "Create a project", id: "cli-create" },
        {
          kind: "code",
          lang: "sh",
          code: `darto create my_api          # with starter user module\ndarto create my_api --blank  # minimal — no modules, just GET /health`,
        },
        { kind: "p", text: "Generated structure (default):" },
        {
          kind: "code",
          lang: "sh",
          code: `my_api/\n  bin/server.dart\n  lib/\n    app.dart\n    modules/user/\n      user_controller.dart   # handlers + route registration\n      user_service.dart      # business logic\n  pubspec.yaml`,
        },
        { kind: "h3", text: "Dev server", id: "cli-dev" },
        {
          kind: "p",
          text: "Watches lib/, bin/, and src/ recursively. Restarts automatically (350 ms debounce) on any .dart file change — including deep subdirectories.",
        },
        { kind: "code", lang: "sh", code: `darto dev\ndarto dev bin/server.dart` },
        { kind: "h3", text: "Build & Start", id: "cli-build" },
        {
          kind: "code",
          lang: "sh",
          code: `darto build                       # compile to build/server + Dockerfile\ndarto build --output build/api    # custom output path\ndarto build --no-docker           # skip Dockerfile\ndarto start                       # run the compiled binary`,
        },
        { kind: "h3", text: "Generate typed Flutter client", id: "cli-gen" },
        {
          kind: "code",
          lang: "sh",
          code: `darto gen client flutter\ndarto gen client flutter --base-url https://api.example.com --output lib/api_client.dart`,
        },
        {
          kind: "callout",
          variant: "tip",
          text: "darto gen reads createApp() from lib/app.dart, introspects all registered routes, and emits a typed ApiClient with one sub-module class per route group.",
        },
      ],
      [
        { kind: "ref", to: "plugin-cli", label: "Pacote: darto_cli" },
        { kind: "p", text: "Instale o Darto CLI globalmente com pub:" },
        { kind: "code", lang: "sh", code: `dart pub global activate darto_cli` },
        { kind: "p", text: "Certifique-se de que ~/.pub-cache/bin está no seu PATH." },
        { kind: "h3", text: "Criar um projeto", id: "cli-create" },
        {
          kind: "code",
          lang: "sh",
          code: `darto create my_api          # com módulo user de exemplo\ndarto create my_api --blank  # mínimo — sem módulos, apenas GET /health`,
        },
        { kind: "p", text: "Estrutura gerada (padrão):" },
        {
          kind: "code",
          lang: "sh",
          code: `my_api/\n  bin/server.dart\n  lib/\n    app.dart\n    modules/user/\n      user_controller.dart   # handlers + registro de rotas\n      user_service.dart      # lógica de negócio\n  pubspec.yaml`,
        },
        { kind: "h3", text: "Servidor de desenvolvimento", id: "cli-dev" },
        {
          kind: "p",
          text: "Observa lib/, bin/ e src/ recursivamente. Reinicia automaticamente (debounce de 350 ms) ao alterar qualquer arquivo .dart — inclusive em subdiretórios profundos.",
        },
        { kind: "code", lang: "sh", code: `darto dev\ndarto dev bin/server.dart` },
        { kind: "h3", text: "Build & Start", id: "cli-build" },
        {
          kind: "code",
          lang: "sh",
          code: `darto build                       # compila para build/server + Dockerfile\ndarto build --output build/api    # caminho de saída personalizado\ndarto build --no-docker           # sem Dockerfile\ndarto start                       # executa o binário compilado`,
        },
        { kind: "h3", text: "Gerar cliente Flutter tipado", id: "cli-gen" },
        {
          kind: "code",
          lang: "sh",
          code: `darto gen client flutter\ndarto gen client flutter --base-url https://api.example.com --output lib/api_client.dart`,
        },
        {
          kind: "callout",
          variant: "tip",
          text: "darto gen lê createApp() de lib/app.dart, inspeciona todas as rotas registradas e emite um ApiClient tipado com uma sub-classe por grupo de rotas.",
        },
      ],
    ),
  },
  {
    id: "full-example",
    group: "advanced",
    title: bi("Full Example", "Exemplo completo"),
    blocks: bi(
      [
        {
          kind: "code",
          code: `import 'package:darto/darto.dart';\nimport 'package:darto/logger.dart';\nimport 'package:darto/cors.dart';\nimport 'package:darto/jwt.dart';\nimport 'package:darto_validator/darto_validator.dart';\n\nfinal createUser = z.map({\n  'email': z.string().email(),\n  'name':  z.string().min(2),\n});\n\nvoid main() {\n  final app = Darto();\n\n  app.use(logger());\n  app.mount('/api/*', cors());\n  app.mount('/api/*', jwt(secret: 'mySecret'));\n\n  final api = app.group('/api');\n\n  api.get('/me', [], (c) {\n    final payload = c.get<Map<String, dynamic>>('jwtPayload');\n    return c.ok({'userId': payload?['sub']});\n  });\n\n  api.post('/users', [zValidator('json', createUser)], (c) {\n    final data = c.req.valid<Map<String, dynamic>>('json');\n    return c.created({'id': '42', ...data});\n  });\n\n  app.onError((err, c) => c.internalError({'error': err.toString()}));\n\n  app.listen(3000, () => print('http://localhost:3000'));\n}`,
        },
      ],
      [
        {
          kind: "code",
          code: `import 'package:darto/darto.dart';\nimport 'package:darto/logger.dart';\nimport 'package:darto/cors.dart';\nimport 'package:darto/jwt.dart';\nimport 'package:darto_validator/darto_validator.dart';\n\nfinal createUser = z.map({\n  'email': z.string().email(),\n  'name':  z.string().min(2),\n});\n\nvoid main() {\n  final app = Darto();\n\n  app.use(logger());\n  app.mount('/api/*', cors());\n  app.mount('/api/*', jwt(secret: 'mySecret'));\n\n  final api = app.group('/api');\n\n  api.get('/me', [], (c) {\n    final payload = c.get<Map<String, dynamic>>('jwtPayload');\n    return c.ok({'userId': payload?['sub']});\n  });\n\n  api.post('/users', [zValidator('json', createUser)], (c) {\n    final data = c.req.valid<Map<String, dynamic>>('json');\n    return c.created({'id': '42', ...data});\n  });\n\n  app.onError((err, c) => c.internalError({'error': err.toString()}));\n\n  app.listen(3000, () => print('http://localhost:3000'));\n}`,
        },
      ],
    ),
  },
  // ── Official plugins ────────────────────────────────────────────────────────
  {
    id: "plugin-cli",
    group: "plugins",
    title: bi("darto_cli", "darto_cli"),
    blocks: bi(
      [
        {
          kind: "links",
          links: [
            { label: "pub.dev", href: "https://pub.dev/packages/darto_cli" },
            { label: "GitHub", href: "https://github.com/evandersondev/darto/tree/main/darto_cli" },
          ],
        },
        {
          kind: "p",
          text: "Official CLI — scaffold projects, run a hot-reload dev server, build native executables and generate a typed API client.",
        },
        { kind: "h3", text: "Install", id: "cli-install" },
        { kind: "code", lang: "sh", code: `dart pub global activate darto_cli` },
        { kind: "ref", to: "cli-tools", label: "Full guide: CLI Tools" },
      ],
      [
        {
          kind: "links",
          links: [
            { label: "pub.dev", href: "https://pub.dev/packages/darto_cli" },
            { label: "GitHub", href: "https://github.com/evandersondev/darto/tree/main/darto_cli" },
          ],
        },
        {
          kind: "p",
          text: "CLI oficial — cria projetos, roda um dev server com hot-reload, compila executáveis nativos e gera um cliente de API tipado.",
        },
        { kind: "h3", text: "Instalação", id: "cli-install" },
        { kind: "code", lang: "sh", code: `dart pub global activate darto_cli` },
        { kind: "ref", to: "cli-tools", label: "Guia completo: Ferramentas CLI" },
      ],
    ),
  },
  {
    id: "plugin-validator",
    group: "plugins",
    title: bi("darto_validator", "darto_validator"),
    blocks: bi(
      [
        {
          kind: "links",
          links: [
            { label: "pub.dev", href: "https://pub.dev/packages/darto_validator" },
            {
              label: "GitHub",
              href: "https://github.com/evandersondev/darto/tree/main/darto_validator",
            },
          ],
        },
        {
          kind: "p",
          text: "Request validation powered by zard (Zod-style) via the zValidator middleware. Pairs schema-driven validation with automatic 400 responses and a c.req.valid<T>() typed read. Also converts schemas to OpenAPI with schema.toOpenApiSchema().",
        },
        { kind: "h3", text: "Install", id: "validator-install" },
        { kind: "code", lang: "yaml", code: `dependencies:\n  darto_validator: ^1.1.0` },
        { kind: "h3", text: "zValidator — schema-driven", id: "val-zvalidator" },
        {
          kind: "code",
          code: `import 'package:darto_validator/darto_validator.dart';\n\nfinal body = z.map({\n  'email': z.string().email(),\n  'age':   z.int().min(18),\n});\n\napp.post('/users', [zValidator('json', body)], (c) {\n  final data = c.req.valid<Map<String, dynamic>>('json');\n  return c.created(data);\n});`,
        },
        { kind: "h3", text: "Custom error hook", id: "val-hook" },
        {
          kind: "code",
          code: `zValidator('json', body, (result, c) {\n  if (!result.success) {\n    return c.status(422).json({\n      'error': 'Validation failed',\n      'issues': result.error?.format(),\n    });\n  }\n  return null;\n});`,
        },
        {
          kind: "callout",
          variant: "tip",
          text: "If you only need the core validator (no zard schema), you don't need this package — see Middlewares → Validator (core).",
        },
        { kind: "ref", to: "validator", label: "Core alternative: validator (no plugin needed)" },
      ],
      [
        {
          kind: "links",
          links: [
            { label: "pub.dev", href: "https://pub.dev/packages/darto_validator" },
            {
              label: "GitHub",
              href: "https://github.com/evandersondev/darto/tree/main/darto_validator",
            },
          ],
        },
        {
          kind: "p",
          text: "Validação de requisições com zard (estilo Zod) via middleware zValidator. Junta validação baseada em schema com respostas 400 automáticas e leitura tipada via c.req.valid<T>(). Também converte schemas para OpenAPI com schema.toOpenApiSchema().",
        },
        { kind: "h3", text: "Instalação", id: "validator-install" },
        { kind: "code", lang: "yaml", code: `dependencies:\n  darto_validator: ^1.1.0` },
        { kind: "h3", text: "zValidator — baseado em schema", id: "val-zvalidator" },
        {
          kind: "code",
          code: `import 'package:darto_validator/darto_validator.dart';\n\nfinal body = z.map({\n  'email': z.string().email(),\n  'age':   z.int().min(18),\n});\n\napp.post('/users', [zValidator('json', body)], (c) {\n  final data = c.req.valid<Map<String, dynamic>>('json');\n  return c.created(data);\n});`,
        },
        { kind: "h3", text: "Hook de erro customizado", id: "val-hook" },
        {
          kind: "code",
          code: `zValidator('json', body, (result, c) {\n  if (!result.success) {\n    return c.status(422).json({\n      'error': 'Validação falhou',\n      'issues': result.error?.format(),\n    });\n  }\n  return null;\n});`,
        },
        {
          kind: "callout",
          variant: "tip",
          text: "Se você só precisa do validator do core (sem schema zard), não precisa deste pacote — veja Middlewares → Validator (core).",
        },
        { kind: "ref", to: "validator", label: "Alternativa do core: validator (sem plugin)" },
      ],
    ),
  },
  {
    id: "plugin-openapi",
    group: "plugins",
    title: bi("darto_openapi", "darto_openapi"),
    blocks: bi(
      [
        {
          kind: "links",
          links: [
            { label: "pub.dev", href: "https://pub.dev/packages/darto_openapi" },
            {
              label: "GitHub",
              href: "https://github.com/evandersondev/darto/tree/main/darto_openapi",
            },
          ],
        },
        {
          kind: "p",
          text: "OpenAPI 3.1 spec generation + Scalar API docs. Describe a route once: it validates the request and is documented from the same source.",
        },
        { kind: "h3", text: "Install", id: "openapi-install" },
        { kind: "code", lang: "yaml", code: `dependencies:\n  darto_openapi: ^1.0.0` },
        { kind: "h3", text: "Usage", id: "openapi-usage" },
        {
          kind: "code",
          code: `import 'package:darto_openapi/darto_openapi.dart';\n\nfinal api = OpenApi(app, info: Info(title: 'API', version: '1.0.0'));\n\napi.post('/posts',\n  request: Req(json: Schema.object({'title': Schema.string(minLength: 1)}, required: ['title'])),\n  responses: {201: Res('Created')},\n  handler: (c) => c.created(c.req.valid('json')),\n);\n\napp.use(api.docs()); // serves /openapi.json + /docs (Scalar)`,
        },
        { kind: "h3", text: "Schema builders", id: "openapi-schema" },
        {
          kind: "table",
          headers: ["Builder", "Description"],
          rows: [
            [
              "Schema.string({minLength, maxLength, format})",
              "String — format: 'email' | 'uri' | 'date-time' | …",
            ],
            ["Schema.integer({minimum, maximum})", "Integer number"],
            ["Schema.number({minimum})", "Floating-point number"],
            ["Schema.boolean()", "Boolean"],
            ["Schema.array(schema, {minItems})", "Array of items matching schema"],
            ["Schema.object({fields}, {required})", "Object with named properties"],
            ["Schema.raw(Map)", "Pass raw OpenAPI schema through unchanged"],
          ],
        },
        { kind: "h3", text: "Security schemes", id: "openapi-security" },
        {
          kind: "code",
          code: `final api = OpenApi(app,\n  info: Info(title: 'My API', version: '1.0.0'),\n  securitySchemes: {\n    'bearer': SecurityScheme.bearer(),\n    'apiKey': SecurityScheme.apiKey(name: 'x-api-key', location: 'header'),\n  },\n);\n\napi.get('/me',\n  security: ['bearer'],\n  responses: {200: Res('User profile')},\n  handler: (c) => c.ok({'user': 'me'}),\n);`,
        },
        { kind: "h3", text: "Typed client", id: "openapi-client" },
        {
          kind: "p",
          text: "generateDartClient(spec) turns the OpenAPI document into an end-to-end typed Dart client — model classes plus a typed method per operation (dependency-free).",
        },
        {
          kind: "code",
          code: `final src = generateDartClient(api.toJson(), baseUrl: 'https://api.example.com');\nFile('lib/api_client.dart').writeAsStringSync(src);\n\n// in the generated client:\nfinal post = await ApiClient().postPosts(PostPostsRequest(title: 'Hello'));\nprint(post.id); // typed`,
        },
      ],
      [
        {
          kind: "links",
          links: [
            { label: "pub.dev", href: "https://pub.dev/packages/darto_openapi" },
            {
              label: "GitHub",
              href: "https://github.com/evandersondev/darto/tree/main/darto_openapi",
            },
          ],
        },
        {
          kind: "p",
          text: "Geração de spec OpenAPI 3.1 + docs Scalar. Descreva a rota uma vez: ela valida a requisição e é documentada a partir da mesma fonte.",
        },
        { kind: "h3", text: "Instalação", id: "openapi-install" },
        { kind: "code", lang: "yaml", code: `dependencies:\n  darto_openapi: ^1.0.0` },
        { kind: "h3", text: "Uso", id: "openapi-usage" },
        {
          kind: "code",
          code: `import 'package:darto_openapi/darto_openapi.dart';\n\nfinal api = OpenApi(app, info: Info(title: 'API', version: '1.0.0'));\n\napi.post('/posts',\n  request: Req(json: Schema.object({'title': Schema.string(minLength: 1)}, required: ['title'])),\n  responses: {201: Res('Created')},\n  handler: (c) => c.created(c.req.valid('json')),\n);\n\napp.use(api.docs()); // serve /openapi.json + /docs (Scalar)`,
        },
        { kind: "h3", text: "Schema builders", id: "openapi-schema" },
        {
          kind: "table",
          headers: ["Builder", "Descrição"],
          rows: [
            [
              "Schema.string({minLength, maxLength, format})",
              "String — format: 'email' | 'uri' | 'date-time' | …",
            ],
            ["Schema.integer({minimum, maximum})", "Número inteiro"],
            ["Schema.number({minimum})", "Número de ponto flutuante"],
            ["Schema.boolean()", "Booleano"],
            ["Schema.array(schema, {minItems})", "Array com itens que casam com o schema"],
            ["Schema.object({fields}, {required})", "Objeto com propriedades nomeadas"],
            ["Schema.raw(Map)", "Passa um schema OpenAPI cru sem alteração"],
          ],
        },
        { kind: "h3", text: "Esquemas de segurança", id: "openapi-security" },
        {
          kind: "code",
          code: `final api = OpenApi(app,\n  info: Info(title: 'My API', version: '1.0.0'),\n  securitySchemes: {\n    'bearer': SecurityScheme.bearer(),\n    'apiKey': SecurityScheme.apiKey(name: 'x-api-key', location: 'header'),\n  },\n);\n\napi.get('/me',\n  security: ['bearer'],\n  responses: {200: Res('Perfil do usuário')},\n  handler: (c) => c.ok({'user': 'me'}),\n);`,
        },
        { kind: "h3", text: "Client tipado", id: "openapi-client" },
        {
          kind: "p",
          text: "generateDartClient(spec) transforma o documento OpenAPI num client Dart tipado ponta a ponta — classes de modelo e um método tipado por operação (sem dep externa).",
        },
        {
          kind: "code",
          code: `final src = generateDartClient(api.toJson(), baseUrl: 'https://api.example.com');\nFile('lib/api_client.dart').writeAsStringSync(src);\n\n// no client gerado:\nfinal post = await ApiClient().postPosts(PostPostsRequest(title: 'Hello'));\nprint(post.id); // tipado`,
        },
      ],
    ),
  },
  {
    id: "plugin-test",
    group: "plugins",
    title: bi("darto_test", "darto_test"),
    blocks: bi(
      [
        {
          kind: "links",
          links: [
            { label: "pub.dev", href: "https://pub.dev/packages/darto_test" },
            {
              label: "GitHub",
              href: "https://github.com/evandersondev/darto/tree/main/darto_test",
            },
          ],
        },
        {
          kind: "p",
          text: "Ergonomic test client — boot an app on an ephemeral port and assert responses without managing a server (supertest-style).",
        },
        { kind: "h3", text: "Install", id: "test-install" },
        { kind: "code", lang: "yaml", code: `dev_dependencies:\n  darto_test: ^1.0.0` },
        { kind: "h3", text: "Usage", id: "test-usage" },
        {
          kind: "code",
          code: `import 'package:darto_test/darto_test.dart';\n\nfinal client = await TestClient.create(buildApp());\n\nfinal res = await client.get('/hello');\nexpect(res.statusCode, 200);\nexpect(res.json['msg'], 'hi');\n\nawait client.close();`,
        },
        { kind: "h3", text: "setUp / tearDown pattern", id: "test-setup" },
        {
          kind: "code",
          code: `import 'package:darto_test/darto_test.dart';\nimport 'package:test/test.dart';\n\nvoid main() {\n  late TestClient client;\n\n  setUp(() async => client = await TestClient.create(buildApp()));\n  tearDown(() => client.close());\n\n  test('GET /hello returns 200', () async {\n    final res = await client.get('/hello');\n    expect(res.statusCode, 200);\n    expect(res.json['msg'], 'hi');\n  });\n\n  test('POST /users creates a user', () async {\n    final res = await client.post('/users', json: {'name': 'Alice'});\n    expect(res.statusCode, 201);\n    expect(res.json['name'], 'Alice');\n  });\n}`,
        },
        { kind: "h3", text: "json: vs body:", id: "test-json-body" },
        {
          kind: "p",
          text: "json: accepts a Map/List, encodes it with jsonEncode and sets Content-Type: application/json automatically. body: sends the value raw — a String is written as-is, a List<int> is sent as bytes. Use json: for APIs (the common case), body: when you need to control the payload format.",
        },
        {
          kind: "code",
          code: `// json: → auto-encode + Content-Type: application/json\nclient.post('/users', json: {'name': 'Alice'});\n\n// body: → raw String (no Content-Type set)\nclient.post('/login', body: 'username=alice&password=s3cret',\n  headers: {'content-type': 'application/x-www-form-urlencoded'});\n\n// body: → raw bytes\nclient.post('/upload', body: imageBytes);`,
        },
        { kind: "h3", text: "TestClient API", id: "test-client-api" },
        {
          kind: "table",
          headers: ["Member", "Description"],
          rows: [
            ["TestClient.create(app)", "Boots the app on a free loopback port; returns a client"],
            ["client.get / head / options(path, {headers})", "Request without a body"],
            [
              "client.post / put / patch / delete(path, {headers, body, json})",
              "Request with an optional body",
            ],
            ["client.request(method, path, {...})", "Generic request"],
            ["client.port", "The bound ephemeral port"],
            ["client.close()", "Stops the app and closes the client"],
          ],
        },
        { kind: "h3", text: "TestResponse API", id: "test-response-api" },
        {
          kind: "table",
          headers: ["Member", "Description"],
          rows: [
            ["res.statusCode", "HTTP status code"],
            ["res.body", "Raw response body as UTF-8 text"],
            ["res.json", "Body parsed as JSON (null when empty)"],
            ["res.header(name)", "Response header value (case-insensitive)"],
            ["res.headers", "All headers as Map<String, String>"],
            ["res.cookie(name) / res.cookies", "Set-Cookie lookup / full list"],
            ["res.isOk", "true for 2xx status codes"],
          ],
        },
      ],
      [
        {
          kind: "links",
          links: [
            { label: "pub.dev", href: "https://pub.dev/packages/darto_test" },
            {
              label: "GitHub",
              href: "https://github.com/evandersondev/darto/tree/main/darto_test",
            },
          ],
        },
        {
          kind: "p",
          text: "Client de teste ergonômico — sobe o app numa porta efêmera e faz asserts sem gerenciar servidor (estilo supertest).",
        },
        { kind: "h3", text: "Instalação", id: "test-install" },
        { kind: "code", lang: "yaml", code: `dev_dependencies:\n  darto_test: ^1.0.0` },
        { kind: "h3", text: "Uso", id: "test-usage" },
        {
          kind: "code",
          code: `import 'package:darto_test/darto_test.dart';\n\nfinal client = await TestClient.create(buildApp());\n\nfinal res = await client.get('/hello');\nexpect(res.statusCode, 200);\nexpect(res.json['msg'], 'hi');\n\nawait client.close();`,
        },
        { kind: "h3", text: "Padrão setUp / tearDown", id: "test-setup" },
        {
          kind: "code",
          code: `import 'package:darto_test/darto_test.dart';\nimport 'package:test/test.dart';\n\nvoid main() {\n  late TestClient client;\n\n  setUp(() async => client = await TestClient.create(buildApp()));\n  tearDown(() => client.close());\n\n  test('GET /hello retorna 200', () async {\n    final res = await client.get('/hello');\n    expect(res.statusCode, 200);\n    expect(res.json['msg'], 'hi');\n  });\n\n  test('POST /users cria usuário', () async {\n    final res = await client.post('/users', json: {'name': 'Alice'});\n    expect(res.statusCode, 201);\n    expect(res.json['name'], 'Alice');\n  });\n}`,
        },
        { kind: "h3", text: "json: vs body:", id: "test-json-body" },
        {
          kind: "p",
          text: "json: aceita Map/List, codifica com jsonEncode e define Content-Type: application/json automaticamente. body: envia o valor cru — String é escrita diretamente, List<int> é enviado como bytes. Use json: para APIs (o caso comum), body: quando precisar controlar o formato do payload.",
        },
        {
          kind: "code",
          code: `// json: → codifica + Content-Type: application/json\nclient.post('/users', json: {'name': 'Alice'});\n\n// body: → String crua (sem Content-Type)\nclient.post('/login', body: 'username=alice&password=s3cret',\n  headers: {'content-type': 'application/x-www-form-urlencoded'});\n\n// body: → bytes crus\nclient.post('/upload', body: imageBytes);`,
        },
        { kind: "h3", text: "API TestClient", id: "test-client-api" },
        {
          kind: "table",
          headers: ["Membro", "Descrição"],
          rows: [
            [
              "TestClient.create(app)",
              "Sobe o app numa porta de loopback livre; retorna um client",
            ],
            ["client.get / head / options(path, {headers})", "Requisição sem body"],
            [
              "client.post / put / patch / delete(path, {headers, body, json})",
              "Requisição com body opcional",
            ],
            ["client.request(method, path, {...})", "Requisição genérica"],
            ["client.port", "A porta efêmera vinculada"],
            ["client.close()", "Para o app e fecha o client"],
          ],
        },
        { kind: "h3", text: "API TestResponse", id: "test-response-api" },
        {
          kind: "table",
          headers: ["Membro", "Descrição"],
          rows: [
            ["res.statusCode", "Código de status HTTP"],
            ["res.body", "Body da resposta como texto UTF-8"],
            ["res.json", "Body parseado como JSON (null quando vazio)"],
            ["res.header(name)", "Valor do header (case-insensitive)"],
            ["res.headers", "Todos os headers como Map<String, String>"],
            ["res.cookie(name) / res.cookies", "Busca no Set-Cookie / lista completa"],
            ["res.isOk", "true para status 2xx"],
          ],
        },
      ],
    ),
  },
  {
    id: "plugin-logger",
    group: "plugins",
    title: bi("darto_logger", "darto_logger"),
    blocks: bi(
      [
        {
          kind: "links",
          links: [
            { label: "pub.dev", href: "https://pub.dev/packages/darto_logger" },
            {
              label: "GitHub",
              href: "https://github.com/evandersondev/darto/tree/main/darto_logger",
            },
          ],
        },
        {
          kind: "p",
          text: "Structured logging — JSON or pretty output, levels, bound fields, and a request-logging middleware with request-id correlation.",
        },
        { kind: "h3", text: "Install", id: "logger-install" },
        { kind: "code", lang: "yaml", code: `dependencies:\n  darto_logger: ^1.0.0` },
        { kind: "h3", text: "Usage", id: "logger-usage" },
        {
          kind: "code",
          code: `import 'package:darto/request_id.dart';\nimport 'package:darto_logger/darto_logger.dart';\n\nfinal log = Logger();\n\napp.use(requestId());        // adds X-Request-Id\napp.use(requestLogger(log)); // logs each request with that id\n\napp.get('/', [], (c) {\n  log.info('home hit', {'q': c.req.query('q')});\n  return c.ok({'ok': true});\n});`,
        },
        { kind: "h3", text: "Child loggers", id: "logger-child" },
        {
          kind: "p",
          text: "child() returns a new Logger with fields bound to every subsequent message — useful for adding context (request-id, user-id, service name) once instead of repeating it.",
        },
        {
          kind: "code",
          code: `final reqLog = log.child({'requestId': c.req.header('x-request-id')});\nreqLog.info('processing order', {'orderId': 42});\n// → {level: info, msg: "processing order", requestId: "…", orderId: 42}`,
        },
        { kind: "h3", text: "API", id: "logger-api" },
        {
          kind: "table",
          headers: ["Symbol", "Description"],
          rows: [
            [
              "Logger({minLevel, pretty, output})",
              "Creates a logger; pretty=true for human-readable output",
            ],
            [
              "log.debug / info / warn / error(msg, [fields])",
              "Log at the given level with optional fields",
            ],
            ["log.child(fields)", "Returns a new Logger with bound fields added to every message"],
            ["LogLevel.debug / info / warn / error", "Enum — messages below minLevel are dropped"],
            [
              "requestLogger(logger)",
              "Middleware — logs method, path, status, duration per request",
            ],
          ],
        },
      ],
      [
        {
          kind: "links",
          links: [
            { label: "pub.dev", href: "https://pub.dev/packages/darto_logger" },
            {
              label: "GitHub",
              href: "https://github.com/evandersondev/darto/tree/main/darto_logger",
            },
          ],
        },
        {
          kind: "p",
          text: "Logging estruturado — saída JSON ou pretty, níveis, campos fixados e um middleware de log de requisições com correlação por request-id.",
        },
        { kind: "h3", text: "Instalação", id: "logger-install" },
        { kind: "code", lang: "yaml", code: `dependencies:\n  darto_logger: ^1.0.0` },
        { kind: "h3", text: "Uso", id: "logger-usage" },
        {
          kind: "code",
          code: `import 'package:darto/request_id.dart';\nimport 'package:darto_logger/darto_logger.dart';\n\nfinal log = Logger();\n\napp.use(requestId());        // adiciona X-Request-Id\napp.use(requestLogger(log)); // loga cada requisição com esse id\n\napp.get('/', [], (c) {\n  log.info('home hit', {'q': c.req.query('q')});\n  return c.ok({'ok': true});\n});`,
        },
        { kind: "h3", text: "Child loggers", id: "logger-child" },
        {
          kind: "p",
          text: "child() devolve um novo Logger com campos fixados em todas as mensagens seguintes — útil para adicionar contexto (request-id, user-id, nome do serviço) uma vez só.",
        },
        {
          kind: "code",
          code: `final reqLog = log.child({'requestId': c.req.header('x-request-id')});\nreqLog.info('processando pedido', {'orderId': 42});\n// → {level: info, msg: "processando pedido", requestId: "…", orderId: 42}`,
        },
        { kind: "h3", text: "API", id: "logger-api" },
        {
          kind: "table",
          headers: ["Símbolo", "Descrição"],
          rows: [
            [
              "Logger({minLevel, pretty, output})",
              "Cria um logger; pretty=true para saída legível por humanos",
            ],
            [
              "log.debug / info / warn / error(msg, [fields])",
              "Loga no nível dado com campos opcionais",
            ],
            [
              "log.child(fields)",
              "Devolve um novo Logger com campos fixados em todas as mensagens",
            ],
            [
              "LogLevel.debug / info / warn / error",
              "Enum — mensagens abaixo de minLevel são descartadas",
            ],
            [
              "requestLogger(logger)",
              "Middleware — loga método, path, status e duração por request",
            ],
          ],
        },
      ],
    ),
  },
  {
    id: "plugin-auth",
    group: "plugins",
    title: bi("darto_auth", "darto_auth"),
    blocks: bi(
      [
        {
          kind: "links",
          links: [
            { label: "pub.dev", href: "https://pub.dev/packages/darto_auth" },
            {
              label: "GitHub",
              href: "https://github.com/evandersondev/darto/tree/main/darto_auth",
            },
          ],
        },
        {
          kind: "p",
          text: "Authentication — password hashing (PBKDF2-HMAC-SHA256, no native deps) and session-based auth guards built on Darto's session middleware.",
        },
        { kind: "h3", text: "Install", id: "auth-install" },
        { kind: "code", lang: "yaml", code: `dependencies:\n  darto_auth: ^1.0.0` },
        { kind: "h3", text: "Password hashing", id: "auth-password" },
        {
          kind: "code",
          code: `import 'package:darto_auth/darto_auth.dart';\n\nfinal hash = hashPassword('s3cret');         // store this\nfinal ok   = verifyPassword('s3cret', hash); // true (constant-time)`,
        },
        { kind: "h3", text: "Session auth", id: "auth-session" },
        {
          kind: "code",
          code: `import 'package:darto/session.dart';\nimport 'package:darto_auth/darto_auth.dart';\n\napp.use(sessionMiddleware(secret: env.sessionSecret));\n\napp.post('/login', [], (c) async {\n  final body = await c.req.json();\n  final user = await users.findByEmail(body['email']);\n  if (user == null || !verifyPassword(body['password'], user.hash)) {\n    return c.unauthorized({'error': 'invalid credentials'});\n  }\n  await signIn(c, {'id': user.id});\n  return c.ok({'ok': true});\n});\n\napp.get('/me', [authGuard()], (c) => c.ok(authUser(c)));`,
        },
        {
          kind: "table",
          headers: ["Symbol", "Description"],
          rows: [
            ["hashPassword / verifyPassword", "PBKDF2 hash & constant-time verify"],
            ["PasswordHasher({iterations, saltLength})", "Configurable hasher"],
            ["signIn(c, user) / signOut(c)", "Authenticate / clear the session"],
            ["authUser(c)", "The session user, or null"],
            [
              "authGuard({onUnauthorized})",
              "Middleware — 401 when unauthenticated; sets c.user otherwise",
            ],
          ],
        },
        { kind: "h3", text: "OAuth 2.0 / OpenID Connect", id: "auth-oauth" },
        {
          kind: "p",
          text: "OAuthProvider runs the Authorization-Code flow with PKCE S256 + randomised state (CSRF). Factories for Google (OIDC) and GitHub. provider.attach(app, prefix, onSignIn: ...) registers both /start and /callback routes in one call.",
        },
        {
          kind: "code",
          code: `import 'package:darto/session.dart';\nimport 'package:darto_auth/darto_auth.dart';\n\nfinal google = await OAuthProvider.google(\n  clientId: env.googleClientId,\n  clientSecret: env.googleClientSecret,\n  redirectUri: 'http://localhost:3000/auth/google/callback',\n);\n\napp.use(sessionMiddleware(secret: env.sessionSecret));\n\ngoogle.attach(app, '/auth/google', onSignIn: (c, user) async {\n  await signIn(c, {'id': user.id, 'email': user.email, 'name': user.name});\n  return c.redirect('/');\n});`,
        },
        {
          kind: "table",
          headers: ["Symbol", "Description"],
          rows: [
            ["OAuthProvider(...)", "Generic OAuth2 provider"],
            [
              "OAuthProvider.oidc({issuer, ...})",
              "OIDC discovery from /.well-known/openid-configuration",
            ],
            ["OAuthProvider.google({...}) / .github({...})", "Pre-configured factories"],
            [
              "provider.attach(app, prefix, {onSignIn, failureRedirect})",
              "Register /start + /callback in one call",
            ],
            ["OAuthUser", "Normalised (id, email, name, picture, raw) profile"],
            ["pkceVerifier() / pkceChallenge(v)", "PKCE helpers (S256)"],
          ],
        },
        {
          kind: "callout",
          variant: "tip",
          text: "id_token claims are decoded but not verified against the issuer's JWKS — authenticity comes from TLS to the token endpoint. JWKS verification is on the roadmap as opt-in.",
        },
      ],
      [
        {
          kind: "links",
          links: [
            { label: "pub.dev", href: "https://pub.dev/packages/darto_auth" },
            {
              label: "GitHub",
              href: "https://github.com/evandersondev/darto/tree/main/darto_auth",
            },
          ],
        },
        {
          kind: "p",
          text: "Autenticação — hashing de senha (PBKDF2-HMAC-SHA256, sem dep nativa) e guards de auth por sessão sobre o session middleware do Darto.",
        },
        { kind: "h3", text: "Instalação", id: "auth-install" },
        { kind: "code", lang: "yaml", code: `dependencies:\n  darto_auth: ^1.0.0` },
        { kind: "h3", text: "Hashing de senha", id: "auth-password" },
        {
          kind: "code",
          code: `import 'package:darto_auth/darto_auth.dart';\n\nfinal hash = hashPassword('s3cret');         // guarde isto\nfinal ok   = verifyPassword('s3cret', hash); // true (tempo constante)`,
        },
        { kind: "h3", text: "Auth por sessão", id: "auth-session" },
        {
          kind: "code",
          code: `import 'package:darto/session.dart';\nimport 'package:darto_auth/darto_auth.dart';\n\napp.use(sessionMiddleware(secret: env.sessionSecret));\n\napp.post('/login', [], (c) async {\n  final body = await c.req.json();\n  final user = await users.findByEmail(body['email']);\n  if (user == null || !verifyPassword(body['password'], user.hash)) {\n    return c.unauthorized({'error': 'invalid credentials'});\n  }\n  await signIn(c, {'id': user.id});\n  return c.ok({'ok': true});\n});\n\napp.get('/me', [authGuard()], (c) => c.ok(authUser(c)));`,
        },
        {
          kind: "table",
          headers: ["Símbolo", "Descrição"],
          rows: [
            ["hashPassword / verifyPassword", "Hash PBKDF2 & verificação em tempo constante"],
            ["PasswordHasher({iterations, saltLength})", "Hasher configurável"],
            ["signIn(c, user) / signOut(c)", "Autentica / limpa a sessão"],
            ["authUser(c)", "O usuário da sessão, ou null"],
            [
              "authGuard({onUnauthorized})",
              "Middleware — 401 se não autenticado; senão define c.user",
            ],
          ],
        },
        { kind: "h3", text: "OAuth 2.0 / OpenID Connect", id: "auth-oauth" },
        {
          kind: "p",
          text: "O OAuthProvider implementa o Authorization-Code flow com PKCE S256 + state aleatório (CSRF). Factories para Google (OIDC) e GitHub. provider.attach(app, prefix, onSignIn: ...) registra /start e /callback em uma chamada.",
        },
        {
          kind: "code",
          code: `import 'package:darto/session.dart';\nimport 'package:darto_auth/darto_auth.dart';\n\nfinal google = await OAuthProvider.google(\n  clientId: env.googleClientId,\n  clientSecret: env.googleClientSecret,\n  redirectUri: 'http://localhost:3000/auth/google/callback',\n);\n\napp.use(sessionMiddleware(secret: env.sessionSecret));\n\ngoogle.attach(app, '/auth/google', onSignIn: (c, user) async {\n  await signIn(c, {'id': user.id, 'email': user.email, 'name': user.name});\n  return c.redirect('/');\n});`,
        },
        {
          kind: "table",
          headers: ["Símbolo", "Descrição"],
          rows: [
            ["OAuthProvider(...)", "Provider OAuth2 genérico"],
            [
              "OAuthProvider.oidc({issuer, ...})",
              "Discovery OIDC via /.well-known/openid-configuration",
            ],
            ["OAuthProvider.google({...}) / .github({...})", "Factories pré-configuradas"],
            [
              "provider.attach(app, prefix, {onSignIn, failureRedirect})",
              "Registra /start + /callback em uma chamada",
            ],
            ["OAuthUser", "Perfil normalizado (id, email, name, picture, raw)"],
            ["pkceVerifier() / pkceChallenge(v)", "Helpers de PKCE (S256)"],
          ],
        },
        {
          kind: "callout",
          variant: "tip",
          text: "Os claims do id_token são decodificados, não verificados contra o JWKS do issuer — a autenticidade vem do TLS até o token endpoint. Verificação JWKS fica no roadmap como opt-in.",
        },
      ],
    ),
  },
  {
    id: "plugin-di",
    group: "plugins",
    title: bi("darto_inject", "darto_inject"),
    blocks: bi(
      [
        {
          kind: "links",
          links: [
            { label: "pub.dev", href: "https://pub.dev/packages/darto_inject" },
            {
              label: "GitHub",
              href: "https://github.com/evandersondev/darto/tree/main/darto_inject",
            },
          ],
        },
        {
          kind: "p",
          text: "Typed dependency injection — Provider<T> factories with app- and request-scope, lifecycle hooks (onDispose), test overrides, and a built-in contextProvider. No build_runner, no decorators.",
        },
        { kind: "h3", text: "Install", id: "di-install" },
        { kind: "code", lang: "yaml", code: `dependencies:\n  darto_inject: ^1.0.0` },
        { kind: "h3", text: "Declare providers", id: "di-providers" },
        {
          kind: "code",
          code: `import 'package:darto_inject/darto_inject.dart';\n\nfinal envProvider = Provider<Env>((di) => Env.fromFile('.env'));\n\nfinal dbProvider = Provider<Db>(\n  (di) => Db.connect(di.read(envProvider).dbUrl),\n  onDispose: (db) => db.close(),\n);\n\nfinal userServiceProvider = Provider<UserService>(\n  (di) => UserService(di.read(dbProvider)),\n);`,
        },
        { kind: "h3", text: "Install on the app", id: "di-install-app" },
        {
          kind: "code",
          code: `final di = Di(providers: [envProvider, dbProvider, userServiceProvider]);\nawait di.warmup(); // eagerly build app-scope singletons\n\nfinal app = Darto()..use(di.middleware());\n\napp.get('/users', [], (c) {\n  final svc = c.read(userServiceProvider);\n  return c.ok(svc.list());\n});\n\napp.listen(3000);\nawait di.dispose(); // runs every onDispose in reverse order`,
        },
        { kind: "h3", text: "Request scope + contextProvider", id: "di-request" },
        {
          kind: "p",
          text: "Mark a provider with scope: Scope.request and read contextProvider inside it to derive per-request values without leaking the Context into your services.",
        },
        {
          kind: "code",
          code: `final currentUserProvider = AsyncProvider<User?>(\n  (di) async {\n    final c = di.read(contextProvider);\n    final token = c.req.header('authorization')?.replaceFirst('Bearer ', '');\n    return token == null ? null : await di.read(userServiceProvider).fromToken(token);\n  },\n  scope: Scope.request,\n);\n\napp.get('/me', [], (c) async => c.ok(await c.readAsync(currentUserProvider)));`,
        },
        { kind: "h3", text: "Test overrides", id: "di-overrides" },
        {
          kind: "code",
          code: `final di = Di(providers: [userServiceProvider])\n  ..override(userServiceProvider, (di) => FakeUserService());`,
        },
        { kind: "h3", text: "Feature", id: "di-feature" },
        {
          kind: "code",
          code: `final userFeature = Feature(\n  providers: [userServiceProvider],\n  routes: (r) {\n    r.get('/users', [], listUsers);\n    r.post('/users', [authGuard()], createUser);\n  },\n);\n\napp.install('/api', userFeature);`,
        },
        { kind: "h3", text: "CLI scaffolds", id: "di-cli" },
        {
          kind: "code",
          lang: "sh",
          code: `darto gen feature users    # lib/features/users/users_feature.dart\ndarto gen service mailer   # lib/services/mailer_service.dart`,
        },
        {
          kind: "table",
          headers: ["Symbol", "Description"],
          rows: [
            ["Provider<T>(factory, {scope, onDispose})", "Synchronous typed factory"],
            ["AsyncProvider<T>(factory, {scope, onDispose})", "Asynchronous typed factory"],
            ["Scope.app / Scope.request", "Lifetime of the cached instance"],
            ["Di({providers, asyncProviders})", "Container — caches, overrides, middleware"],
            ["Di.warmup() / dispose()", "Eager build / reverse-order cleanup"],
            ["Di.override(p, factory)", "Replace a factory (tests)"],
            ["c.read(p) / c.readAsync(p)", "Resolve a provider on the current request"],
            ["contextProvider", "Built-in Provider<Context> for request-scope factories"],
            ["Feature({providers, routes})", "Providers + routes bundle"],
            ["app.install([prefix], feature)", "Mount a feature, optionally prefixed"],
          ],
        },
      ],
      [
        {
          kind: "links",
          links: [
            { label: "pub.dev", href: "https://pub.dev/packages/darto_inject" },
            {
              label: "GitHub",
              href: "https://github.com/evandersondev/darto/tree/main/darto_inject",
            },
          ],
        },
        {
          kind: "p",
          text: "Injeção de dependência tipada — fábricas Provider<T> com escopo app/request, lifecycle (onDispose), override para testes e um contextProvider embutido. Sem build_runner, sem decorators.",
        },
        { kind: "h3", text: "Instalação", id: "di-install" },
        { kind: "code", lang: "yaml", code: `dependencies:\n  darto_inject: ^1.0.0` },
        { kind: "h3", text: "Declarar providers", id: "di-providers" },
        {
          kind: "code",
          code: `import 'package:darto_inject/darto_inject.dart';\n\nfinal envProvider = Provider<Env>((di) => Env.fromFile('.env'));\n\nfinal dbProvider = Provider<Db>(\n  (di) => Db.connect(di.read(envProvider).dbUrl),\n  onDispose: (db) => db.close(),\n);\n\nfinal userServiceProvider = Provider<UserService>(\n  (di) => UserService(di.read(dbProvider)),\n);`,
        },
        { kind: "h3", text: "Instalar no app", id: "di-install-app" },
        {
          kind: "code",
          code: `final di = Di(providers: [envProvider, dbProvider, userServiceProvider]);\nawait di.warmup(); // constrói os singletons de app-scope antes do primeiro request\n\nfinal app = Darto()..use(di.middleware());\n\napp.get('/users', [], (c) {\n  final svc = c.read(userServiceProvider);\n  return c.ok(svc.list());\n});\n\napp.listen(3000);\nawait di.dispose(); // dispara onDispose em ordem reversa`,
        },
        { kind: "h3", text: "Escopo por request + contextProvider", id: "di-request" },
        {
          kind: "p",
          text: "Marque um provider com scope: Scope.request e leia contextProvider dentro dele para derivar valores por requisição sem vazar o Context para os seus serviços.",
        },
        {
          kind: "code",
          code: `final currentUserProvider = AsyncProvider<User?>(\n  (di) async {\n    final c = di.read(contextProvider);\n    final token = c.req.header('authorization')?.replaceFirst('Bearer ', '');\n    return token == null ? null : await di.read(userServiceProvider).fromToken(token);\n  },\n  scope: Scope.request,\n);\n\napp.get('/me', [], (c) async => c.ok(await c.readAsync(currentUserProvider)));`,
        },
        { kind: "h3", text: "Override em testes", id: "di-overrides" },
        {
          kind: "code",
          code: `final di = Di(providers: [userServiceProvider])\n  ..override(userServiceProvider, (di) => FakeUserService());`,
        },
        { kind: "h3", text: "Feature", id: "di-feature" },
        {
          kind: "code",
          code: `final userFeature = Feature(\n  providers: [userServiceProvider],\n  routes: (r) {\n    r.get('/users', [], listUsers);\n    r.post('/users', [authGuard()], createUser);\n  },\n);\n\napp.install('/api', userFeature);`,
        },
        { kind: "h3", text: "Scaffolds da CLI", id: "di-cli" },
        {
          kind: "code",
          lang: "sh",
          code: `darto gen feature users    # lib/features/users/users_feature.dart\ndarto gen service mailer   # lib/services/mailer_service.dart`,
        },
        {
          kind: "table",
          headers: ["Símbolo", "Descrição"],
          rows: [
            ["Provider<T>(factory, {scope, onDispose})", "Fábrica tipada síncrona"],
            ["AsyncProvider<T>(factory, {scope, onDispose})", "Fábrica tipada assíncrona"],
            ["Scope.app / Scope.request", "Tempo de vida da instância em cache"],
            ["Di({providers, asyncProviders})", "Container — caches, overrides, middleware"],
            ["Di.warmup() / dispose()", "Build antecipado / cleanup em ordem reversa"],
            ["Di.override(p, factory)", "Substitui uma fábrica (testes)"],
            ["c.read(p) / c.readAsync(p)", "Resolve um provider na requisição atual"],
            ["contextProvider", "Provider<Context> embutido para fábricas de request"],
            ["Feature({providers, routes})", "Pacote de providers + rotas"],
            ["app.install([prefix], feature)", "Monta uma feature, opcionalmente com prefixo"],
          ],
        },
      ],
    ),
  },
  {
    id: "plugin-cache",
    group: "plugins",
    title: bi("darto_cache", "darto_cache"),
    blocks: bi(
      [
        {
          kind: "links",
          links: [
            { label: "pub.dev", href: "https://pub.dev/packages/darto_cache" },
            {
              label: "GitHub",
              href: "https://github.com/evandersondev/darto/tree/main/darto_cache",
            },
          ],
        },
        {
          kind: "p",
          text: "Cache primitives — a tiny Cache interface with a zero-dep MemoryCache (LRU + TTL) and a RedisCache adapter for shared / distributed caching.",
        },
        { kind: "h3", text: "Install", id: "cache-install" },
        { kind: "code", lang: "yaml", code: `dependencies:\n  darto_cache: ^1.0.0` },
        { kind: "h3", text: "In-process: MemoryCache", id: "cache-memory" },
        {
          kind: "code",
          code: `import 'package:darto_cache/darto_cache.dart';\n\nfinal cache = MemoryCache(maxEntries: 1024);\n\nawait cache.set('user:42', {'name': 'Eva'}, ttl: Duration(minutes: 5));\nfinal user = await cache.get<Map<String, dynamic>>('user:42');`,
        },
        { kind: "h3", text: "Distributed: RedisCache", id: "cache-redis" },
        {
          kind: "code",
          code: `final cache = await RedisCache.connect(\n  host: 'localhost',\n  port: 6379,\n  prefix: 'app:',\n);\n\nawait cache.set('user:42', {'name': 'Eva'}, ttl: Duration(minutes: 5));\nfinal user = await cache.get<Map<String, dynamic>>('user:42');\nawait cache.close();`,
        },
        { kind: "h3", text: "Read-through with remember", id: "cache-remember" },
        {
          kind: "p",
          text: "The call site you want 90% of the time: builder runs on miss, the value is stored with ttl, then returned. null is not cached.",
        },
        {
          kind: "code",
          code: `final user = await cache.remember<Map<String, dynamic>>(\n  'user:\$id',\n  ttl: Duration(minutes: 5),\n  builder: () => db.users.findById(id),\n);`,
        },
        { kind: "h3", text: "Wiring with darto_inject", id: "cache-di" },
        {
          kind: "code",
          code: `final cacheProvider = AsyncProvider<Cache>(\n  (di) => RedisCache.connect(\n    host: di.read(envProvider).redisHost,\n    prefix: 'app:',\n  ),\n  onDispose: (c) => c.close(),\n);\n\napp.get('/users/:id', [], (c) async {\n  final cache = await c.readAsync(cacheProvider);\n  final user = await cache.remember(\n    'user:\${c.req.param('id')}',\n    ttl: Duration(minutes: 5),\n    builder: () => userService.findById(c.req.param('id')!),\n  );\n  return c.ok(user);\n});`,
        },
        {
          kind: "table",
          headers: ["Symbol", "Description"],
          rows: [
            ["Cache (interface)", "get / set / delete / has / clear / close"],
            ["cache.remember(key, {ttl, builder})", "Read-through helper"],
            ["MemoryCache({maxEntries})", "In-process; LRU when maxEntries is set"],
            ["RedisCache.connect({host, port, prefix})", "Distributed cache over Redis"],
            ["prefix (Redis)", "Namespaces the keys; clear() only drops keys under prefix"],
          ],
        },
      ],
      [
        {
          kind: "links",
          links: [
            { label: "pub.dev", href: "https://pub.dev/packages/darto_cache" },
            {
              label: "GitHub",
              href: "https://github.com/evandersondev/darto/tree/main/darto_cache",
            },
          ],
        },
        {
          kind: "p",
          text: "Primitivos de cache — uma interface Cache mínima com MemoryCache zero-dep (LRU + TTL) e o adapter RedisCache para cache compartilhado/distribuído.",
        },
        { kind: "h3", text: "Instalação", id: "cache-install" },
        { kind: "code", lang: "yaml", code: `dependencies:\n  darto_cache: ^1.0.0` },
        { kind: "h3", text: "Em processo: MemoryCache", id: "cache-memory" },
        {
          kind: "code",
          code: `import 'package:darto_cache/darto_cache.dart';\n\nfinal cache = MemoryCache(maxEntries: 1024);\n\nawait cache.set('user:42', {'name': 'Eva'}, ttl: Duration(minutes: 5));\nfinal user = await cache.get<Map<String, dynamic>>('user:42');`,
        },
        { kind: "h3", text: "Distribuído: RedisCache", id: "cache-redis" },
        {
          kind: "code",
          code: `final cache = await RedisCache.connect(\n  host: 'localhost',\n  port: 6379,\n  prefix: 'app:',\n);\n\nawait cache.set('user:42', {'name': 'Eva'}, ttl: Duration(minutes: 5));\nfinal user = await cache.get<Map<String, dynamic>>('user:42');\nawait cache.close();`,
        },
        { kind: "h3", text: "Read-through com remember", id: "cache-remember" },
        {
          kind: "p",
          text: "É o call site que você quer 90% das vezes: o builder roda no miss, o valor vira cache com ttl e é devolvido. null não é cacheado.",
        },
        {
          kind: "code",
          code: `final user = await cache.remember<Map<String, dynamic>>(\n  'user:\$id',\n  ttl: Duration(minutes: 5),\n  builder: () => db.users.findById(id),\n);`,
        },
        { kind: "h3", text: "Integração com darto_inject", id: "cache-di" },
        {
          kind: "code",
          code: `final cacheProvider = AsyncProvider<Cache>(\n  (di) => RedisCache.connect(\n    host: di.read(envProvider).redisHost,\n    prefix: 'app:',\n  ),\n  onDispose: (c) => c.close(),\n);\n\napp.get('/users/:id', [], (c) async {\n  final cache = await c.readAsync(cacheProvider);\n  final user = await cache.remember(\n    'user:\${c.req.param('id')}',\n    ttl: Duration(minutes: 5),\n    builder: () => userService.findById(c.req.param('id')!),\n  );\n  return c.ok(user);\n});`,
        },
        {
          kind: "table",
          headers: ["Símbolo", "Descrição"],
          rows: [
            ["Cache (interface)", "get / set / delete / has / clear / close"],
            ["cache.remember(key, {ttl, builder})", "Helper read-through"],
            ["MemoryCache({maxEntries})", "Em processo; LRU quando maxEntries é setado"],
            ["RedisCache.connect({host, port, prefix})", "Cache distribuído sobre Redis"],
            ["prefix (Redis)", "Namespace de chaves; clear() só apaga sob o prefix"],
          ],
        },
      ],
    ),
  },
  {
    id: "plugin-rate-limit",
    group: "plugins",
    title: bi("darto_rate_limit", "darto_rate_limit"),
    blocks: bi(
      [
        {
          kind: "links",
          links: [
            { label: "pub.dev", href: "https://pub.dev/packages/darto_rate_limit" },
            {
              label: "GitHub",
              href: "https://github.com/evandersondev/darto/tree/main/darto_rate_limit",
            },
          ],
        },
        {
          kind: "p",
          text: "Distributed RateLimitStore for the core rateLimit() middleware. The in-process store is fine for one instance; this package adds a Redis-backed store so multiple replicas behind a load balancer share the same counter.",
        },
        { kind: "h3", text: "Install", id: "rl-install" },
        {
          kind: "code",
          lang: "yaml",
          code: `dependencies:\n  darto: ^1.2.0\n  darto_rate_limit: ^1.0.0`,
        },
        { kind: "h3", text: "Usage", id: "rl-usage" },
        {
          kind: "code",
          code: `import 'package:darto/darto.dart';\nimport 'package:darto/rate_limit.dart';\nimport 'package:darto_rate_limit/darto_rate_limit.dart';\n\nfinal store = await RedisRateLimitStore.connect(\n  host: 'localhost',\n  port: 6379,\n  prefix: 'rl:',\n);\n\napp.use(rateLimit(\n  max: 100,\n  window: Duration(minutes: 1),\n  store: store, // ← shared across instances\n));`,
        },
        { kind: "h3", text: "How it works", id: "rl-how" },
        {
          kind: "p",
          text: "Each hit runs a single Lua script — INCR + conditional PEXPIRE + PTTL — in one round-trip. INCR is atomic so counts never drift, and PEXPIRE only fires when a new window starts, so every instance agrees on the same resetAt.",
        },
        {
          kind: "table",
          headers: ["Symbol", "Description"],
          rows: [
            [
              "RedisRateLimitStore.connect({host, port, prefix})",
              "Opens a connection to a Redis server; the prefix namespaces keys.",
            ],
            ["store.hit(key, window)", "Records a hit; returns count + resetAt"],
            ["store.reset(key)", "Clears the counter for key"],
            ["store.close()", "Releases the Redis connection"],
          ],
        },
        { kind: "ref", to: "middleware-builtin", label: "See: core rateLimit() middleware" },
      ],
      [
        {
          kind: "links",
          links: [
            { label: "pub.dev", href: "https://pub.dev/packages/darto_rate_limit" },
            {
              label: "GitHub",
              href: "https://github.com/evandersondev/darto/tree/main/darto_rate_limit",
            },
          ],
        },
        {
          kind: "p",
          text: "RateLimitStore distribuído para o middleware rateLimit() do core. O store em processo é suficiente para uma instância; este pacote adiciona um store em Redis para que múltiplas réplicas atrás de um load balancer compartilhem o mesmo contador.",
        },
        { kind: "h3", text: "Instalação", id: "rl-install" },
        {
          kind: "code",
          lang: "yaml",
          code: `dependencies:\n  darto: ^1.2.0\n  darto_rate_limit: ^1.0.0`,
        },
        { kind: "h3", text: "Uso", id: "rl-usage" },
        {
          kind: "code",
          code: `import 'package:darto/darto.dart';\nimport 'package:darto/rate_limit.dart';\nimport 'package:darto_rate_limit/darto_rate_limit.dart';\n\nfinal store = await RedisRateLimitStore.connect(\n  host: 'localhost',\n  port: 6379,\n  prefix: 'rl:',\n);\n\napp.use(rateLimit(\n  max: 100,\n  window: Duration(minutes: 1),\n  store: store, // ← compartilhado entre instâncias\n));`,
        },
        { kind: "h3", text: "Como funciona", id: "rl-how" },
        {
          kind: "p",
          text: "Cada hit roda um único script Lua — INCR + PEXPIRE condicional + PTTL — em um round-trip. INCR é atômico, então o contador não se perde; PEXPIRE só dispara quando uma nova janela começa, e todas as instâncias concordam no mesmo resetAt.",
        },
        {
          kind: "table",
          headers: ["Símbolo", "Descrição"],
          rows: [
            [
              "RedisRateLimitStore.connect({host, port, prefix})",
              "Abre conexão com o Redis; o prefix faz namespacing das chaves.",
            ],
            ["store.hit(key, window)", "Registra um hit; devolve count + resetAt"],
            ["store.reset(key)", "Limpa o contador da chave"],
            ["store.close()", "Libera a conexão do Redis"],
          ],
        },
        { kind: "ref", to: "middleware-builtin", label: "Veja: middleware rateLimit() do core" },
      ],
    ),
  },
  {
    id: "plugin-mailer",
    group: "plugins",
    title: bi("darto_mailer", "darto_mailer"),
    blocks: bi(
      [
        {
          kind: "links",
          links: [
            { label: "pub.dev", href: "https://pub.dev/packages/darto_mailer" },
            {
              label: "GitHub",
              href: "https://github.com/evandersondev/darto/tree/main/darto_mailer",
            },
          ],
        },
        {
          kind: "p",
          text: "Email sending — a small Mailer API with an SMTP transport (pure-Dart) plus console and memory transports for development and tests.",
        },
        { kind: "h3", text: "Install", id: "mailer-install" },
        { kind: "code", lang: "yaml", code: `dependencies:\n  darto_mailer: ^1.0.0` },
        { kind: "h3", text: "Send via SMTP", id: "mailer-smtp" },
        {
          kind: "code",
          code: `import 'package:darto_mailer/darto_mailer.dart';\n\nfinal mailer = Mailer(\n  from: 'no-reply@example.com',\n  transport: SmtpTransport(\n    host: 'smtp.example.com',\n    port: 587,\n    username: env.smtpUser,\n    password: env.smtpPass,\n    security: SmtpSecurity.starttls, // none | ssl | starttls\n  ),\n);\n\nawait mailer.send(Message(\n  to: 'user@example.com',\n  subject: 'Welcome!',\n  text: 'Hello, welcome aboard.',\n  html: '<h1>Hello!</h1>',\n));`,
        },
        { kind: "h3", text: "Cc / bcc and attachments", id: "mailer-attachments" },
        {
          kind: "code",
          code: `await mailer.send(Message(\n  to: ['a@x.com', 'b@x.com'],\n  cc: 'manager@x.com',\n  replyTo: 'support@x.com',\n  subject: 'Report',\n  html: '<p>See attached.</p>',\n  attachments: [\n    Attachment.file('report.pdf'),\n    Attachment.bytes('logo.png', bytes, contentType: 'image/png'),\n  ],\n));`,
        },
        { kind: "h3", text: "Dev & test transports", id: "mailer-transports" },
        {
          kind: "code",
          code: `// Dev — prints a summary, sends nothing\nfinal mailer = Mailer(from: '…', transport: ConsoleTransport());\n\n// Tests — capture and assert\nfinal box = MemoryTransport();\nfinal mailer = Mailer(from: 'a@b.com', transport: box);\nawait mailer.send(Message(to: 'x@y.com', subject: 'Hi', text: '…'));\nexpect(box.sent.single.message.subject, 'Hi');`,
        },
        {
          kind: "callout",
          variant: "tip",
          text: "No template engine here — pass rendered html/text. Combine with darto_view (Mustache/Jinja) to render the body.",
        },
        {
          kind: "table",
          headers: ["Symbol", "Description"],
          rows: [
            ["Mailer({from, transport})", "Sends messages; injects the default from"],
            ["Message({to, cc, bcc, replyTo, subject, text, html, attachments})", "An email"],
            ["Attachment.file / .bytes / .string", "Attachment constructors"],
            ["SmtpTransport({host, port, username, password, security})", "SMTP delivery"],
            ["SmtpSecurity", "none / ssl / starttls"],
            ["ConsoleTransport / MemoryTransport", "Dev / test transports"],
          ],
        },
      ],
      [
        {
          kind: "links",
          links: [
            { label: "pub.dev", href: "https://pub.dev/packages/darto_mailer" },
            {
              label: "GitHub",
              href: "https://github.com/evandersondev/darto/tree/main/darto_mailer",
            },
          ],
        },
        {
          kind: "p",
          text: "Envio de e-mail — uma API Mailer enxuta com transport SMTP (pure-Dart) mais transports console e memory para desenvolvimento e testes.",
        },
        { kind: "h3", text: "Instalação", id: "mailer-install" },
        { kind: "code", lang: "yaml", code: `dependencies:\n  darto_mailer: ^1.0.0` },
        { kind: "h3", text: "Enviar via SMTP", id: "mailer-smtp" },
        {
          kind: "code",
          code: `import 'package:darto_mailer/darto_mailer.dart';\n\nfinal mailer = Mailer(\n  from: 'no-reply@example.com',\n  transport: SmtpTransport(\n    host: 'smtp.example.com',\n    port: 587,\n    username: env.smtpUser,\n    password: env.smtpPass,\n    security: SmtpSecurity.starttls, // none | ssl | starttls\n  ),\n);\n\nawait mailer.send(Message(\n  to: 'user@example.com',\n  subject: 'Bem-vindo!',\n  text: 'Olá, bem-vindo.',\n  html: '<h1>Olá!</h1>',\n));`,
        },
        { kind: "h3", text: "Cc / bcc e anexos", id: "mailer-attachments" },
        {
          kind: "code",
          code: `await mailer.send(Message(\n  to: ['a@x.com', 'b@x.com'],\n  cc: 'gerente@x.com',\n  replyTo: 'suporte@x.com',\n  subject: 'Relatório',\n  html: '<p>Segue em anexo.</p>',\n  attachments: [\n    Attachment.file('relatorio.pdf'),\n    Attachment.bytes('logo.png', bytes, contentType: 'image/png'),\n  ],\n));`,
        },
        { kind: "h3", text: "Transports de dev & teste", id: "mailer-transports" },
        {
          kind: "code",
          code: `// Dev — imprime um resumo, não envia nada\nfinal mailer = Mailer(from: '…', transport: ConsoleTransport());\n\n// Teste — captura e faz assert\nfinal box = MemoryTransport();\nfinal mailer = Mailer(from: 'a@b.com', transport: box);\nawait mailer.send(Message(to: 'x@y.com', subject: 'Oi', text: '…'));\nexpect(box.sent.single.message.subject, 'Oi');`,
        },
        {
          kind: "callout",
          variant: "tip",
          text: "Sem engine de template aqui — passe html/text já renderizados. Combine com darto_view (Mustache/Jinja) para renderizar o corpo.",
        },
        {
          kind: "table",
          headers: ["Símbolo", "Descrição"],
          rows: [
            ["Mailer({from, transport})", "Envia mensagens; injeta o from padrão"],
            ["Message({to, cc, bcc, replyTo, subject, text, html, attachments})", "Um e-mail"],
            ["Attachment.file / .bytes / .string", "Construtores de anexo"],
            ["SmtpTransport({host, port, username, password, security})", "Entrega SMTP"],
            ["SmtpSecurity", "none / ssl / starttls"],
            ["ConsoleTransport / MemoryTransport", "Transports de dev / teste"],
          ],
        },
      ],
    ),
  },
  {
    id: "plugin-jobs",
    group: "plugins",
    title: bi("darto_jobs", "darto_jobs"),
    blocks: bi(
      [
        {
          kind: "links",
          links: [
            { label: "pub.dev", href: "https://pub.dev/packages/darto_jobs" },
            {
              label: "GitHub",
              href: "https://github.com/evandersondev/darto/tree/main/darto_jobs",
            },
          ],
        },
        {
          kind: "p",
          text: "Background job queue — enqueue work, process it with retries and backoff, backed by an in-memory or Redis store (at-least-once).",
        },
        { kind: "h3", text: "Install", id: "jobs-install" },
        { kind: "code", lang: "yaml", code: `dependencies:\n  darto_jobs: ^1.0.0` },
        { kind: "h3", text: "Define, enqueue, work", id: "jobs-basics" },
        {
          kind: "code",
          code: `import 'package:darto_jobs/darto_jobs.dart';\n\nfinal queue = JobQueue(store: MemoryJobStore()); // or RedisJobStore.connect(...)\n\nqueue.handle('send-welcome', (job) async {\n  await mailer.send(Message(to: job.data['email'], subject: 'Welcome'));\n});\n\nawait queue.add('send-welcome', {'email': 'user@x.com'});\nawait queue.add('report', {'id': 42}, delay: Duration(minutes: 5));\n\nfinal worker = queue.work(concurrency: 4);\n// … on shutdown:\nawait worker.stop(); // drains in-flight jobs`,
        },
        { kind: "h3", text: "Retries, backoff & dead-letter", id: "jobs-retry" },
        {
          kind: "code",
          code: `queue.handle('charge', (job) async {\n  await payments.charge(job.data['orderId']);\n}, maxAttempts: 5, backoff: (attempt) => Duration(seconds: 2 * attempt));\n\nqueue.onFailed((job, error, stack) {\n  log.error('job \${job.name} gave up', error, stack);\n});\n\nfinal dead = await queue.store.deadLetter();`,
        },
        {
          kind: "callout",
          variant: "warning",
          text: "Delivery is at-least-once — a job may run more than once if a worker crashes mid-process. Make handlers idempotent.",
        },
        { kind: "h3", text: "Durable & distributed (Redis)", id: "jobs-redis" },
        {
          kind: "p",
          text: "RedisJobStore persists jobs across restarts and lets multiple worker processes share one queue. reserve runs a Lua script (promote due → pop → lease) atomically; a periodic sweep re-queues jobs from crashed workers.",
        },
        {
          kind: "code",
          code: `final queue = JobQueue(\n  store: await RedisJobStore.connect(host: 'localhost', port: 6379),\n);`,
        },
        {
          kind: "table",
          headers: ["Symbol", "Description"],
          rows: [
            ["JobQueue({store})", "add / handle / work / onFailed / close"],
            ["queue.add(name, data, {delay, scheduledAt, maxAttempts})", "Enqueue a job"],
            ["queue.handle(name, handler, {maxAttempts, backoff})", "Register a handler"],
            ["queue.work({concurrency, pollInterval, lease})", "Start a Worker"],
            ["Worker.stop()", "Drain in-flight jobs and stop"],
            ["MemoryJobStore / RedisJobStore", "In-process / durable, shared store"],
            ["JobStats", "ready / delayed / active / dead counts"],
          ],
        },
      ],
      [
        {
          kind: "links",
          links: [
            { label: "pub.dev", href: "https://pub.dev/packages/darto_jobs" },
            {
              label: "GitHub",
              href: "https://github.com/evandersondev/darto/tree/main/darto_jobs",
            },
          ],
        },
        {
          kind: "p",
          text: "Fila de jobs em background — enfileira trabalho, processa com retries e backoff, sobre um store em memória ou Redis (at-least-once).",
        },
        { kind: "h3", text: "Instalação", id: "jobs-install" },
        { kind: "code", lang: "yaml", code: `dependencies:\n  darto_jobs: ^1.0.0` },
        { kind: "h3", text: "Definir, enfileirar, processar", id: "jobs-basics" },
        {
          kind: "code",
          code: `import 'package:darto_jobs/darto_jobs.dart';\n\nfinal queue = JobQueue(store: MemoryJobStore()); // ou RedisJobStore.connect(...)\n\nqueue.handle('send-welcome', (job) async {\n  await mailer.send(Message(to: job.data['email'], subject: 'Welcome'));\n});\n\nawait queue.add('send-welcome', {'email': 'user@x.com'});\nawait queue.add('report', {'id': 42}, delay: Duration(minutes: 5));\n\nfinal worker = queue.work(concurrency: 4);\n// … no shutdown:\nawait worker.stop(); // drena os jobs em andamento`,
        },
        { kind: "h3", text: "Retries, backoff & dead-letter", id: "jobs-retry" },
        {
          kind: "code",
          code: `queue.handle('charge', (job) async {\n  await payments.charge(job.data['orderId']);\n}, maxAttempts: 5, backoff: (attempt) => Duration(seconds: 2 * attempt));\n\nqueue.onFailed((job, error, stack) {\n  log.error('job \${job.name} desistiu', error, stack);\n});\n\nfinal dead = await queue.store.deadLetter();`,
        },
        {
          kind: "callout",
          variant: "warning",
          text: "Entrega é at-least-once — um job pode rodar mais de uma vez se um worker crashar no meio. Faça os handlers idempotentes.",
        },
        { kind: "h3", text: "Durável & distribuído (Redis)", id: "jobs-redis" },
        {
          kind: "p",
          text: "O RedisJobStore persiste jobs entre restarts e deixa múltiplos processos worker compartilharem a mesma fila. O reserve roda um script Lua (promove vencidos → pop → lease) atomicamente; um sweep periódico re-enfileira jobs de workers que crasharam.",
        },
        {
          kind: "code",
          code: `final queue = JobQueue(\n  store: await RedisJobStore.connect(host: 'localhost', port: 6379),\n);`,
        },
        {
          kind: "table",
          headers: ["Símbolo", "Descrição"],
          rows: [
            ["JobQueue({store})", "add / handle / work / onFailed / close"],
            ["queue.add(name, data, {delay, scheduledAt, maxAttempts})", "Enfileira um job"],
            ["queue.handle(name, handler, {maxAttempts, backoff})", "Registra um handler"],
            ["queue.work({concurrency, pollInterval, lease})", "Inicia um Worker"],
            ["Worker.stop()", "Drena os jobs em andamento e para"],
            ["MemoryJobStore / RedisJobStore", "Store em processo / durável e compartilhado"],
            ["JobStats", "Contagens ready / delayed / active / dead"],
          ],
        },
      ],
    ),
  },
  {
    id: "plugin-ws",
    group: "plugins",
    title: bi("darto_ws", "darto_ws"),
    blocks: bi(
      [
        {
          kind: "links",
          links: [
            { label: "pub.dev", href: "https://pub.dev/packages/darto_ws" },
            { label: "GitHub", href: "https://github.com/evandersondev/darto/tree/main/darto_ws" },
          ],
        },
        {
          kind: "p",
          text: "WebSocket support — same port, route-integrated. Middleware (auth, params, state) runs before the upgrade. v1.1 adds rooms / broadcast (WsHub) and a Redis adapter for multi-instance fanout.",
        },
        { kind: "h3", text: "Install", id: "ws-install" },
        { kind: "code", lang: "yaml", code: `dependencies:\n  darto_ws: ^1.1.0` },
        { kind: "ref", to: "websocket", label: "Full guide: WebSocket" },
      ],
      [
        {
          kind: "links",
          links: [
            { label: "pub.dev", href: "https://pub.dev/packages/darto_ws" },
            { label: "GitHub", href: "https://github.com/evandersondev/darto/tree/main/darto_ws" },
          ],
        },
        {
          kind: "p",
          text: "Suporte a WebSocket — mesma porta, integrado às rotas. Middleware (auth, params, estado) roda antes do upgrade. A v1.1 adiciona rooms / broadcast (WsHub) e um adapter Redis para fanout multi-instância.",
        },
        { kind: "h3", text: "Instalação", id: "ws-install" },
        { kind: "code", lang: "yaml", code: `dependencies:\n  darto_ws: ^1.1.0` },
        { kind: "ref", to: "websocket", label: "Guia completo: WebSocket" },
      ],
    ),
  },
  {
    id: "plugin-view",
    group: "plugins",
    title: bi("darto_view", "darto_view"),
    blocks: bi(
      [
        {
          kind: "links",
          links: [
            { label: "pub.dev", href: "https://pub.dev/packages/darto_view" },
            {
              label: "GitHub",
              href: "https://github.com/evandersondev/darto/tree/main/darto_view",
            },
          ],
        },
        {
          kind: "p",
          text: "Pluggable template engine — ships with Mustache. Register once, then call c.render() in any handler.",
        },
        { kind: "h3", text: "Install", id: "view-install" },
        {
          kind: "code",
          lang: "yaml",
          code: `dependencies:\n  darto_view: ^1.0.1\n  mustache_template: ^2.0.0`,
        },
        { kind: "ref", to: "view-engine", label: "Full guide: View Engine" },
      ],
      [
        {
          kind: "links",
          links: [
            { label: "pub.dev", href: "https://pub.dev/packages/darto_view" },
            {
              label: "GitHub",
              href: "https://github.com/evandersondev/darto/tree/main/darto_view",
            },
          ],
        },
        {
          kind: "p",
          text: "Engine de templates plugável — vem com Mustache. Registre uma vez e use c.render() em qualquer handler.",
        },
        { kind: "h3", text: "Instalação", id: "view-install" },
        {
          kind: "code",
          lang: "yaml",
          code: `dependencies:\n  darto_view: ^1.0.1\n  mustache_template: ^2.0.0`,
        },
        { kind: "ref", to: "view-engine", label: "Guia completo: View Engine" },
      ],
    ),
  },
  {
    id: "plugin-static",
    group: "plugins",
    title: bi("darto_static", "darto_static"),
    blocks: bi(
      [
        {
          kind: "links",
          links: [
            { label: "pub.dev", href: "https://pub.dev/packages/darto_static" },
            {
              label: "GitHub",
              href: "https://github.com/evandersondev/darto/tree/main/darto_static",
            },
          ],
        },
        {
          kind: "p",
          text: "Static file serving middleware — ETag, 304, Range requests, optional gzip and Cache-Control, with built-in path-traversal protection.",
        },
        { kind: "h3", text: "Install", id: "static-install" },
        { kind: "code", lang: "yaml", code: `dependencies:\n  darto_static: ^1.0.1` },
        { kind: "h3", text: "Usage", id: "static-usage" },
        {
          kind: "code",
          code: `import 'package:darto_static/darto_static.dart';\n\napp.mount('/public/*', serveStatic('public'));\napp.mount('/assets/*', serveStatic('dist', urlPrefix: '/assets', maxAge: Duration(days: 7)));`,
        },
        { kind: "h3", text: "serveStatic options", id: "static-options" },
        {
          kind: "table",
          headers: ["Option", "Description"],
          rows: [
            ["dir (positional)", "Directory to serve files from (relative to cwd)"],
            [
              "urlPrefix",
              "URL prefix to strip — defaults to '/dir'. Set when the mount path differs from the folder name.",
            ],
            ["maxAge", "Sets Cache-Control: public, max-age=N. Omit to disable client caching."],
          ],
        },
        {
          kind: "callout",
          variant: "tip",
          text: "Built-in path-traversal protection, automatic MIME detection, and ETag / 304 / Range support. When a file isn't found it falls through to next(), so your other routes still match.",
        },
      ],
      [
        {
          kind: "links",
          links: [
            { label: "pub.dev", href: "https://pub.dev/packages/darto_static" },
            {
              label: "GitHub",
              href: "https://github.com/evandersondev/darto/tree/main/darto_static",
            },
          ],
        },
        {
          kind: "p",
          text: "Middleware de arquivos estáticos — ETag, 304, Range, gzip e Cache-Control opcionais, com proteção contra path traversal.",
        },
        { kind: "h3", text: "Instalação", id: "static-install" },
        { kind: "code", lang: "yaml", code: `dependencies:\n  darto_static: ^1.0.1` },
        { kind: "h3", text: "Uso", id: "static-usage" },
        {
          kind: "code",
          code: `import 'package:darto_static/darto_static.dart';\n\napp.mount('/public/*', serveStatic('public'));\napp.mount('/assets/*', serveStatic('dist', urlPrefix: '/assets', maxAge: Duration(days: 7)));`,
        },
        { kind: "h3", text: "Opções do serveStatic", id: "static-options" },
        {
          kind: "table",
          headers: ["Opção", "Descrição"],
          rows: [
            ["dir (posicional)", "Diretório para servir arquivos (relativo ao cwd)"],
            [
              "urlPrefix",
              "Prefixo de URL a remover — padrão '/dir'. Use quando o path de montagem difere do nome da pasta.",
            ],
            [
              "maxAge",
              "Define Cache-Control: public, max-age=N. Omita para desativar o cache do cliente.",
            ],
          ],
        },
        {
          kind: "callout",
          variant: "tip",
          text: "Proteção contra path traversal embutida, detecção automática de MIME e suporte a ETag / 304 / Range. Quando o arquivo não existe, cai para next(), então suas outras rotas ainda casam.",
        },
      ],
    ),
  },
  {
    id: "plugin-env",
    group: "plugins",
    title: bi("darto_env", "darto_env"),
    blocks: bi(
      [
        {
          kind: "links",
          links: [
            { label: "pub.dev", href: "https://pub.dev/packages/darto_env" },
            { label: "GitHub", href: "https://github.com/evandersondev/darto/tree/main/darto_env" },
          ],
        },
        {
          kind: "p",
          text: "Environment variable loader — reads .env files and Platform.environment with typed accessors.",
        },
        { kind: "h3", text: "Install", id: "env-install" },
        { kind: "code", lang: "yaml", code: `dependencies:\n  darto_env: ^1.0.1` },
        { kind: "h3", text: "Usage", id: "env-usage" },
        {
          kind: "code",
          code: `import 'package:darto_env/darto_env.dart';\n\nDartoEnv.load(); // call once at startup\n\nfinal port  = DartoEnv.getInt('PORT', 3000);\nfinal debug = DartoEnv.getBool('DEBUG', false);\nfinal key   = DartoEnv.get('API_KEY'); // throws if missing`,
        },
        { kind: "h3", text: "API", id: "env-api" },
        {
          kind: "table",
          headers: ["Method", "Description"],
          rows: [
            ["DartoEnv.load([path = '.env'])", "Load a .env file — call once at startup"],
            ["DartoEnv.get('KEY', [default])", "String — throws if missing and no default given"],
            ["DartoEnv.maybeGet('KEY')", "String? — null when the var is not set"],
            ["DartoEnv.getInt('PORT', 3000)", "int with a fallback"],
            ["DartoEnv.getDouble('RATE', 1.5)", "double with a fallback"],
            ["DartoEnv.getBool('DEBUG', false)", "bool with a fallback"],
            ["DartoEnv.getOrThrow('KEY')", "String — always throws if missing"],
            ["DartoEnv.all()", "Map<String, String> — every loaded variable"],
          ],
        },
      ],
      [
        {
          kind: "links",
          links: [
            { label: "pub.dev", href: "https://pub.dev/packages/darto_env" },
            { label: "GitHub", href: "https://github.com/evandersondev/darto/tree/main/darto_env" },
          ],
        },
        {
          kind: "p",
          text: "Carregador de variáveis de ambiente — lê arquivos .env e Platform.environment com acessores tipados.",
        },
        { kind: "h3", text: "Instalação", id: "env-install" },
        { kind: "code", lang: "yaml", code: `dependencies:\n  darto_env: ^1.0.1` },
        { kind: "h3", text: "Uso", id: "env-usage" },
        {
          kind: "code",
          code: `import 'package:darto_env/darto_env.dart';\n\nDartoEnv.load(); // chame uma vez no startup\n\nfinal port  = DartoEnv.getInt('PORT', 3000);\nfinal debug = DartoEnv.getBool('DEBUG', false);\nfinal key   = DartoEnv.get('API_KEY'); // lança se faltar`,
        },
        { kind: "h3", text: "API", id: "env-api" },
        {
          kind: "table",
          headers: ["Método", "Descrição"],
          rows: [
            [
              "DartoEnv.load([path = '.env'])",
              "Carrega um arquivo .env — chame uma vez no startup",
            ],
            ["DartoEnv.get('KEY', [default])", "String — lança se faltar e não houver default"],
            ["DartoEnv.maybeGet('KEY')", "String? — null quando a var não está definida"],
            ["DartoEnv.getInt('PORT', 3000)", "int com fallback"],
            ["DartoEnv.getDouble('RATE', 1.5)", "double com fallback"],
            ["DartoEnv.getBool('DEBUG', false)", "bool com fallback"],
            ["DartoEnv.getOrThrow('KEY')", "String — sempre lança se faltar"],
            ["DartoEnv.all()", "Map<String, String> — todas as variáveis carregadas"],
          ],
        },
      ],
    ),
  },
  // ── Migration guide ─────────────────────────────────────────────────────────
  {
    id: "migration-overview",
    group: "migration",
    title: bi("v0.x → v2 Overview", "v0.x → v2 Visão geral"),
    blocks: bi(
      [
        {
          kind: "callout",
          variant: "warning",
          text: "Darto v2 is a full rewrite. The API is incompatible with v0.x. Every route, middleware and response call needs to be updated. This guide covers all breaking changes side by side.",
        },
        {
          kind: "p",
          text: "The central concept changed from Express-style (Request, Response, NextFunction) to a Hono-style single Context object. Everything request/response related is now on c.",
        },
        {
          kind: "table",
          headers: ["Area", "v0.x", "v2"],
          rows: [
            ["Handler", "(Request req, Response res)", "(Context c)"],
            [
              "Middleware",
              "(Request req, Response res, NextFunction next)",
              "(Context c, Next next) async",
            ],
            ["Route verb", "app.get(path, handler)", "app.get(path, [], handler)"],
            ["Path-scoped mw", "app.use('/path', mw)", "app.mount('/path', mw)"],
            ["Path params", "req.param['id'] / req.params['id']", "c.req.param('id')"],
            ["Query params", "req.query['key']", "c.req.query('key')"],
            ["Body", "await req.body", "await c.req.json()"],
            ["Send JSON", "res.json({...})", "c.json({...}) / c.ok({...})"],
            [
              "Status + send",
              "res.status(201).json({...})",
              "c.status(201).json({...}) / c.created({...})",
            ],
            ["Error handler", "(Err, Request, Response, Next)", "app.onError((err, c) => ...)"],
          ],
        },
      ],
      [
        {
          kind: "callout",
          variant: "warning",
          text: "O Darto v2 é uma reescrita completa. A API é incompatível com v0.x. Cada rota, middleware e chamada de response precisa ser atualizada. Este guia cobre todas as breaking changes lado a lado.",
        },
        {
          kind: "p",
          text: "O conceito central mudou do estilo Express (Request, Response, NextFunction) para um único objeto Context no estilo Hono. Tudo relacionado a request/response agora está em c.",
        },
        {
          kind: "table",
          headers: ["Área", "v0.x", "v2"],
          rows: [
            ["Handler", "(Request req, Response res)", "(Context c)"],
            [
              "Middleware",
              "(Request req, Response res, NextFunction next)",
              "(Context c, Next next) async",
            ],
            ["Verbo de rota", "app.get(path, handler)", "app.get(path, [], handler)"],
            ["Middleware por path", "app.use('/path', mw)", "app.mount('/path', mw)"],
            ["Params de rota", "req.param['id'] / req.params['id']", "c.req.param('id')"],
            ["Query params", "req.query['key']", "c.req.query('key')"],
            ["Body", "await req.body", "await c.req.json()"],
            ["Enviar JSON", "res.json({...})", "c.json({...}) / c.ok({...})"],
            [
              "Status + enviar",
              "res.status(201).json({...})",
              "c.status(201).json({...}) / c.created({...})",
            ],
            [
              "Tratamento de erros",
              "(Err, Request, Response, Next)",
              "app.onError((err, c) => ...)",
            ],
          ],
        },
      ],
    ),
  },
  {
    id: "migration-handlers",
    group: "migration",
    title: bi("Handler & Middleware", "Handler & Middleware"),
    blocks: bi(
      [
        { kind: "h3", text: "Handler signature", id: "mg-handler" },
        {
          kind: "code",
          code: `// v0.x\napp.get('/users/:id', (Request req, Response res) {\n  final id = req.param['id'];\n  res.json({'id': id});\n});\n\n// v2\napp.get('/users/:id', [], (Context c) {\n  final id = c.req.param('id');\n  return c.ok({'id': id});\n});`,
        },
        { kind: "h3", text: "Middleware signature", id: "mg-middleware" },
        {
          kind: "code",
          code: `// v0.x\napp.use((Request req, Response res, NextFunction next) {\n  print('request: \${req.method} \${req.originalUrl}');\n  next();\n});\n\n// v2\napp.use((Context c, Next next) async {\n  print('request: \${c.req.method} \${c.req.path}');\n  await next();\n});`,
        },
        { kind: "h3", text: "Route-level middleware", id: "mg-route-mw" },
        {
          kind: "code",
          code: `// v0.x — middleware passed as positional argument before handler\napp.get('/admin', authMiddleware, (req, res) { ... });\n\n// v2 — always a List in the second argument\napp.get('/admin', [authMiddleware], (c) { ... });`,
        },
      ],
      [
        { kind: "h3", text: "Assinatura do handler", id: "mg-handler" },
        {
          kind: "code",
          code: `// v0.x\napp.get('/users/:id', (Request req, Response res) {\n  final id = req.param['id'];\n  res.json({'id': id});\n});\n\n// v2\napp.get('/users/:id', [], (Context c) {\n  final id = c.req.param('id');\n  return c.ok({'id': id});\n});`,
        },
        { kind: "h3", text: "Assinatura do middleware", id: "mg-middleware" },
        {
          kind: "code",
          code: `// v0.x\napp.use((Request req, Response res, NextFunction next) {\n  print('request: \${req.method} \${req.originalUrl}');\n  next();\n});\n\n// v2\napp.use((Context c, Next next) async {\n  print('request: \${c.req.method} \${c.req.path}');\n  await next();\n});`,
        },
        { kind: "h3", text: "Middleware por rota", id: "mg-route-mw" },
        {
          kind: "code",
          code: `// v0.x — middleware como argumento posicional antes do handler\napp.get('/admin', authMiddleware, (req, res) { ... });\n\n// v2 — sempre uma List no segundo argumento\napp.get('/admin', [authMiddleware], (c) { ... });`,
        },
      ],
    ),
  },
  {
    id: "migration-request",
    group: "migration",
    title: bi("Request API", "API de Request"),
    blocks: bi(
      [
        {
          kind: "code",
          code: `// v0.x\nfinal id      = req.param['id'];          // path param\nfinal name    = req.query['name'];         // query param\nfinal body    = await req.body;            // any body\nfinal auth    = req.headers.value('authorization');\nfinal method  = req.method;\nfinal path    = req.originalUrl;\n\n// v2\nfinal id      = c.req.param('id');         // path param\nfinal name    = c.req.query('name');       // query param\nfinal body    = await c.req.json();        // JSON body\nfinal typed   = await c.req.json<User>(User.fromJson);\nfinal auth    = c.req.header('authorization');\nfinal method  = c.req.method;\nfinal path    = c.req.path;`,
        },
        {
          kind: "callout",
          variant: "tip",
          text: "c.req.queryInt() and c.req.queryBool() parse typed query params without manual conversion.",
        },
      ],
      [
        {
          kind: "code",
          code: `// v0.x\nfinal id      = req.param['id'];          // path param\nfinal name    = req.query['name'];         // query param\nfinal body    = await req.body;            // qualquer body\nfinal auth    = req.headers.value('authorization');\nfinal method  = req.method;\nfinal path    = req.originalUrl;\n\n// v2\nfinal id      = c.req.param('id');         // path param\nfinal name    = c.req.query('name');       // query param\nfinal body    = await c.req.json();        // body JSON\nfinal typed   = await c.req.json<User>(User.fromJson);\nfinal auth    = c.req.header('authorization');\nfinal method  = c.req.method;\nfinal path    = c.req.path;`,
        },
        {
          kind: "callout",
          variant: "tip",
          text: "c.req.queryInt() e c.req.queryBool() fazem parse de query params tipados sem conversão manual.",
        },
      ],
    ),
  },
  {
    id: "migration-response",
    group: "migration",
    title: bi("Response API", "API de Response"),
    blocks: bi(
      [
        {
          kind: "code",
          code: `// v0.x\nres.send('text');               // plain text\nres.json({'key': 'value'});     // JSON\nres.status(201).json({...});    // status + JSON\nres.status(404).send('Not found');\nres.redirect('https://example.com');\nres.sendFile('path/to/file');\nres.download('path/to/file', {'filename': 'custom.txt'});\n\n// v2\nreturn c.text('text');          // plain text\nreturn c.json({'key': 'value'});\nreturn c.ok({...});             // 200 JSON\nreturn c.created({...});        // 201 JSON\nreturn c.badRequest({...});     // 400 JSON\nreturn c.notFound({...});       // 404 JSON\nreturn c.status(201).json({...});\nreturn c.redirect('https://example.com');\nawait c.file('path/to/file');   // serve inline\nawait c.download('path', filename: 'custom.txt');`,
        },
        {
          kind: "table",
          headers: ["v0.x", "v2 equivalent"],
          rows: [
            ["res.send('text')", "c.text('text')"],
            ["res.json({...})", "c.json({...})"],
            ["res.status(200).json({...})", "c.ok({...})"],
            ["res.status(201).json({...})", "c.created({...})"],
            ["res.status(400).json({...})", "c.badRequest({...})"],
            ["res.status(401).json({...})", "c.unauthorized({...})"],
            ["res.status(403).json({...})", "c.forbidden({...})"],
            ["res.status(404).send(...)", "c.notFound({...})"],
            ["res.status(500).send(...)", "c.internalError({...})"],
            ["res.redirect(url)", "c.redirect(url)"],
            ["res.sendFile(path)", "await c.file(path)"],
            ["res.download(path, opts)", "await c.download(path, filename: ...)"],
          ],
        },
      ],
      [
        {
          kind: "code",
          code: `// v0.x\nres.send('texto');              // texto simples\nres.json({'key': 'value'});     // JSON\nres.status(201).json({...});    // status + JSON\nres.status(404).send('Not found');\nres.redirect('https://example.com');\nres.sendFile('path/to/file');\nres.download('path/to/file', {'filename': 'custom.txt'});\n\n// v2\nreturn c.text('texto');\nreturn c.json({'key': 'value'});\nreturn c.ok({...});             // 200 JSON\nreturn c.created({...});        // 201 JSON\nreturn c.badRequest({...});     // 400 JSON\nreturn c.notFound({...});       // 404 JSON\nreturn c.status(201).json({...});\nreturn c.redirect('https://example.com');\nawait c.file('path/to/file');\nawait c.download('path', filename: 'custom.txt');`,
        },
        {
          kind: "table",
          headers: ["v0.x", "v2 equivalente"],
          rows: [
            ["res.send('texto')", "c.text('texto')"],
            ["res.json({...})", "c.json({...})"],
            ["res.status(200).json({...})", "c.ok({...})"],
            ["res.status(201).json({...})", "c.created({...})"],
            ["res.status(400).json({...})", "c.badRequest({...})"],
            ["res.status(401).json({...})", "c.unauthorized({...})"],
            ["res.status(403).json({...})", "c.forbidden({...})"],
            ["res.status(404).send(...)", "c.notFound({...})"],
            ["res.status(500).send(...)", "c.internalError({...})"],
            ["res.redirect(url)", "c.redirect(url)"],
            ["res.sendFile(path)", "await c.file(path)"],
            ["res.download(path, opts)", "await c.download(path, filename: ...)"],
          ],
        },
      ],
    ),
  },
  {
    id: "migration-routing",
    group: "migration",
    title: bi("Routing & Middleware Registration", "Rotas e registro de middleware"),
    blocks: bi(
      [
        { kind: "h3", text: "Path-scoped middleware", id: "mg-mount" },
        {
          kind: "code",
          code: `// v0.x\napp.use('/api/:id', middlewareFn); // path-scoped\n\n// v2\napp.mount('/api/*', middlewareFn); // wildcard required for prefix matching`,
        },
        { kind: "h3", text: "Router / grouping", id: "mg-router" },
        {
          kind: "code",
          code: `// v0.x\nRouter userRouter() {\n  final r = Router();\n  r.get('/', (req, res) { res.json(users); });\n  r.post('/', (req, res) async { ... });\n  return r;\n}\napp.use('/users', userRouter());\n\n// v2 — three equivalent styles\n// 1. Fluent chain\napp.route('/users').get([], listUsers).post([], createUser);\n\n// 2. Builder callback\napp.route('/users', (r) {\n  r.get('/', [], listUsers);\n  r.post('/', [], createUser);\n});\n\n// 3. group() prefix\nfinal users = app.group('/users');\nusers.get('/', [], listUsers);\nusers.post('/', [], createUser);`,
        },
        { kind: "h3", text: "Error handler", id: "mg-error" },
        {
          kind: "code",
          code: `// v0.x\napp.use((Err err, Request req, Response res, NextFunction next) {\n  res.status(500).json({'error': err.toString()});\n});\n\n// v2\napp.onError((err, c) {\n  return c.internalError({'error': err.toString()});\n});`,
        },
      ],
      [
        { kind: "h3", text: "Middleware por caminho", id: "mg-mount" },
        {
          kind: "code",
          code: `// v0.x\napp.use('/api/:id', middlewareFn);\n\n// v2\napp.mount('/api/*', middlewareFn); // wildcard obrigatório para match de prefixo`,
        },
        { kind: "h3", text: "Router / agrupamento", id: "mg-router" },
        {
          kind: "code",
          code: `// v0.x\nRouter userRouter() {\n  final r = Router();\n  r.get('/', (req, res) { res.json(users); });\n  return r;\n}\napp.use('/users', userRouter());\n\n// v2 — três estilos equivalentes\n// 1. Fluent chain\napp.route('/users').get([], listUsers).post([], createUser);\n\n// 2. Builder callback\napp.route('/users', (r) {\n  r.get('/', [], listUsers);\n  r.post('/', [], createUser);\n});\n\n// 3. Prefixo com group()\nfinal users = app.group('/users');\nusers.get('/', [], listUsers);\nusers.post('/', [], createUser);`,
        },
        { kind: "h3", text: "Tratamento de erros", id: "mg-error" },
        {
          kind: "code",
          code: `// v0.x\napp.use((Err err, Request req, Response res, NextFunction next) {\n  res.status(500).json({'error': err.toString()});\n});\n\n// v2\napp.onError((err, c) {\n  return c.internalError({'error': err.toString()});\n});`,
        },
      ],
    ),
  },
  {
    id: "migration-validation",
    group: "migration",
    title: bi("Validation", "Validação"),
    blocks: bi(
      [
        {
          kind: "code",
          code: `// v0.x — manual try/catch with Zard\napp.post('/users', (Request req, Response res) async {\n  final schema = z.map({\n    'name': z.string().min(3),\n    'age':  z.int().min(1),\n  });\n  try {\n    final data = await schema.parseAsync(req.body);\n    res.json(data);\n  } catch (e) {\n    res.status(406).send(schema.getErrors());\n  }\n});\n\n// v2 — zValidator middleware (darto_validator package)\nimport 'package:darto_validator/darto_validator.dart';\n\nfinal userSchema = z.map({\n  'name': z.string().min(3),\n  'age':  z.int().min(1),\n});\n\napp.post('/users', [zValidator('json', userSchema)], (c) {\n  final data = c.req.valid<Map<String, dynamic>>('json');\n  return c.created(data);\n});`,
        },
        {
          kind: "callout",
          variant: "tip",
          text: "Add darto_validator: ^1.1.0 to pubspec.yaml. zard is re-exported — no separate zard dependency needed.",
        },
      ],
      [
        {
          kind: "code",
          code: `// v0.x — try/catch manual com Zard
app.post('/users', (Request req, Response res) async {
  final schema = z.map({
    'name': z.string().min(3),
    'age':  z.int().min(1),
  });
  try {
    final data = await schema.parseAsync(req.body);
    res.json(data);
  } catch (e) {
    res.status(406).send(schema.getErrors());
  }
});

// v2 — middleware zValidator (pacote darto_validator)
import 'package:darto_validator/darto_validator.dart';

final userSchema = z.map({
  'name': z.string().min(3),
  'age':  z.int().min(1),
});

app.post('/users', [zValidator('json', userSchema)], (c) {
  final data = c.req.valid<Map<String, dynamic>>('json');
  return c.created(data);
});`,
        },
        {
          kind: "callout",
          variant: "tip",
          text: "Adicione darto_validator: ^1.1.0 ao pubspec.yaml. O zard já é re-exportado — não precisa de dependência separada.",
        },
      ],
    ),
  },
];

export function getDocSections(lang: Lang): DocSection[] {
  return SECTIONS.map((s) => ({
    id: s.id,
    group: s.group,
    title: s.title[lang],
    blocks: s.blocks[lang],
  }));
}
