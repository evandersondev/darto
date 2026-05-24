import { CodeBlock } from "@/components/CodeBlock";
import { Button } from "@/components/ui/button";
import { useI18n } from "@/lib/i18n-context";
import { Link } from "@tanstack/react-router";
import { ArrowRight, Check, Copy, Github, Package } from "lucide-react";
import { useState } from "react";

const HERO_CODE = `import 'package:darto/darto.dart';

void main() {
  final app = Darto();

  app.get('/users/:id', [], (Context c) {
    final id = c.req.param('id');
    
    return c.ok({'id': id});
  });

  app.listen(3000);
}`;

export function Hero() {
  const { t } = useI18n();
  const [copied, setCopied] = useState(false);

  const copy = async () => {
    await navigator.clipboard.writeText(t.hero.installNote);
    setCopied(true);
    setTimeout(() => setCopied(false), 1500);
  };

  return (
    <section className="relative hero-bg border-b border-border">
      <div className="container relative grid gap-14 py-20 lg:grid-cols-[1.1fr_1fr] lg:gap-12 lg:py-28">
        <div className="flex flex-col justify-center">
          <div className="mb-6 inline-flex w-fit items-center gap-2 rounded-full border border-border bg-card px-3 py-1 text-xs font-medium text-muted-foreground">
            <span className="h-1.5 w-1.5 rounded-full bg-primary" />
            {t.hero.badge}
          </div>
          <h1 className="text-5xl font-semibold leading-[1.1] tracking-tight sm:text-6xl">
            {t.hero.title1} <span className="text-primary">{t.hero.title2}</span>
          </h1>
          <p className="mt-6 max-w-xl text-lg leading-relaxed text-muted-foreground">
            {t.hero.subtitle}
          </p>
          <p className="mt-3 max-w-xl font-mono text-sm text-foreground/70">{t.hero.tagline}</p>

          <div className="mt-8 flex flex-wrap items-center gap-3">
            <Link to="/docs" className="w-full sm:w-auto">
              <Button size="lg" className="w-full sm:min-w-[200px]">
                {t.hero.cta1} <ArrowRight className="h-4 w-4" />
              </Button>
            </Link>
            <Link to="/docs" className="w-full sm:w-auto">
              <Button variant="outline" size="lg" className="w-full sm:min-w-[200px]">
                {t.hero.cta2}
              </Button>
            </Link>
          </div>

          <button
            onClick={copy}
            className="mt-8 inline-flex w-fit items-center gap-3 rounded-md border border-border bg-card px-3 py-2 font-mono text-sm text-foreground transition-colors hover:bg-secondary"
          >
            <span className="text-muted-foreground">$</span> {t.hero.installNote}
            {copied ? (
              <Check className="h-3.5 w-3.5 text-primary" />
            ) : (
              <Copy className="h-3.5 w-3.5 text-muted-foreground" />
            )}
          </button>

          <div className="mt-6 flex flex-wrap items-center gap-x-4 gap-y-2 text-xs text-muted-foreground">
            <span className="inline-flex items-center gap-1.5 rounded-md border border-border bg-card px-2 py-1 font-mono">
              <span className="h-1.5 w-1.5 rounded-full bg-primary" />
              {t.hero.credibility.version}
            </span>
            <span className="inline-flex items-center gap-1.5">
              <span className="h-1 w-1 rounded-full bg-muted-foreground/50" />
              {t.hero.credibility.oss}
            </span>
            <a
              href="https://pub.dev/packages/darto"
              target="_blank"
              rel="noreferrer"
              className="inline-flex items-center gap-1.5 transition-colors hover:text-foreground"
            >
              <Package className="h-3.5 w-3.5" />
              {t.hero.credibility.pub}
            </a>
            <a
              href="https://github.com/evandersondev/darto"
              target="_blank"
              rel="noreferrer"
              className="inline-flex items-center gap-1.5 transition-colors hover:text-foreground"
            >
              <Github className="h-3.5 w-3.5" />
              {t.hero.credibility.github}
            </a>
          </div>
        </div>

        <div className="relative">
          <CodeBlock code={HERO_CODE} filename="main.dart" />
        </div>
      </div>
    </section>
  );
}
