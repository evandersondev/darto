import { Cpu, Boxes, Zap } from "lucide-react";
import { useI18n } from "@/lib/i18n-context";

const ICONS = [Cpu, Boxes, Zap];

export function Performance() {
  const { t } = useI18n();
  return (
    <section className="border-b border-border section-animate">
      <div className="container py-20 lg:py-28">
        <div className="mx-auto max-w-2xl text-center">
          <div className="mb-3 font-mono text-xs uppercase tracking-wider text-muted-foreground">
            Runtime
          </div>
          <h2 className="text-3xl font-semibold tracking-tight sm:text-4xl">{t.perf.title}</h2>
          <p className="mt-3 text-muted-foreground">{t.perf.subtitle}</p>
        </div>

        <div className="mx-auto mt-10 grid max-w-4xl gap-4 sm:grid-cols-3">
          {t.perf.chips.map((chip, i) => {
            const Icon = ICONS[i] ?? Cpu;
            return (
              <div
                key={i}
                className="stagger-child rounded-xl border border-primary/20 bg-primary/[0.03] p-5"
              >
                <div className="flex h-9 w-9 items-center justify-center rounded-lg border border-primary/30 bg-primary/10">
                  <Icon className="h-4 w-4 text-primary" />
                </div>
                <h3 className="mt-4 text-sm font-semibold">{chip.label}</h3>
                <p className="mt-1.5 text-sm leading-relaxed text-muted-foreground">{chip.desc}</p>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}