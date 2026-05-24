import { useState } from "react";
import { CodeBlock } from "@/components/CodeBlock";
import { useI18n } from "@/lib/i18n-context";
import { cn } from "@/lib/utils";

const SAMPLES = {
  routes: `// Verbs, params and groups
app.get('/users/:id', [], (c) => c.ok({'id': c.req.param('id')}));

app.route('/posts')
  .get([], listPosts)
  .post([auth()], createPost)
  .on(['PUT', 'DELETE'], [], handler);

final api = app.group('/api');
api.get('/status', [], (c) => c.ok({'ok': true}));`,
  middleware: `// Global, path-scoped, route-level
app.use(logger());
app.mount('/api/*', cors());

app.get('/admin', [requireAdmin()], handler);

Middleware requireAdmin() => (c, next) async {
  if (c.user?['role'] != 'admin') {
    c.forbidden({'error': 'Admins only'});
    return; // short-circuit
  }
  await next();
};`,
  validation: `import 'package:darto_validator/darto_validator.dart';
import 'package:zard/zard.dart';

final body = z.map({
  'email': z.string().email(),
  'age':   z.int().min(18),
});

app.post('/users', [zValidator('json', body)], (c) {
  final data = c.valid<Map<String, dynamic>>('json');
  return c.created(data);
});`,
  websocket: `import 'package:darto/darto.dart';
import 'package:darto_ws/darto_ws.dart';

app.get('/chat', [], upgradeWebSocket((c) => WSHandler(
  onOpen:    (ws) => ws.send('hello'),
  onMessage: (event, ws) => ws.send('echo: \${event.text}'),
  onClose:   () => print('bye'),
)));`,
};

export function Examples() {
  const { t } = useI18n();
  const [tab, setTab] = useState<keyof typeof SAMPLES>("routes");

  const tabs: { key: keyof typeof SAMPLES; label: string }[] = [
    { key: "routes", label: t.examples.tabs.routes },
    { key: "middleware", label: t.examples.tabs.middleware },
    { key: "validation", label: t.examples.tabs.validation },
    { key: "websocket", label: t.examples.tabs.websocket },
  ];

  return (
    <section className="border-b border-border section-animate">
      <div className="container py-20 lg:py-28">
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="text-3xl font-semibold tracking-tight sm:text-4xl">{t.examples.title}</h2>
          <p className="mt-3 text-muted-foreground">{t.examples.subtitle}</p>
        </div>

        <div className="mx-auto mt-10 max-w-3xl">
          <div className="mb-4 flex items-center gap-1 border-b border-border">
            {tabs.map(tb => (
              <button
                key={tb.key}
                onClick={() => setTab(tb.key)}
                className={cn(
                  "relative whitespace-nowrap px-3 py-2 text-sm font-medium transition-colors",
                  tab === tb.key
                    ? "text-foreground after:absolute after:inset-x-0 after:-bottom-px after:h-px after:bg-primary"
                    : "text-muted-foreground hover:text-foreground"
                )}
              >
                {tb.label}
              </button>
            ))}
          </div>
          <CodeBlock code={SAMPLES[tab]} filename={`${tab}.dart`} />
        </div>
      </div>
    </section>
  );
}