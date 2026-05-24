import { Link } from "@tanstack/react-router";
import { ArrowRight, Terminal } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useI18n } from "@/lib/i18n-context";
import { highlightDart } from "@/lib/highlight";

const SNIPPET = `import 'package:darto/darto.dart';

final app = Darto();

app.get('/', (c) => c.ok({'ok': true}));

await app.listen(3000);`;

export function CTA() {
  const { t } = useI18n();
  return (
    <section className="relative overflow-hidden border-b border-border bg-muted/60 dark:bg-zinc-950 section-animate">
      <div className="pointer-events-none absolute inset-0" style={{
        backgroundImage: "radial-gradient(ellipse 80% 60% at 50% -10%, color-mix(in oklab, var(--primary) 14%, transparent), transparent 70%)",
      }} />
      <div
        className="pointer-events-none absolute inset-0 opacity-[0.03]"
        style={{
          backgroundImage: "radial-gradient(circle, currentColor 1px, transparent 1px)",
          backgroundSize: "28px 28px",
        }}
      />

      <div className="container relative py-20 lg:py-28">
        <div className="mx-auto grid max-w-5xl items-center gap-12 lg:grid-cols-[1fr_auto]">
          <div>
            <div className="mb-4 inline-flex items-center gap-2 rounded-full border border-border bg-background/60 px-3 py-1 text-xs font-medium text-muted-foreground">
              <span className="h-1.5 w-1.5 rounded-full bg-primary" />
              {t.hero.credibility.version} · MIT
            </div>
            <h2 className="text-3xl font-semibold tracking-tight text-foreground sm:text-4xl lg:text-5xl">
              {t.cta.title}
            </h2>
            <p className="mt-4 max-w-lg text-muted-foreground">{t.cta.subtitle}</p>

            <div className="mt-8 flex flex-wrap items-center gap-3">
              <a href="https://pub.dev/packages/darto" target="_blank" rel="noreferrer" className="w-full sm:w-auto">
                <Button size="lg" className="w-full bg-primary text-primary-foreground hover:bg-primary/90 sm:min-w-[200px]">
                  {t.cta.install} <ArrowRight className="h-4 w-4" />
                </Button>
              </a>
              <Link to="/docs" className="w-full sm:w-auto">
                <Button variant="outline" size="lg" className="w-full sm:min-w-[200px]">
                  {t.cta.docs}
                </Button>
              </Link>
            </div>
          </div>

          <div className="hidden lg:block">
            <div className="w-[340px] overflow-hidden rounded-xl border border-code-border bg-code backdrop-blur-sm">
              <div className="flex items-center gap-2 border-b border-code-border px-4 py-2.5">
                <Terminal className="h-3.5 w-3.5 text-muted-foreground" />
                <span className="font-mono text-xs text-muted-foreground">main.dart</span>
              </div>
              <pre className="overflow-x-auto p-4 font-mono text-[12.5px] leading-relaxed">
                <code dangerouslySetInnerHTML={{ __html: highlightDart(SNIPPET) }} />
              </pre>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}