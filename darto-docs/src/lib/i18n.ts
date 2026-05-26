export type Lang = "en" | "pt";

export const translations = {
  en: {
    nav: { docs: "Documentation", github: "GitHub", getStarted: "Get Started" },
    hero: {
      badge: "v1.1 · Minimal Dart web framework",
      title1: "A minimal, fast web framework",
      title2: "for Dart, done right.",
      subtitle:
        "Define routes, compose middleware, ship APIs. Everything flows through one concept: Context — inspired by Express and Hono, built for pure Dart.",
      cta1: "Get Started",
      cta2: "View Documentation",
      installNote: "dart pub add darto",
      tagline: "One Context. Familiar API. Zero JS bridges.",
      credibility: {
        version: "v1.1.0",
        oss: "Open source · MIT",
        pub: "pub.dev",
        github: "GitHub",
      },
    },
    features: {
      title: "Everything you expect from a modern web framework",
      subtitle:
        "Routing, context, middleware, validation, layouts, file uploads, WebSockets — out of the box.",
      items: [
        {
          icon: "route",
          title: "Expressive routing",
          desc: "Path params, regex constraints, wildcards, route groups and nested prefixes.",
        },
        {
          icon: "layers",
          title: "Single Context",
          desc: "Request and response live behind one object — c.req, c.json, c.set, c.get, c.user.",
        },
        {
          icon: "shield",
          title: "Middleware pipeline",
          desc: "Global, path-scoped or route-level. Short-circuit any time by skipping next().",
        },
        {
          icon: "blocks",
          title: "Batteries included",
          desc: "Logger, CORS, JWT, Basic/Bearer auth, Cache, Compress, CSRF, body-limit, RBAC.",
        },
        {
          icon: "check",
          title: "Built-in validation",
          desc: "zValidator for json, query, params and form — pair it with Zard for full type safety.",
        },
        {
          icon: "package",
          title: "Pure Dart, everywhere",
          desc: "Runs on the standard Dart HttpServer. No FFI, no JS, hot-reload friendly.",
        },
      ],
    },
    perf: {
      title: "Minimal overhead, maximum ergonomics",
      subtitle:
        "Darto is a thin layer over Dart's native HttpServer — you keep the speed, gain the API.",
      chips: [
        { label: "Native HttpServer", desc: "No reflection, no codegen, no FFI." },
        { label: "Tree-shakeable middlewares", desc: "Import only what you ship." },
        { label: "AOT-ready", desc: "Compiles down to a single binary." },
      ],
    },
    examples: {
      title: "Real Dart, no magic",
      subtitle: "Pick a tab to see Darto in action.",
      tabs: {
        routes: "Routing",
        middleware: "Middleware",
        validation: "Validation",
        websocket: "WebSocket",
      },
    },
    usedFor: {
      title: "Used for",
      subtitle: "Wherever HTTP enters your Dart app, Darto fits.",
      items: [
        {
          title: "REST APIs",
          desc: "Build JSON APIs with route groups, middleware and typed validation.",
        },
        {
          title: "File transfer",
          desc: "Upload streamed multipart bodies, serve files inline or force-download.",
        },
        {
          title: "WebSocket servers",
          desc: "Upgrade HTTP routes to WebSocket with the same Context API.",
        },
        {
          title: "SSR with layouts",
          desc: "Hono-style setRender or the darto_view engine for Mustache and Jinja.",
        },
      ],
    },
    realWorld: {
      title: "Real-world usage",
      subtitle: "Snippets you can paste into a Darto project today.",
      tabs: {
        api: "REST API",
        auth: "JWT-protected route",
        upload: "File upload",
      },
      samples: {
        api: `// Group + middleware + typed handler
app.route('/users')
  .get([], (c) => c.ok(users))
  .post([requireAdmin()], (c) async {
    final body = await c.req.json();
    return c.created({'id': '42', ...body});
  });`,
        auth: `import 'package:darto/jwt.dart';

app.mount('/api/*', jwt(secret: env.jwtSecret));

app.get('/api/me', [], (c) {
  final payload = c.get<Map<String, dynamic>>('jwtPayload');
  return c.ok({'userId': payload?['sub']});
});`,
        upload: `app.post('/upload', [], (c) async {
  final form = await c.req.formData();
  final file = (form as Map)['avatar'] as UploadedFile;
  await file.saveTo('uploads/\${file.filename}');
  return c.created({'name': file.filename, 'size': file.size});
});`,
      },
    },
    compare: {
      title: "Why Darto over the alternatives",
      subtitle: "A small, opinionated layer — not a heavy framework, not a bare socket.",
      headers: ["Feature", "Darto", "dart:io", "Shelf"],
      rows: [
        ["Single Context object", "✅", "❌", "⚠️"],
        ["Fluent route groups", "✅", "❌", "⚠️"],
        ["Built-in middlewares", "✅", "❌", "⚠️"],
        ["WebSocket upgrade", "✅", "⚙️", "⚙️"],
        ["Layouts / render", "✅", "❌", "❌"],
        ["Hono-style ergonomics", "✅", "❌", "❌"],
      ],
      note: "dart:io is the foundation, Shelf is the classic middleware pipeline — Darto sits between them with a Context-first API inspired by Express and Hono.",
    },
    how: {
      title: "How it works",
      subtitle: "Three steps. Create the app, register routes, start listening.",
      steps: [
        {
          title: "Create the app",
          desc: "Instantiate Darto and optionally set a global base path.",
          code: "final app = Darto();\nfinal api = app.basePath('/v1');",
        },
        {
          title: "Register routes",
          desc: "Use verbs, route groups or builder callbacks — all type-safe.",
          code: "app.get('/users/:id', [], (c) {\n  return c.ok({'id': c.req.param('id')});\n});",
        },
        {
          title: "Listen",
          desc: "Bind to a port. Stop gracefully with app.stop().",
          code: "app.listen(3000, () =>\n  print('Listening on http://localhost:3000'));",
        },
      ],
    },
    why: {
      title: "Why Darto",
      subtitle: "A web framework that respects how Dart developers actually work.",
      items: [
        {
          title: "One concept: Context",
          desc: "Everything request/response related lives behind c — nothing to memorize twice.",
        },
        {
          title: "Hono-style ergonomics",
          desc: "Familiar API. Composable middleware. Render layouts the same way.",
        },
        {
          title: "Pure Dart, no bridges",
          desc: "Runs on dart:io. Compiles AOT. Hot-reloads with the dev runner.",
        },
      ],
    },
    cta: {
      title: "Ship your next Dart API today",
      subtitle: "Add Darto to your pubspec and serve your first route in under a minute.",
      install: "Install",
      docs: "Documentation",
    },
    callouts: { tip: "Tip", warning: "Warning", bestPractice: "Best practice" },
    footer: {
      rights: "All rights reserved.",
      made: "A minimal Dart web framework — inspired by Express and Hono",
    },
    docs: {
      search: "Search the docs…",
      onThisPage: "On this page",
      badge: "Documentation",
      title: "Darto Docs",
      subtitle: "Routing, Context, middleware, validation, WebSockets and more.",
      results: (n: number, q: string) => `${n} result${n === 1 ? "" : "s"} for "${q}"`,
      noMatches: "No matches.",
      groups: {
        start: "Getting Started",
        core: "Core Concepts",
        validation: "Validation",
        advanced: "Advanced",
        reference: "Reference",
        migration: "Migration Guide",
      },
    },
  },
  pt: {
    nav: { docs: "Documentação", github: "GitHub", getStarted: "Começar" },
    hero: {
      badge: "v1.1 · Framework web minimalista para Dart",
      title1: "Um framework web rápido e mínimo",
      title2: "para Dart, do jeito certo.",
      subtitle:
        "Defina rotas, componha middlewares, publique APIs. Tudo passa por um único conceito: Context — inspirado em Express e Hono, feito em Dart puro.",
      cta1: "Começar",
      cta2: "Ver documentação",
      installNote: "dart pub add darto",
      tagline: "Um único Context. API familiar. Zero pontes JS.",
      credibility: {
        version: "v1.1.0",
        oss: "Código aberto · MIT",
        pub: "pub.dev",
        github: "GitHub",
      },
    },
    features: {
      title: "Tudo que você espera de um framework web moderno",
      subtitle:
        "Rotas, contexto, middleware, validação, layouts, upload de arquivos, WebSockets — direto da caixa.",
      items: [
        {
          icon: "route",
          title: "Rotas expressivas",
          desc: "Parâmetros, restrições regex, wildcards, grupos e prefixos aninhados.",
        },
        {
          icon: "layers",
          title: "Context único",
          desc: "Request e response vivem atrás de um objeto — c.req, c.json, c.set, c.get, c.user.",
        },
        {
          icon: "shield",
          title: "Pipeline de middlewares",
          desc: "Global, por caminho ou por rota. Pare a cadeia quando quiser pulando o next().",
        },
        {
          icon: "blocks",
          title: "Baterias inclusas",
          desc: "Logger, CORS, JWT, Basic/Bearer, Cache, Compress, CSRF, body-limit, RBAC.",
        },
        {
          icon: "check",
          title: "Validação embutida",
          desc: "zValidator para json, query, params e form — combine com Zard para type-safety total.",
        },
        {
          icon: "package",
          title: "Dart puro, em todo lugar",
          desc: "Roda no HttpServer padrão do Dart. Sem FFI, sem JS, com hot-reload.",
        },
      ],
    },
    perf: {
      title: "Overhead mínimo, ergonomia máxima",
      subtitle:
        "O Darto é uma camada fina sobre o HttpServer nativo do Dart — você mantém a velocidade e ganha a API.",
      chips: [
        { label: "HttpServer nativo", desc: "Sem reflexão, sem codegen, sem FFI." },
        { label: "Middlewares tree-shakeable", desc: "Importe só o que você publica." },
        { label: "Pronto para AOT", desc: "Compila para um único binário." },
      ],
    },
    examples: {
      title: "Dart real, sem mágica",
      subtitle: "Escolha uma aba para ver o Darto em ação.",
      tabs: {
        routes: "Rotas",
        middleware: "Middleware",
        validation: "Validação",
        websocket: "WebSocket",
      },
    },
    usedFor: {
      title: "Para que serve",
      subtitle: "Onde quer que HTTP entre no seu app Dart, o Darto se encaixa.",
      items: [
        {
          title: "APIs REST",
          desc: "Construa APIs JSON com grupos de rotas, middleware e validação tipada.",
        },
        {
          title: "Transferência de arquivos",
          desc: "Receba uploads multipart em stream, envie arquivos inline ou force download.",
        },
        {
          title: "Servidores WebSocket",
          desc: "Faça upgrade de rotas HTTP para WebSocket com a mesma API de Context.",
        },
        {
          title: "SSR com layouts",
          desc: "setRender no estilo Hono ou o engine darto_view para Mustache e Jinja.",
        },
      ],
    },
    realWorld: {
      title: "Casos de uso reais",
      subtitle: "Snippets prontos para colar no seu projeto Darto hoje.",
      tabs: {
        api: "API REST",
        auth: "Rota protegida com JWT",
        upload: "Upload de arquivo",
      },
      samples: {
        api: `// Grupo + middleware + handler tipado
app.route('/users')
  .get([], (c) => c.ok(users))
  .post([requireAdmin()], (c) async {
    final body = await c.req.json();
    return c.created({'id': '42', ...body});
  });`,
        auth: `import 'package:darto/jwt.dart';

app.mount('/api/*', jwt(secret: env.jwtSecret));

app.get('/api/me', [], (c) {
  final payload = c.get<Map<String, dynamic>>('jwtPayload');
  return c.ok({'userId': payload?['sub']});
});`,
        upload: `app.post('/upload', [], (c) async {
  final form = await c.req.formData();
  final file = (form as Map)['avatar'] as UploadedFile;
  await file.saveTo('uploads/\${file.filename}');
  return c.created({'name': file.filename, 'size': file.size});
});`,
      },
    },
    compare: {
      title: "Por que Darto em vez das alternativas",
      subtitle: "Uma camada pequena e opinativa — nem framework pesado, nem socket cru.",
      headers: ["Recurso", "Darto", "dart:io", "Shelf"],
      rows: [
        ["Objeto Context único", "✅", "❌", "⚠️"],
        ["Grupos de rotas fluentes", "✅", "❌", "⚠️"],
        ["Middlewares embutidos", "✅", "❌", "⚠️"],
        ["Upgrade WebSocket", "✅", "⚙️", "⚙️"],
        ["Layouts / render", "✅", "❌", "❌"],
        ["Ergonomia estilo Hono", "✅", "❌", "❌"],
      ],
      note: "dart:io é a fundação, Shelf é o pipeline clássico de middleware — o Darto fica entre eles com uma API Context-first inspirada no Express e Hono.",
    },
    how: {
      title: "Como funciona",
      subtitle: "Três passos. Crie o app, registre rotas, comece a ouvir.",
      steps: [
        {
          title: "Crie o app",
          desc: "Instancie o Darto e, opcionalmente, defina um base path global.",
          code: "final app = Darto();\nfinal api = app.basePath('/v1');",
        },
        {
          title: "Registre rotas",
          desc: "Use verbos, grupos ou callbacks builder — tudo type-safe.",
          code: "app.get('/users/:id', [], (c) {\n  return c.ok({'id': c.req.param('id')});\n});",
        },
        {
          title: "Ouça uma porta",
          desc: "Faça o bind. Pare graciosamente com app.stop().",
          code: "app.listen(3000, () =>\n  print('Listening on http://localhost:3000'));",
        },
      ],
    },
    why: {
      title: "Por que Darto",
      subtitle: "Um framework que respeita como devs Dart realmente trabalham.",
      items: [
        {
          title: "Um único conceito: Context",
          desc: "Tudo de request/response vive atrás de c — você não memoriza duas APIs.",
        },
        {
          title: "Ergonomia estilo Hono",
          desc: "API familiar. Middlewares componíveis. Render de layouts do mesmo jeito.",
        },
        {
          title: "Dart puro, sem pontes",
          desc: "Roda no dart:io. Compila AOT. Hot-reload com o runner de dev.",
        },
      ],
    },
    cta: {
      title: "Publique sua próxima API Dart hoje",
      subtitle: "Adicione o Darto ao pubspec e sirva sua primeira rota em menos de um minuto.",
      install: "Instalar",
      docs: "Documentação",
    },
    callouts: { tip: "Dica", warning: "Atenção", bestPractice: "Boa prática" },
    footer: {
      rights: "Todos os direitos reservados.",
      made: "Um framework web minimalista para Dart — inspirado no Express e Hono",
    },
    docs: {
      search: "Buscar na documentação…",
      onThisPage: "Nesta página",
      badge: "Documentação",
      title: "Documentação Darto",
      subtitle: "Rotas, Context, middleware, validação, WebSockets e mais.",
      results: (n: number, q: string) => `${n} resultado${n === 1 ? "" : "s"} para "${q}"`,
      noMatches: "Nenhum resultado.",
      groups: {
        start: "Primeiros passos",
        core: "Conceitos centrais",
        validation: "Validação",
        advanced: "Avançado",
        reference: "Referência",
        migration: "Guia de Migração",
      },
    },
  },
};

export type Translations = typeof translations.en;
