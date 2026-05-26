export type Lang = "en" | "pt";

export type Block =
  | { kind: "p"; text: string }
  | { kind: "code"; lang?: "dart" | "yaml" | "sh"; code: string; filename?: string }
  | { kind: "h3"; text: string; id?: string }
  | { kind: "ul"; items: string[] }
  | { kind: "table"; headers: string[]; rows: string[][] }
  | { kind: "note"; text: string }
  | { kind: "callout"; variant: "tip" | "warning" | "success"; text: string };

export interface DocSection {
  id: string;
  title: string;
  group: "start" | "core" | "validation" | "advanced" | "reference" | "migration";
  blocks: Block[];
}

type Bi<T> = { en: T; pt: T };
const bi = <T,>(en: T, pt: T): Bi<T> => ({ en, pt });

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
        { kind: "code", lang: "yaml", filename: "pubspec.yaml", code: `dependencies:\n  darto: ^1.0.0` },
        { kind: "p", text: "Or use the pub command directly:" },
        { kind: "code", lang: "sh", code: `dart pub add darto` },
      ],
      [
        { kind: "p", text: "Adicione o Darto ao seu pubspec.yaml:" },
        { kind: "code", lang: "yaml", filename: "pubspec.yaml", code: `dependencies:\n  darto: ^1.0.0` },
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
        { kind: "p", text: "Spin up a server in under a minute. Define a Darto instance, register a route, listen on a port." },
        { kind: "code", code: `import 'package:darto/darto.dart';\n\nvoid main() {\n  final app = Darto();\n\n  app.get('/users/:id', [], (Context c) {\n    final id = c.req.param('id');\n    return c.ok({'id': id});\n  });\n\n  app.listen(3000, () => print('Listening on http://localhost:3000'));\n}` },
        { kind: "callout", variant: "tip", text: "Use response helpers (c.ok, c.created, c.badRequest…) for clean status-code handling without manual headers." },
      ],
      [
        { kind: "p", text: "Suba um servidor em menos de um minuto. Defina uma instância de Darto, registre uma rota e ouça uma porta." },
        { kind: "code", code: `import 'package:darto/darto.dart';\n\nvoid main() {\n  final app = Darto();\n\n  app.get('/users/:id', [], (Context c) {\n    final id = c.req.param('id');\n    return c.ok({'id': id});\n  });\n\n  app.listen(3000, () => print('Listening on http://localhost:3000'));\n}` },
        { kind: "callout", variant: "tip", text: "Use os helpers de resposta (c.ok, c.created, c.badRequest…) para tratar status sem montar headers manualmente." },
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
        { kind: "code", code: `typedef Handler    = FutureOr<Response>? Function(Context c);\ntypedef Middleware = FutureOr<void>      Function(Context c, Next next);\ntypedef Next       = Future<void>        Function();` },
        { kind: "ul", items: [
          "A handler receives a Context and returns a Response.",
          "A middleware receives a Context and a Next callback.",
          "Call await next() to continue the pipeline; return without it to short-circuit.",
        ]},
        { kind: "callout", variant: "success", text: "If you've used Hono, you already know Darto — the mental model is identical." },
      ],
      [
        { kind: "p", text: "Três typedefs são tudo o que você precisa entender para usar o framework inteiro:" },
        { kind: "code", code: `typedef Handler    = FutureOr<Response>? Function(Context c);\ntypedef Middleware = FutureOr<void>      Function(Context c, Next next);\ntypedef Next       = Future<void>        Function();` },
        { kind: "ul", items: [
          "Um handler recebe um Context e retorna uma Response.",
          "Um middleware recebe um Context e um callback Next.",
          "Chame await next() para continuar a pipeline; retorne sem chamar para parar.",
        ]},
        { kind: "callout", variant: "success", text: "Se você já usou Hono, já conhece Darto — o modelo mental é idêntico." },
      ],
    ),
  },
  {
    id: "application",
    group: "core",
    title: bi("Application", "Aplicação"),
    blocks: bi(
      [
        { kind: "h3", text: "Creating the app", id: "app-create" },
        { kind: "code", code: `final app = Darto();             // default (non-strict trailing slash)\nfinal app = Darto(strict: true); // /users ≠ /users/` },
        { kind: "h3", text: "Global base path", id: "app-basepath" },
        { kind: "code", code: `final app = Darto().basePath('/v1');\n\napp.get('/users', [], handler); // registered as /v1/users` },
        { kind: "h3", text: "Starting and stopping", id: "app-listen" },
        { kind: "code", code: `app.listen(3000);\napp.listen(3000, () => print('ready'));\n\napp.stop();\nbool running = app.isRunning;` },
      ],
      [
        { kind: "h3", text: "Criando o app", id: "app-create" },
        { kind: "code", code: `final app = Darto();             // padrão (trailing slash não-estrito)\nfinal app = Darto(strict: true); // /users ≠ /users/` },
        { kind: "h3", text: "Base path global", id: "app-basepath" },
        { kind: "code", code: `final app = Darto().basePath('/v1');\n\napp.get('/users', [], handler); // registrado como /v1/users` },
        { kind: "h3", text: "Subindo e parando", id: "app-listen" },
        { kind: "code", code: `app.listen(3000);\napp.listen(3000, () => print('pronto'));\n\napp.stop();\nbool running = app.isRunning;` },
      ],
    ),
  },
  {
    id: "routing",
    group: "core",
    title: bi("Routing", "Roteamento"),
    blocks: bi(
      [
        { kind: "h3", text: "HTTP verbs", id: "routing-verbs" },
        { kind: "p", text: "All verb methods take the middleware list as the second argument (required — pass [] for no middleware) and the handler last." },
        { kind: "code", code: `app.get(path, [], handler);\napp.post(path, [], handler);\napp.put(path, [], handler);\napp.patch(path, [], handler);\napp.delete(path, [], handler);\n\napp.all(path, [], handler);\napp.on(['GET', 'POST'], ['/a', '/b'], [], handler);` },
        { kind: "h3", text: "Route parameters", id: "routing-params" },
        { kind: "code", code: `app.get('/users/:id', [], (c) => c.ok({'id': c.req.param('id')}));\napp.get('/posts/:slug?', [], handler);          // optional\napp.get('/items/:id(\\d+)', [], handler);        // regex constraint\napp.get('/files/*path', [], handler);           // named wildcard\napp.get('/assets/*', [], handler);              // unnamed wildcard` },
        { kind: "h3", text: "Route groups", id: "routing-groups" },
        { kind: "code", code: `// Fluent chain\napp.route('/users')\n  .get([], listUsers)\n  .post([auth()], createUser);\n\n// Builder callback\napp.route('/users', (r) {\n  r.get('/', [], listUsers);\n  r.post('/', [auth()], createUser);\n  r.get('/:id', [], getUser);\n});\n\n// group() prefix\nfinal api = app.group('/api');\napi.get('/status', [], (c) => c.ok({'ok': true}));` },
        { kind: "callout", variant: "tip", text: "Groups compose: app.group('/api').group('/v2').get('/ping', [], …) registers GET /api/v2/ping." },
      ],
      [
        { kind: "h3", text: "Verbos HTTP", id: "routing-verbs" },
        { kind: "p", text: "Todos os métodos de verbo recebem a lista de middlewares como segundo argumento (obrigatório — passe [] para nenhum middleware) e o handler por último." },
        { kind: "code", code: `app.get(path, [], handler);\napp.post(path, [], handler);\napp.put(path, [], handler);\napp.patch(path, [], handler);\napp.delete(path, [], handler);\n\napp.all(path, [], handler);\napp.on(['GET', 'POST'], ['/a', '/b'], [], handler);` },
        { kind: "h3", text: "Parâmetros de rota", id: "routing-params" },
        { kind: "code", code: `app.get('/users/:id', [], (c) => c.ok({'id': c.req.param('id')}));\napp.get('/posts/:slug?', [], handler);          // opcional\napp.get('/items/:id(\\d+)', [], handler);        // restrição regex\napp.get('/files/*path', [], handler);           // wildcard nomeado\napp.get('/assets/*', [], handler);              // wildcard sem nome` },
        { kind: "h3", text: "Grupos de rotas", id: "routing-groups" },
        { kind: "code", code: `// Fluent chain\napp.route('/users')\n  .get([], listUsers)\n  .post([auth()], createUser);\n\n// Builder callback\napp.route('/users', (r) {\n  r.get('/', [], listUsers);\n  r.post('/', [auth()], createUser);\n  r.get('/:id', [], getUser);\n});\n\n// Prefixo com group()\nfinal api = app.group('/api');\napi.get('/status', [], (c) => c.ok({'ok': true}));` },
        { kind: "callout", variant: "tip", text: "Grupos compõem: app.group('/api').group('/v2').get('/ping', [], …) registra GET /api/v2/ping." },
      ],
    ),
  },
  {
    id: "context",
    group: "core",
    title: bi("Context API", "API do Context"),
    blocks: bi(
      [
        { kind: "p", text: "The Context object is the single entry point for everything request/response related." },
        { kind: "h3", text: "Response helpers", id: "ctx-responses" },
        { kind: "code", code: `c.ok([body])           // 200\nc.created([body])      // 201\nc.noContent()          // 204\nc.badRequest([body])   // 400\nc.unauthorized([body]) // 401\nc.forbidden([body])    // 403\nc.notFound([body])     // 404\nc.internalError([body])// 500\n\nc.json(data, [status]);\nc.text(str, [status]);\nc.html(str, [status]);\nc.redirect('/login', 301);\nc.status(206).json(data);\n\n// Streamed files\nawait c.file('/path/to/file.pdf');\nawait c.download('/path/to/report.csv', filename: 'export.csv');` },
        { kind: "h3", text: "Sending a raw body", id: "ctx-body" },
        { kind: "p", text: "c.body() sends the response body (HonoJS-style). To read the request body, use c.req (see the Request section)." },
        { kind: "code", code: `c.body('Thank you!');                              // text/plain\nc.body(bytes, 200, {'Content-Type': 'image/png'}); // bytes + headers\nc.body(null, 204);                                 // empty body` },
        { kind: "h3", text: "State", id: "ctx-state" },
        { kind: "code", code: `c.set('userId', '42');\nfinal id = c.get<String>('userId');\n\nc.user = {'id': '42', 'role': 'admin'};` },
        { kind: "h3", text: "Headers and metadata", id: "ctx-meta" },
        { kind: "code", code: `c.header('X-Request-Id', uuid);\nint code = c.statusCode;\nString? pattern = c.routePath;     // '/posts/:id'\nString? base    = c.basePath;     // '/api'` },
      ],
      [
        { kind: "p", text: "O Context é o ponto único de entrada para tudo relacionado a request/response." },
        { kind: "h3", text: "Helpers de resposta", id: "ctx-responses" },
        { kind: "code", code: `c.ok([body])           // 200\nc.created([body])      // 201\nc.noContent()          // 204\nc.badRequest([body])   // 400\nc.unauthorized([body]) // 401\nc.forbidden([body])    // 403\nc.notFound([body])     // 404\nc.internalError([body])// 500\n\nc.json(data, [status]);\nc.text(str, [status]);\nc.html(str, [status]);\nc.redirect('/login', 301);\nc.status(206).json(data);\n\n// Arquivos em stream\nawait c.file('/path/to/file.pdf');\nawait c.download('/path/to/report.csv', filename: 'export.csv');` },
        { kind: "h3", text: "Enviando um body cru", id: "ctx-body" },
        { kind: "p", text: "c.body() envia o corpo da resposta (estilo HonoJS). Para ler o corpo da requisição, use c.req (veja a seção Request)." },
        { kind: "code", code: `c.body('Obrigado!');                               // text/plain\nc.body(bytes, 200, {'Content-Type': 'image/png'}); // bytes + headers\nc.body(null, 204);                                 // body vazio` },
        { kind: "h3", text: "Estado", id: "ctx-state" },
        { kind: "code", code: `c.set('userId', '42');\nfinal id = c.get<String>('userId');\n\nc.user = {'id': '42', 'role': 'admin'};` },
        { kind: "h3", text: "Headers e metadata", id: "ctx-meta" },
        { kind: "code", code: `c.header('X-Request-Id', uuid);\nint code = c.statusCode;\nString? pattern = c.routePath;     // '/posts/:id'\nString? base    = c.basePath;     // '/api'` },
      ],
    ),
  },
  {
    id: "request",
    group: "core",
    title: bi("Request (c.req)", "Request (c.req)"),
    blocks: bi(
      [
        { kind: "code", code: `String  method = c.req.method;\nString  path   = c.req.path;\nUri     url    = c.req.url;\nString  ip     = c.req.ip;\n\nString? id      = c.req.param('id');\nint?    page    = c.req.queryInt('page');\nbool    active  = c.req.queryBool('active');\nString? auth    = c.req.header('authorization');\n\nfinal json   = await c.req.json();\nfinal typed  = await c.req.json<User>(User.fromJson);\nfinal text   = await c.req.text();          // String (UTF-8)\nfinal blob   = await c.req.blob();          // Uint8List\nfinal stream = c.req.body;                  // Stream<List<int>> (raw)\nfinal form   = await c.req.formData();` },
      ],
      [
        { kind: "code", code: `String  method = c.req.method;\nString  path   = c.req.path;\nUri     url    = c.req.url;\nString  ip     = c.req.ip;\n\nString? id      = c.req.param('id');\nint?    page    = c.req.queryInt('page');\nbool    active  = c.req.queryBool('active');\nString? auth    = c.req.header('authorization');\n\nfinal json   = await c.req.json();\nfinal typed  = await c.req.json<User>(User.fromJson);\nfinal text   = await c.req.text();          // String (UTF-8)\nfinal blob   = await c.req.blob();          // Uint8List\nfinal stream = c.req.body;                  // Stream<List<int>> (raw)\nfinal form   = await c.req.formData();` },
      ],
    ),
  },
  {
    id: "response-factories",
    group: "core",
    title: bi("Response Factories", "Factories de Response"),
    blocks: bi(
      [
        { kind: "p", text: "Construct raw Response objects when you need full control:" },
        { kind: "code", code: `Response.json(data, {int status = 200, Map<String,String> headers = const {}});\nResponse.text(str,  {int status = 200});\nResponse.html(str,  {int status = 200});\nResponse.bytes(bytes, {int status = 200, String contentType = '...'});\nconst Response.empty({int status = 204});` },
      ],
      [
        { kind: "p", text: "Construa objetos Response brutos quando precisar de controle total:" },
        { kind: "code", code: `Response.json(data, {int status = 200, Map<String,String> headers = const {}});\nResponse.text(str,  {int status = 200});\nResponse.html(str,  {int status = 200});\nResponse.bytes(bytes, {int status = 200, String contentType = '...'});\nconst Response.empty({int status = 204});` },
      ],
    ),
  },
  {
    id: "validation",
    group: "validation",
    title: bi("Validation", "Validação"),
    blocks: bi(
      [
        { kind: "p", text: "Darto ships two validation middlewares. zValidator (from darto_validator) uses zard schemas and sends automatic 400 responses. validator (from darto core) gives you full control over the error response — use any logic or library you like." },
        { kind: "h3", text: "zValidator — schema-driven", id: "val-zvalidator" },
        { kind: "code", lang: "yaml", filename: "pubspec.yaml", code: `dependencies:\n  darto_validator: ^1.0.0` },
        { kind: "code", code: `import 'package:darto_validator/darto_validator.dart';\n\nfinal body = z.map({\n  'email': z.string().email(),\n  'age':   z.int().min(18),\n});\n\napp.post('/users', [zValidator('json', body)], (c) {\n  final data = c.req.valid<Map<String, dynamic>>('json');\n  return c.created(data);\n});` },
        { kind: "h3", text: "Custom error hook", id: "val-hook" },
        { kind: "code", code: `zValidator('json', body, (result, c) {\n  if (!result.success) {\n    return c.status(422).json({\n      'error': 'Validation failed',\n      'issues': result.error?.format(),\n    });\n  }\n  return null;\n});` },
        { kind: "h3", text: "validator — bring your own logic", id: "val-validator" },
        { kind: "p", text: "Built into the darto core — no extra package needed. Pass a callback that receives the raw value and the Context. Return a Response to short-circuit with any status code, or return data to store it." },
        { kind: "code", code: `import 'package:darto/validator.dart';\nimport 'package:darto_validator/darto_validator.dart'; // for z.*\n\nfinal loginSchema = z.map({\n  'email':    z.string().email(),\n  'password': z.string().min(6),\n});\n\n// 401 on failure — you decide the status code\napp.post('/login', [\n  validator('json', (value, c) {\n    final result = loginSchema.safeParse(value);\n    if (!result.success) return c.status(401).json({'errors': result.error?.format()});\n    return result.data;\n  }),\n], (c) {\n  final credentials = c.req.valid<Map<String, dynamic>>('json');\n  return c.ok({'message': 'Welcome, \${credentials[\\'email\\']}!'});\n});` },
        { kind: "h3", text: "Targets", id: "val-targets" },
        { kind: "ul", items: ["'json' — request body", "'query' — query string", "'param' — path parameters", "'form' — url-encoded / multipart", "'header' — request headers"] },
        { kind: "callout", variant: "warning", text: "Always validate untrusted input at the edges — bodies, queries, headers and uploaded files." },
      ],
      [
        { kind: "p", text: "O Darto oferece dois middlewares de validação. zValidator (do darto_validator) usa schemas zard e envia respostas 400 automáticas. validator (do core do darto) dá controle total sobre a resposta de erro — use qualquer lógica ou biblioteca." },
        { kind: "h3", text: "zValidator — baseado em schema", id: "val-zvalidator" },
        { kind: "code", lang: "yaml", filename: "pubspec.yaml", code: `dependencies:\n  darto_validator: ^1.0.0` },
        { kind: "code", code: `import 'package:darto_validator/darto_validator.dart';\n\nfinal body = z.map({\n  'email': z.string().email(),\n  'age':   z.int().min(18),\n});\n\napp.post('/users', [zValidator('json', body)], (c) {\n  final data = c.req.valid<Map<String, dynamic>>('json');\n  return c.created(data);\n});` },
        { kind: "h3", text: "Hook de erro customizado", id: "val-hook" },
        { kind: "code", code: `zValidator('json', body, (result, c) {\n  if (!result.success) {\n    return c.status(422).json({\n      'error': 'Validação falhou',\n      'issues': result.error?.format(),\n    });\n  }\n  return null;\n});` },
        { kind: "h3", text: "validator — traga sua própria lógica", id: "val-validator" },
        { kind: "p", text: "Embutido no core do darto — sem pacote extra. Passe um callback que recebe o valor bruto e o Context. Retorne uma Response para encerrar com qualquer status, ou retorne os dados para armazená-los." },
        { kind: "code", code: `import 'package:darto/validator.dart';\nimport 'package:darto_validator/darto_validator.dart'; // para z.*\n\nfinal loginSchema = z.map({\n  'email':    z.string().email(),\n  'password': z.string().min(6),\n});\n\n// 401 em caso de falha — você decide o status\napp.post('/login', [\n  validator('json', (value, c) {\n    final result = loginSchema.safeParse(value);\n    if (!result.success) return c.status(401).json({'errors': result.error?.format()});\n    return result.data;\n  }),\n], (c) {\n  final credentials = c.req.valid<Map<String, dynamic>>('json');\n  return c.ok({'message': 'Bem-vindo, \${credentials[\\'email\\']}!'});\n});` },
        { kind: "h3", text: "Targets", id: "val-targets" },
        { kind: "ul", items: ["'json' — body da request", "'query' — query string", "'param' — parâmetros de path", "'form' — url-encoded / multipart", "'header' — headers da request"] },
        { kind: "callout", variant: "warning", text: "Sempre valide input não confiável nas bordas — bodies, queries, headers e arquivos enviados." },
      ],
    ),
  },
  {
    id: "middleware",
    group: "advanced",
    title: bi("Middleware", "Middleware"),
    blocks: bi(
      [
        { kind: "h3", text: "Registering", id: "mw-register" },
        { kind: "p", text: "use(middleware) registers a global middleware that runs on every request. mount(path, middleware) registers a path-scoped middleware — it only runs when the request path starts with path (supports * wildcards)." },
        { kind: "code", code: `app.use(logger());               // global — runs on every request\napp.use(cors());                 // call separately per middleware\napp.mount('/api/*', jwt(...));   // path-scoped\napp.get('/admin', [requireAdmin()], handler); // route-level` },
        { kind: "h3", text: "Writing one", id: "mw-write" },
        { kind: "code", code: `Middleware timer() => (Context c, Next next) async {\n  final sw = Stopwatch()..start();\n  await next();\n  print('\${c.req.method} \${c.req.path}  \${sw.elapsedMilliseconds}ms');\n};` },
        { kind: "h3", text: "Short-circuit", id: "mw-short" },
        { kind: "code", code: `Middleware requireAdmin() => (c, next) async {\n  if (c.user?['role'] != 'admin') {\n    c.forbidden({'error': 'Admins only'});\n    return; // pipeline stops here\n  }\n  await next();\n};` },
      ],
      [
        { kind: "h3", text: "Registrando", id: "mw-register" },
        { kind: "p", text: "use(middleware) registra um middleware global que roda em toda request. mount(path, middleware) registra um middleware por caminho — só roda quando o path da request começa com path (suporta wildcards *)." },
        { kind: "code", code: `app.use(logger());               // global — roda em toda request\napp.use(cors());                 // chame separadamente por middleware\napp.mount('/api/*', jwt(...));   // por caminho\napp.get('/admin', [requireAdmin()], handler); // por rota` },
        { kind: "h3", text: "Criando um", id: "mw-write" },
        { kind: "code", code: `Middleware timer() => (Context c, Next next) async {\n  final sw = Stopwatch()..start();\n  await next();\n  print('\${c.req.method} \${c.req.path}  \${sw.elapsedMilliseconds}ms');\n};` },
        { kind: "h3", text: "Short-circuit", id: "mw-short" },
        { kind: "code", code: `Middleware requireAdmin() => (c, next) async {\n  if (c.user?['role'] != 'admin') {\n    c.forbidden({'error': 'Somente admins'});\n    return; // pipeline para aqui\n  }\n  await next();\n};` },
      ],
    ),
  },
  {
    id: "builtin-middlewares",
    group: "advanced",
    title: bi("Built-in Middlewares", "Middlewares embutidos"),
    blocks: bi(
      [
        { kind: "p", text: "Darto ships with batteries: logger, CORS, JWT, Basic & Bearer auth, cache, compress, CSRF, body-limit, RBAC and more." },
        { kind: "code", code: `import 'package:darto/logger.dart';\nimport 'package:darto/cors.dart';\nimport 'package:darto/jwt.dart';\nimport 'package:darto/basic_auth.dart';\nimport 'package:darto/bearer_auth.dart';\nimport 'package:darto/cache.dart';\n\napp.use(logger());\napp.mount('/api/*', cors(origin: 'https://example.com'));\napp.mount('/api/*', jwt(secret: env.jwtSecret));\napp.mount('/admin/*', basicAuth(username: 'admin', password: 'secret'));\napp.mount('/api/*', bearerAuth(token: ['key1', 'key2']));` },
        { kind: "h3", text: "RBAC", id: "mw-rbac" },
        { kind: "code", code: `import 'package:darto/require_roles.dart';\napp.delete('/users/:id', [requireRoles(['admin'])], handler);` },
        { kind: "h3", text: "Body limit", id: "mw-bodylimit" },
        { kind: "code", code: `app.post('/upload', [bodyLimit(maxSize: 5 * 1024 * 1024)], handler);` },
        { kind: "callout", variant: "warning", text: "When using jwt, always set verifyOptions (iss, exp, nbf) for production deployments." },
      ],
      [
        { kind: "p", text: "O Darto vem com baterias: logger, CORS, JWT, Basic & Bearer auth, cache, compress, CSRF, body-limit, RBAC e mais." },
        { kind: "code", code: `import 'package:darto/logger.dart';\nimport 'package:darto/cors.dart';\nimport 'package:darto/jwt.dart';\nimport 'package:darto/basic_auth.dart';\nimport 'package:darto/bearer_auth.dart';\nimport 'package:darto/cache.dart';\n\napp.use(logger());\napp.mount('/api/*', cors(origin: 'https://example.com'));\napp.mount('/api/*', jwt(secret: env.jwtSecret));\napp.mount('/admin/*', basicAuth(username: 'admin', password: 'secret'));\napp.mount('/api/*', bearerAuth(token: ['key1', 'key2']));` },
        { kind: "h3", text: "RBAC", id: "mw-rbac" },
        { kind: "code", code: `import 'package:darto/require_roles.dart';\napp.delete('/users/:id', [requireRoles(['admin'])], handler);` },
        { kind: "h3", text: "Limite de body", id: "mw-bodylimit" },
        { kind: "code", code: `app.post('/upload', [bodyLimit(maxSize: 5 * 1024 * 1024)], handler);` },
        { kind: "callout", variant: "warning", text: "Ao usar jwt, sempre configure verifyOptions (iss, exp, nbf) em produção." },
      ],
    ),
  },
  {
    id: "session",
    group: "advanced",
    title: bi("Session", "Sessão"),
    blocks: bi(
      [
        { kind: "p", text: "Cookie-based signed sessions. Data is JSON-serialised, base64url-encoded, and signed with HMAC-SHA256 — tamper-proof but not encrypted. Store only non-sensitive identifiers (e.g. userId) in the session." },
        { kind: "code", code: `import 'package:darto/session.dart';\n\n// Register once globally — reads and validates the session cookie on every request\napp.use(sessionMiddleware(\n  secret: 'at-least-32-chars-long-secret!!',\n  duration: 60 * 30,           // cookie maxAge in seconds (default: 1800)\n  cookieName: 'darto.session', // optional, this is the default\n));` },
        { kind: "h3", text: "Write / Read / Delete", id: "session-api" },
        { kind: "code", code: `app.post('/login', [], (c) async {\n  final body = await c.req.json();\n  await sessionContext(c).update({'userId': body['id'], 'role': 'user'});\n  return c.ok({'message': 'logged in'});\n});\n\napp.get('/me', [], (c) {\n  final data = sessionContext(c).get(); // null if no active session\n  if (data == null) return c.unauthorized({'error': 'no session'});\n  return c.ok(data);\n});\n\napp.post('/logout', [], (c) {\n  sessionContext(c).delete();\n  return c.ok({'message': 'logged out'});\n});` },
        { kind: "table", headers: ["Method", "Returns", "Description"], rows: [
          ["sessionContext(c).get()", "Map<String, dynamic>?", "Session data — null if no valid session"],
          ["sessionContext(c).update(data)", "Future<void>", "Replace data and write the signed cookie"],
          ["sessionContext(c).delete()", "void", "Clear data and remove the cookie"],
        ]},
        { kind: "callout", variant: "warning", text: "Session data is visible (base64-decoded) but not alterable — the HMAC signature prevents tampering. Do not store passwords or secrets inside the session." },
      ],
      [
        { kind: "p", text: "Sessões baseadas em cookie assinado. Os dados são serializados em JSON, codificados em base64url e assinados com HMAC-SHA256 — à prova de adulteração, mas não criptografados. Armazene apenas identificadores não sensíveis (ex.: userId) na sessão." },
        { kind: "code", code: `import 'package:darto/session.dart';\n\n// Registre uma vez globalmente — lê e valida o cookie de sessão em toda request\napp.use(sessionMiddleware(\n  secret: 'chave-com-pelo-menos-32-caracteres!!',\n  duration: 60 * 30,           // maxAge do cookie em segundos (padrão: 1800)\n  cookieName: 'darto.session', // opcional, este é o padrão\n));` },
        { kind: "h3", text: "Gravar / Ler / Apagar", id: "session-api" },
        { kind: "code", code: `app.post('/login', [], (c) async {\n  final body = await c.req.json();\n  await sessionContext(c).update({'userId': body['id'], 'role': 'user'});\n  return c.ok({'message': 'logado'});\n});\n\napp.get('/me', [], (c) {\n  final data = sessionContext(c).get(); // null se não houver sessão ativa\n  if (data == null) return c.unauthorized({'error': 'sem sessão'});\n  return c.ok(data);\n});\n\napp.post('/logout', [], (c) {\n  sessionContext(c).delete();\n  return c.ok({'message': 'deslogado'});\n});` },
        { kind: "table", headers: ["Método", "Retorna", "Descrição"], rows: [
          ["sessionContext(c).get()", "Map<String, dynamic>?", "Dados da sessão — null se não houver sessão válida"],
          ["sessionContext(c).update(data)", "Future<void>", "Substitui os dados e escreve o cookie assinado"],
          ["sessionContext(c).delete()", "void", "Limpa os dados e remove o cookie"],
        ]},
        { kind: "callout", variant: "warning", text: "Os dados da sessão são visíveis (decodificáveis via base64) mas não alteráveis — a assinatura HMAC impede adulteração. Não armazene senhas ou segredos dentro da sessão." },
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
        { kind: "code", code: `app.use((Context c, Next next) async {\n  c.setRender((content, props) => c.html('''\n    <!DOCTYPE html>\n    <html><head><title>\${props['title'] ?? 'Darto'}</title></head>\n    <body>\$content</body></html>\n  '''));\n  await next();\n});\n\napp.get('/', [], (c) => c.render('<h1>Welcome</h1>', {'title': 'Home'}));` },
        { kind: "callout", variant: "tip", text: "Register a different layout via app.mount('/admin/*', …) to override for a path scope." },
      ],
      [
        { kind: "p", text: "Renderização em duas etapas, inspirada no setRenderer / c.render do Hono." },
        { kind: "code", code: `app.use((Context c, Next next) async {\n  c.setRender((content, props) => c.html('''\n    <!DOCTYPE html>\n    <html><head><title>\${props['title'] ?? 'Darto'}</title></head>\n    <body>\$content</body></html>\n  '''));\n  await next();\n});\n\napp.get('/', [], (c) => c.render('<h1>Bem-vindo</h1>', {'title': 'Home'}));` },
        { kind: "callout", variant: "tip", text: "Registre um layout diferente via app.mount('/admin/*', …) para sobrescrever em um escopo." },
      ],
    ),
  },
  {
    id: "view-engine",
    group: "advanced",
    title: bi("View Engine", "View Engine"),
    blocks: bi(
      [
        { kind: "p", text: "For file-based templates (Mustache, Jinja…) use the darto_view package. Register an engine once via middleware, then call c.render() in any handler." },
        { kind: "code", code: `import 'package:darto/darto.dart';\nimport 'package:darto_view/darto_view.dart';\n\nfinal app = Darto();\napp.use(viewEngine(MustacheEngine(viewsPath: 'views')));\n\napp.get('/', [], (c) => c.render('index', {\n  'title': 'Home',\n  'items': ['Routing', 'Middleware', 'Validation'],\n}));` },
      ],
      [
        { kind: "p", text: "Para templates em arquivos (Mustache, Jinja…) use o pacote darto_view. Registre o engine via middleware uma vez e use c.render() em qualquer handler." },
        { kind: "code", code: `import 'package:darto/darto.dart';\nimport 'package:darto_view/darto_view.dart';\n\nfinal app = Darto();\napp.use(viewEngine(MustacheEngine(viewsPath: 'views')));\n\napp.get('/', [], (c) => c.render('index', {\n  'title': 'Home',\n  'items': ['Roteamento', 'Middleware', 'Validação'],\n}));` },
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
        { kind: "code", code: `app.post('/upload', [], (c) async {\n  final form = await c.req.formData();\n  final file = (form as Map)['avatar'] as UploadedFile;\n  print(file.filename); // logo.png\n  print(file.size);     // bytes\n  return c.created({'name': file.filename});\n});` },
        { kind: "h3", text: "Streamed to disk", id: "fu-stream" },
        { kind: "code", code: `app.post('/upload', [], (c) async {\n  final form = await c.req.formData();\n  final file = (form as Map)['video'] as UploadedFile;\n  await file.saveTo('uploads/\${file.filename}');\n  return c.created({'ok': true});\n});` },
        { kind: "callout", variant: "tip", text: "Prefer saveTo for files larger than a few MB — it streams instead of buffering the entire body." },
      ],
      [
        { kind: "h3", text: "Em memória", id: "fu-memory" },
        { kind: "code", code: `app.post('/upload', [], (c) async {\n  final form = await c.req.formData();\n  final file = (form as Map)['avatar'] as UploadedFile;\n  print(file.filename);\n  print(file.size);\n  return c.created({'name': file.filename});\n});` },
        { kind: "h3", text: "Streamed para disco", id: "fu-stream" },
        { kind: "code", code: `app.post('/upload', [], (c) async {\n  final form = await c.req.formData();\n  final file = (form as Map)['video'] as UploadedFile;\n  await file.saveTo('uploads/\${file.filename}');\n  return c.created({'ok': true});\n});` },
        { kind: "callout", variant: "tip", text: "Use saveTo para arquivos maiores que alguns MB — ele faz stream em vez de bufferizar tudo." },
      ],
    ),
  },
  {
    id: "file-download",
    group: "advanced",
    title: bi("File Download", "Download de arquivo"),
    blocks: bi(
      [
        { kind: "code", code: `// Inline (browser tries to render it)\nawait c.file('/path/to/report.pdf');\n\n// Force download with Content-Disposition\nawait c.download('/path/to/report.csv', filename: 'export.csv');` },
      ],
      [
        { kind: "code", code: `// Inline (browser tenta renderizar)\nawait c.file('/path/to/report.pdf');\n\n// Forçar download com Content-Disposition\nawait c.download('/path/to/report.csv', filename: 'export.csv');` },
      ],
    ),
  },
  {
    id: "websocket",
    group: "advanced",
    title: bi("WebSocket", "WebSocket"),
    blocks: bi(
      [
        { kind: "p", text: "Use the darto_ws package to upgrade any route to a WebSocket. Add it to your pubspec: darto_ws: ^1.0.0." },
        { kind: "code", code: `import 'package:darto/darto.dart';\nimport 'package:darto_ws/darto_ws.dart';\n\napp.get('/chat', [], upgradeWebSocket((c) => WSHandler(\n  onOpen:    (ws) => ws.send('hello'),\n  onMessage: (event, ws) => ws.send('echo: \${event.text}'),\n  onClose:   () => print('bye'),\n)));` },
        { kind: "h3", text: "Path params and state", id: "ws-state" },
        { kind: "code", code: `// Middleware runs before the upgrade — path params and state are available inside WSHandler\napp.get('/rooms/:id', [bearerAuth(token: env.token)], upgradeWebSocket((c) {\n  final room = c.req.param('id');\n  return WSHandler(\n    onOpen: (ws) => ws.send('joined room \$room'),\n    onMessage: (event, ws) => ws.sendJson({'echo': event.json}),\n  );\n}));` },
        { kind: "callout", variant: "success", text: "Middleware (auth, logging) runs before the upgrade — protect WS endpoints just like HTTP routes." },
      ],
      [
        { kind: "p", text: "Use o pacote darto_ws para fazer upgrade de qualquer rota para WebSocket. Adicione ao pubspec: darto_ws: ^1.0.0." },
        { kind: "code", code: `import 'package:darto/darto.dart';\nimport 'package:darto_ws/darto_ws.dart';\n\napp.get('/chat', [], upgradeWebSocket((c) => WSHandler(\n  onOpen:    (ws) => ws.send('hello'),\n  onMessage: (event, ws) => ws.send('echo: \${event.text}'),\n  onClose:   () => print('bye'),\n)));` },
        { kind: "h3", text: "Params e estado", id: "ws-state" },
        { kind: "code", code: `// Middleware roda antes do upgrade — params e estado disponíveis no WSHandler\napp.get('/rooms/:id', [bearerAuth(token: env.token)], upgradeWebSocket((c) {\n  final room = c.req.param('id');\n  return WSHandler(\n    onOpen: (ws) => ws.send('entrou na sala \$room'),\n    onMessage: (event, ws) => ws.sendJson({'echo': event.json}),\n  );\n}));` },
        { kind: "callout", variant: "success", text: "Middlewares (auth, log) rodam antes do upgrade — proteja endpoints WS como rotas HTTP." },
      ],
    ),
  },
  {
    id: "error-handling",
    group: "advanced",
    title: bi("Error Handling", "Tratamento de erros"),
    blocks: bi(
      [
        { kind: "code", code: `app.onError((err, c) {\n  print('error: \$err');\n  return c.internalError({'error': 'something went wrong'});\n});\n\napp.notFound((c) => c.notFound({'error': 'route not found'}));` },
      ],
      [
        { kind: "code", code: `app.onError((err, c) {\n  print('erro: \$err');\n  return c.internalError({'error': 'algo deu errado'});\n});\n\napp.notFound((c) => c.notFound({'error': 'rota não encontrada'}));` },
      ],
    ),
  },
  {
    id: "helpers",
    group: "reference",
    title: bi("Helpers", "Helpers"),
    blocks: bi(
      [
        { kind: "h3", text: "Cookie", id: "helpers-cookie" },
        { kind: "p", text: "Cookie helpers are standalone functions imported from package:darto/cookie.dart." },
        { kind: "code", code: `import 'package:darto/cookie.dart';\n\nsetCookie(c, 'session', token,\n  CookieOptions(maxAge: 3600, httpOnly: true, secure: true));\nfinal sid = getCookie(c, 'session');\ndeleteCookie(c, 'session');\n\n// Signed cookies (HMAC-SHA256)\nawait setSignedCookie(c, 'session', token, secret);\nfinal val = await getSignedCookie(c, secret, 'session');` },
        { kind: "h3", text: "JWT helpers", id: "helpers-jwt" },
        { kind: "p", text: "sign() and verify() are async. Include exp in the payload to set an expiry." },
        { kind: "code", code: `import 'package:darto/jwt.dart';\n\nfinal token = await sign(\n  {'sub': '42', 'exp': DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000},\n  env.jwtSecret,\n);\nfinal payload = await verify(token, env.jwtSecret);` },
        { kind: "h3", text: "Proxy", id: "helpers-proxy" },
        { kind: "p", text: "proxy() is a route handler helper — call it inside a handler and return its result. A single wildcard route covers exact and deep paths." },
        { kind: "code", code: `import 'package:darto/proxy.dart';\n\n// /* matches both the exact path and any sub-path:\n// /api/users  •  /api/users/1  •  /api/users/1/posts\napp.all('/api/users/*', [], (Context c) =>\n    proxy(c, 'https://backend.com\${c.req.path}'));\n\n// With header overrides\napp.all('/v1/*', [], (Context c) =>\n    proxy(c, 'https://example.com\${c.req.path}',\n        options: ProxyOptions(\n          headers: {\n            'X-Proxy-By': 'darto-gateway',\n            'Authorization': 'Bearer INTERNAL_SECRET',\n            'Cookie': null, // null = remove header\n          },\n        )));` },
      ],
      [
        { kind: "h3", text: "Cookie", id: "helpers-cookie" },
        { kind: "p", text: "Os helpers de cookie são funções standalone importadas de package:darto/cookie.dart." },
        { kind: "code", code: `import 'package:darto/cookie.dart';\n\nsetCookie(c, 'session', token,\n  CookieOptions(maxAge: 3600, httpOnly: true, secure: true));\nfinal sid = getCookie(c, 'session');\ndeleteCookie(c, 'session');\n\n// Cookies assinados (HMAC-SHA256)\nawait setSignedCookie(c, 'session', token, secret);\nfinal val = await getSignedCookie(c, secret, 'session');` },
        { kind: "h3", text: "JWT helpers", id: "helpers-jwt" },
        { kind: "p", text: "sign() e verify() são assíncronos. Inclua exp no payload para definir expiração." },
        { kind: "code", code: `import 'package:darto/jwt.dart';\n\nfinal token = await sign(\n  {'sub': '42', 'exp': DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000},\n  env.jwtSecret,\n);\nfinal payload = await verify(token, env.jwtSecret);` },
        { kind: "h3", text: "Proxy", id: "helpers-proxy" },
        { kind: "p", text: "proxy() é um helper de handler — chame dentro de um handler e retorne o resultado. Uma única rota wildcard cobre caminhos exatos e profundos." },
        { kind: "code", code: `import 'package:darto/proxy.dart';\n\n// Forward transparente — método + headers + body\napp.all('/api/*', [], (Context c) =>\n    proxy(c, 'https://backend.com\${c.req.path}'));\n\n// Com sobrescrita de headers\napp.all('/v1/*', [], (Context c) =>\n    proxy(c, 'https://example.com\${c.req.path}',\n        options: ProxyOptions(\n          headers: {\n            'X-Proxy-By': 'darto-gateway',\n            'Authorization': 'Bearer INTERNAL_SECRET',\n            'Cookie': null, // null = remove o header\n          },\n        )));` },
      ],
    ),
  },
  {
    id: "cli-tools",
    group: "reference",
    title: bi("CLI Tools", "Ferramentas CLI"),
    blocks: bi(
      [
        { kind: "p", text: "Install the Darto CLI globally with pub:" },
        { kind: "code", lang: "sh", code: `dart pub global activate darto_cli` },
        { kind: "p", text: "Make sure ~/.pub-cache/bin is on your PATH." },
        { kind: "h3", text: "Create a project", id: "cli-create" },
        { kind: "code", lang: "sh", code: `darto create my_api          # with starter user module\ndarto create my_api --blank  # minimal — no modules, just GET /health` },
        { kind: "p", text: "Generated structure (default):" },
        { kind: "code", lang: "sh", code: `my_api/\n  bin/server.dart\n  lib/\n    app.dart\n    modules/user/\n      user_controller.dart   # handlers + route registration\n      user_service.dart      # business logic\n  pubspec.yaml` },
        { kind: "h3", text: "Dev server", id: "cli-dev" },
        { kind: "p", text: "Watches lib/, bin/, and src/ recursively. Restarts automatically (350 ms debounce) on any .dart file change — including deep subdirectories." },
        { kind: "code", lang: "sh", code: `darto dev\ndarto dev bin/server.dart` },
        { kind: "h3", text: "Build & Start", id: "cli-build" },
        { kind: "code", lang: "sh", code: `darto build                       # compile to build/server + Dockerfile\ndarto build --output build/api    # custom output path\ndarto build --no-docker           # skip Dockerfile\ndarto start                       # run the compiled binary` },
        { kind: "h3", text: "Generate typed Flutter client", id: "cli-gen" },
        { kind: "code", lang: "sh", code: `darto gen client flutter\ndarto gen client flutter --base-url https://api.example.com --output lib/api_client.dart` },
        { kind: "callout", variant: "tip", text: "darto gen reads createApp() from lib/app.dart, introspects all registered routes, and emits a typed ApiClient with one sub-module class per route group." },
      ],
      [
        { kind: "p", text: "Instale o Darto CLI globalmente com pub:" },
        { kind: "code", lang: "sh", code: `dart pub global activate darto_cli` },
        { kind: "p", text: "Certifique-se de que ~/.pub-cache/bin está no seu PATH." },
        { kind: "h3", text: "Criar um projeto", id: "cli-create" },
        { kind: "code", lang: "sh", code: `darto create my_api          # com módulo user de exemplo\ndarto create my_api --blank  # mínimo — sem módulos, apenas GET /health` },
        { kind: "p", text: "Estrutura gerada (padrão):" },
        { kind: "code", lang: "sh", code: `my_api/\n  bin/server.dart\n  lib/\n    app.dart\n    modules/user/\n      user_controller.dart   # handlers + registro de rotas\n      user_service.dart      # lógica de negócio\n  pubspec.yaml` },
        { kind: "h3", text: "Servidor de desenvolvimento", id: "cli-dev" },
        { kind: "p", text: "Observa lib/, bin/ e src/ recursivamente. Reinicia automaticamente (debounce de 350 ms) ao alterar qualquer arquivo .dart — inclusive em subdiretórios profundos." },
        { kind: "code", lang: "sh", code: `darto dev\ndarto dev bin/server.dart` },
        { kind: "h3", text: "Build & Start", id: "cli-build" },
        { kind: "code", lang: "sh", code: `darto build                       # compila para build/server + Dockerfile\ndarto build --output build/api    # caminho de saída personalizado\ndarto build --no-docker           # sem Dockerfile\ndarto start                       # executa o binário compilado` },
        { kind: "h3", text: "Gerar cliente Flutter tipado", id: "cli-gen" },
        { kind: "code", lang: "sh", code: `darto gen client flutter\ndarto gen client flutter --base-url https://api.example.com --output lib/api_client.dart` },
        { kind: "callout", variant: "tip", text: "darto gen lê createApp() de lib/app.dart, inspeciona todas as rotas registradas e emite um ApiClient tipado com uma sub-classe por grupo de rotas." },
      ],
    ),
  },
  {
    id: "full-example",
    group: "reference",
    title: bi("Full Example", "Exemplo completo"),
    blocks: bi(
      [
        { kind: "code", code: `import 'package:darto/darto.dart';\nimport 'package:darto/logger.dart';\nimport 'package:darto/cors.dart';\nimport 'package:darto/jwt.dart';\nimport 'package:darto_validator/darto_validator.dart';\n\nfinal createUser = z.map({\n  'email': z.string().email(),\n  'name':  z.string().min(2),\n});\n\nvoid main() {\n  final app = Darto();\n\n  app.use(logger());\n  app.mount('/api/*', cors());\n  app.mount('/api/*', jwt(secret: 'mySecret'));\n\n  final api = app.group('/api');\n\n  api.get('/me', [], (c) {\n    final payload = c.get<Map<String, dynamic>>('jwtPayload');\n    return c.ok({'userId': payload?['sub']});\n  });\n\n  api.post('/users', [zValidator('json', createUser)], (c) {\n    final data = c.req.valid<Map<String, dynamic>>('json');\n    return c.created({'id': '42', ...data});\n  });\n\n  app.onError((err, c) => c.internalError({'error': err.toString()}));\n\n  app.listen(3000, () => print('http://localhost:3000'));\n}` },
      ],
      [
        { kind: "code", code: `import 'package:darto/darto.dart';\nimport 'package:darto/logger.dart';\nimport 'package:darto/cors.dart';\nimport 'package:darto/jwt.dart';\nimport 'package:darto_validator/darto_validator.dart';\n\nfinal createUser = z.map({\n  'email': z.string().email(),\n  'name':  z.string().min(2),\n});\n\nvoid main() {\n  final app = Darto();\n\n  app.use(logger());\n  app.mount('/api/*', cors());\n  app.mount('/api/*', jwt(secret: 'mySecret'));\n\n  final api = app.group('/api');\n\n  api.get('/me', [], (c) {\n    final payload = c.get<Map<String, dynamic>>('jwtPayload');\n    return c.ok({'userId': payload?['sub']});\n  });\n\n  api.post('/users', [zValidator('json', createUser)], (c) {\n    final data = c.req.valid<Map<String, dynamic>>('json');\n    return c.created({'id': '42', ...data});\n  });\n\n  app.onError((err, c) => c.internalError({'error': err.toString()}));\n\n  app.listen(3000, () => print('http://localhost:3000'));\n}` },
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
        { kind: "callout", variant: "warning", text: "Darto v2 is a full rewrite. The API is incompatible with v0.x. Every route, middleware and response call needs to be updated. This guide covers all breaking changes side by side." },
        { kind: "p", text: "The central concept changed from Express-style (Request, Response, NextFunction) to a Hono-style single Context object. Everything request/response related is now on c." },
        { kind: "table", headers: ["Area", "v0.x", "v2"], rows: [
          ["Handler", "(Request req, Response res)", "(Context c)"],
          ["Middleware", "(Request req, Response res, NextFunction next)", "(Context c, Next next) async"],
          ["Route verb", "app.get(path, handler)", "app.get(path, [], handler)"],
          ["Path-scoped mw", "app.use('/path', mw)", "app.mount('/path', mw)"],
          ["Path params", "req.param['id'] / req.params['id']", "c.req.param('id')"],
          ["Query params", "req.query['key']", "c.req.query('key')"],
          ["Body", "await req.body", "await c.req.json()"],
          ["Send JSON", "res.json({...})", "c.json({...}) / c.ok({...})"],
          ["Status + send", "res.status(201).json({...})", "c.status(201).json({...}) / c.created({...})"],
          ["Error handler", "(Err, Request, Response, Next)", "app.onError((err, c) => ...)"],
        ]},
      ],
      [
        { kind: "callout", variant: "warning", text: "O Darto v2 é uma reescrita completa. A API é incompatível com v0.x. Cada rota, middleware e chamada de response precisa ser atualizada. Este guia cobre todas as breaking changes lado a lado." },
        { kind: "p", text: "O conceito central mudou do estilo Express (Request, Response, NextFunction) para um único objeto Context no estilo Hono. Tudo relacionado a request/response agora está em c." },
        { kind: "table", headers: ["Área", "v0.x", "v2"], rows: [
          ["Handler", "(Request req, Response res)", "(Context c)"],
          ["Middleware", "(Request req, Response res, NextFunction next)", "(Context c, Next next) async"],
          ["Verbo de rota", "app.get(path, handler)", "app.get(path, [], handler)"],
          ["Middleware por path", "app.use('/path', mw)", "app.mount('/path', mw)"],
          ["Params de rota", "req.param['id'] / req.params['id']", "c.req.param('id')"],
          ["Query params", "req.query['key']", "c.req.query('key')"],
          ["Body", "await req.body", "await c.req.json()"],
          ["Enviar JSON", "res.json({...})", "c.json({...}) / c.ok({...})"],
          ["Status + enviar", "res.status(201).json({...})", "c.status(201).json({...}) / c.created({...})"],
          ["Tratamento de erros", "(Err, Request, Response, Next)", "app.onError((err, c) => ...)"],
        ]},
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
        { kind: "code", code: `// v0.x\napp.get('/users/:id', (Request req, Response res) {\n  final id = req.param['id'];\n  res.json({'id': id});\n});\n\n// v2\napp.get('/users/:id', [], (Context c) {\n  final id = c.req.param('id');\n  return c.ok({'id': id});\n});` },
        { kind: "h3", text: "Middleware signature", id: "mg-middleware" },
        { kind: "code", code: `// v0.x\napp.use((Request req, Response res, NextFunction next) {\n  print('request: \${req.method} \${req.originalUrl}');\n  next();\n});\n\n// v2\napp.use((Context c, Next next) async {\n  print('request: \${c.req.method} \${c.req.path}');\n  await next();\n});` },
        { kind: "h3", text: "Route-level middleware", id: "mg-route-mw" },
        { kind: "code", code: `// v0.x — middleware passed as positional argument before handler\napp.get('/admin', authMiddleware, (req, res) { ... });\n\n// v2 — always a List in the second argument\napp.get('/admin', [authMiddleware], (c) { ... });` },
      ],
      [
        { kind: "h3", text: "Assinatura do handler", id: "mg-handler" },
        { kind: "code", code: `// v0.x\napp.get('/users/:id', (Request req, Response res) {\n  final id = req.param['id'];\n  res.json({'id': id});\n});\n\n// v2\napp.get('/users/:id', [], (Context c) {\n  final id = c.req.param('id');\n  return c.ok({'id': id});\n});` },
        { kind: "h3", text: "Assinatura do middleware", id: "mg-middleware" },
        { kind: "code", code: `// v0.x\napp.use((Request req, Response res, NextFunction next) {\n  print('request: \${req.method} \${req.originalUrl}');\n  next();\n});\n\n// v2\napp.use((Context c, Next next) async {\n  print('request: \${c.req.method} \${c.req.path}');\n  await next();\n});` },
        { kind: "h3", text: "Middleware por rota", id: "mg-route-mw" },
        { kind: "code", code: `// v0.x — middleware como argumento posicional antes do handler\napp.get('/admin', authMiddleware, (req, res) { ... });\n\n// v2 — sempre uma List no segundo argumento\napp.get('/admin', [authMiddleware], (c) { ... });` },
      ],
    ),
  },
  {
    id: "migration-request",
    group: "migration",
    title: bi("Request API", "API de Request"),
    blocks: bi(
      [
        { kind: "code", code: `// v0.x\nfinal id      = req.param['id'];          // path param\nfinal name    = req.query['name'];         // query param\nfinal body    = await req.body;            // any body\nfinal auth    = req.headers.value('authorization');\nfinal method  = req.method;\nfinal path    = req.originalUrl;\n\n// v2\nfinal id      = c.req.param('id');         // path param\nfinal name    = c.req.query('name');       // query param\nfinal body    = await c.req.json();        // JSON body\nfinal typed   = await c.req.json<User>(User.fromJson);\nfinal auth    = c.req.header('authorization');\nfinal method  = c.req.method;\nfinal path    = c.req.path;` },
        { kind: "callout", variant: "tip", text: "c.req.queryInt() and c.req.queryBool() parse typed query params without manual conversion." },
      ],
      [
        { kind: "code", code: `// v0.x\nfinal id      = req.param['id'];          // path param\nfinal name    = req.query['name'];         // query param\nfinal body    = await req.body;            // qualquer body\nfinal auth    = req.headers.value('authorization');\nfinal method  = req.method;\nfinal path    = req.originalUrl;\n\n// v2\nfinal id      = c.req.param('id');         // path param\nfinal name    = c.req.query('name');       // query param\nfinal body    = await c.req.json();        // body JSON\nfinal typed   = await c.req.json<User>(User.fromJson);\nfinal auth    = c.req.header('authorization');\nfinal method  = c.req.method;\nfinal path    = c.req.path;` },
        { kind: "callout", variant: "tip", text: "c.req.queryInt() e c.req.queryBool() fazem parse de query params tipados sem conversão manual." },
      ],
    ),
  },
  {
    id: "migration-response",
    group: "migration",
    title: bi("Response API", "API de Response"),
    blocks: bi(
      [
        { kind: "code", code: `// v0.x\nres.send('text');               // plain text\nres.json({'key': 'value'});     // JSON\nres.status(201).json({...});    // status + JSON\nres.status(404).send('Not found');\nres.redirect('https://example.com');\nres.sendFile('path/to/file');\nres.download('path/to/file', {'filename': 'custom.txt'});\n\n// v2\nreturn c.text('text');          // plain text\nreturn c.json({'key': 'value'});\nreturn c.ok({...});             // 200 JSON\nreturn c.created({...});        // 201 JSON\nreturn c.badRequest({...});     // 400 JSON\nreturn c.notFound({...});       // 404 JSON\nreturn c.status(201).json({...});\nreturn c.redirect('https://example.com');\nawait c.file('path/to/file');   // serve inline\nawait c.download('path', filename: 'custom.txt');` },
        { kind: "table", headers: ["v0.x", "v2 equivalent"], rows: [
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
        ]},
      ],
      [
        { kind: "code", code: `// v0.x\nres.send('texto');              // texto simples\nres.json({'key': 'value'});     // JSON\nres.status(201).json({...});    // status + JSON\nres.status(404).send('Not found');\nres.redirect('https://example.com');\nres.sendFile('path/to/file');\nres.download('path/to/file', {'filename': 'custom.txt'});\n\n// v2\nreturn c.text('texto');\nreturn c.json({'key': 'value'});\nreturn c.ok({...});             // 200 JSON\nreturn c.created({...});        // 201 JSON\nreturn c.badRequest({...});     // 400 JSON\nreturn c.notFound({...});       // 404 JSON\nreturn c.status(201).json({...});\nreturn c.redirect('https://example.com');\nawait c.file('path/to/file');\nawait c.download('path', filename: 'custom.txt');` },
        { kind: "table", headers: ["v0.x", "v2 equivalente"], rows: [
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
        ]},
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
        { kind: "code", code: `// v0.x\napp.use('/api/:id', middlewareFn); // path-scoped\n\n// v2\napp.mount('/api/*', middlewareFn); // wildcard required for prefix matching` },
        { kind: "h3", text: "Router / grouping", id: "mg-router" },
        { kind: "code", code: `// v0.x\nRouter userRouter() {\n  final r = Router();\n  r.get('/', (req, res) { res.json(users); });\n  r.post('/', (req, res) async { ... });\n  return r;\n}\napp.use('/users', userRouter());\n\n// v2 — three equivalent styles\n// 1. Fluent chain\napp.route('/users').get([], listUsers).post([], createUser);\n\n// 2. Builder callback\napp.route('/users', (r) {\n  r.get('/', [], listUsers);\n  r.post('/', [], createUser);\n});\n\n// 3. group() prefix\nfinal users = app.group('/users');\nusers.get('/', [], listUsers);\nusers.post('/', [], createUser);` },
        { kind: "h3", text: "Error handler", id: "mg-error" },
        { kind: "code", code: `// v0.x\napp.use((Err err, Request req, Response res, NextFunction next) {\n  res.status(500).json({'error': err.toString()});\n});\n\n// v2\napp.onError((err, c) {\n  return c.internalError({'error': err.toString()});\n});` },
      ],
      [
        { kind: "h3", text: "Middleware por caminho", id: "mg-mount" },
        { kind: "code", code: `// v0.x\napp.use('/api/:id', middlewareFn);\n\n// v2\napp.mount('/api/*', middlewareFn); // wildcard obrigatório para match de prefixo` },
        { kind: "h3", text: "Router / agrupamento", id: "mg-router" },
        { kind: "code", code: `// v0.x\nRouter userRouter() {\n  final r = Router();\n  r.get('/', (req, res) { res.json(users); });\n  return r;\n}\napp.use('/users', userRouter());\n\n// v2 — três estilos equivalentes\n// 1. Fluent chain\napp.route('/users').get([], listUsers).post([], createUser);\n\n// 2. Builder callback\napp.route('/users', (r) {\n  r.get('/', [], listUsers);\n  r.post('/', [], createUser);\n});\n\n// 3. Prefixo com group()\nfinal users = app.group('/users');\nusers.get('/', [], listUsers);\nusers.post('/', [], createUser);` },
        { kind: "h3", text: "Tratamento de erros", id: "mg-error" },
        { kind: "code", code: `// v0.x\napp.use((Err err, Request req, Response res, NextFunction next) {\n  res.status(500).json({'error': err.toString()});\n});\n\n// v2\napp.onError((err, c) {\n  return c.internalError({'error': err.toString()});\n});` },
      ],
    ),
  },
  {
    id: "migration-validation",
    group: "migration",
    title: bi("Validation", "Validação"),
    blocks: bi(
      [
        { kind: "code", code: `// v0.x — manual try/catch with Zard\napp.post('/users', (Request req, Response res) async {\n  final schema = z.map({\n    'name': z.string().min(3),\n    'age':  z.int().min(1),\n  });\n  try {\n    final data = await schema.parseAsync(req.body);\n    res.json(data);\n  } catch (e) {\n    res.status(406).send(schema.getErrors());\n  }\n});\n\n// v2 — zValidator middleware (darto_validator package)\nimport 'package:darto_validator/darto_validator.dart';\n\nfinal userSchema = z.map({\n  'name': z.string().min(3),\n  'age':  z.int().min(1),\n});\n\napp.post('/users', [zValidator('json', userSchema)], (c) {\n  final data = c.req.valid<Map<String, dynamic>>('json');\n  return c.created(data);\n});` },
        { kind: "callout", variant: "tip", text: "Add darto_validator: ^1.0.0 to pubspec.yaml. zard is re-exported — no separate zard dependency needed." },
      ],
      [
        { kind: "code", code: `// v0.x — try/catch manual com Zard\napp.post('/users', (Request req, Response res) async {\n  final schema = z.map({\n    'name': z.string().min(3),\n    'age':  z.int().min(1),\n  });\n  try {\n    final data = await schema.parseAsync(req.body);\n    res.json(data);\n  } catch (e) {\n    res.status(406).send(schema.getErrors());\n  }\n});\n\n// v2 — middleware zValidator (pacote darto_validator)\nimport 'package:darto_validator/darto_validator.dart';\n\nfinal userSchema = z.map({\n  'name': z.string().min(3),\n  'age':  z.int().min(1),\n});\n\napp.post('/users', [zValidator('json', userSchema)], (c) {\n  final data = c.req.valid<Map<String, dynamic>>('json');\n  return c.created(data);\n});` },
        { kind: "callout", variant: "tip", text: "Adicione darto_validator: ^1.0.0 ao pubspec.yaml. O zard já é re-exportado — não precisa de dependência separada." },
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
