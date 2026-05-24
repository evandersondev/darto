import { ArrowRight, FileCode, Network, Rocket } from "lucide-react";
import { useI18n } from "@/lib/i18n-context";
import { highlightDart } from "@/lib/highlight";

export function HowItWorks() {
  const { t } = useI18n();
  const steps = t.how.steps;
  const icons = [FileCode, Network, Rocket];

  return (
    <section className="border-b border-border bg-secondary/40 section-animate">
      <div className="container py-20 lg:py-28">
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="text-3xl font-semibold tracking-tight sm:text-4xl">{t.how.title}</h2>
          <p className="mt-3 text-muted-foreground">{t.how.subtitle}</p>
        </div>

        <div className="mt-12 grid gap-6 md:grid-cols-3">
          {steps.map((step, i) => {
            const Icon = icons[i];
            return (
              <div key={i} className="relative flex">
                <div className="flex w-full flex-col rounded-lg border border-border bg-card p-6">
                  <div className="mb-4 flex items-center gap-2">
                    <Icon className="h-4 w-4 text-primary" />
                    <span className="font-mono text-xs uppercase tracking-wider text-muted-foreground">
                      {String(i + 1).padStart(2, "0")}
                    </span>
                  </div>
                  <h3 className="text-base font-semibold">{step.title}</h3>
                  <p className="mt-2 text-sm leading-relaxed text-muted-foreground">{step.desc}</p>
                  <pre className="mt-4 flex-1 overflow-x-auto rounded-md border border-code-border bg-code px-3 py-2 font-mono text-[12px] leading-relaxed text-code-foreground">
                    <code dangerouslySetInnerHTML={{ __html: highlightDart(step.code) }} />
                  </pre>
                </div>
                {i < steps.length - 1 && (
                  <ArrowRight className="absolute -right-5 top-1/2 hidden h-5 w-5 -translate-y-1/2 text-muted-foreground md:block" />
                )}
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}