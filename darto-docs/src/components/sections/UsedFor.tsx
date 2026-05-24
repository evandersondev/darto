import { useI18n } from "@/lib/i18n-context";
import { Server, Upload, Radio, LayoutTemplate } from "lucide-react";

const ICONS = [Server, Upload, Radio, LayoutTemplate];

export function UsedFor() {
  const { t } = useI18n();
  return (
    <section className="border-b border-border section-animate">
      <div className="container py-20 lg:py-28">
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="text-3xl font-semibold tracking-tight sm:text-4xl">{t.usedFor.title}</h2>
          <p className="mt-3 text-muted-foreground">{t.usedFor.subtitle}</p>
        </div>
        <div className="mx-auto mt-12 grid max-w-5xl gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {t.usedFor.items.map((item, i) => {
            const Icon = ICONS[i] ?? Server;
            return (
              <div
                key={i}
                className="stagger-child group relative flex flex-col gap-4 overflow-hidden rounded-xl border border-border bg-card p-5 transition-all duration-300 hover:border-primary/30 hover:shadow-md"
              >
                <div className="pointer-events-none absolute -bottom-4 -right-4 h-16 w-16 rounded-full bg-primary/5 opacity-0 blur-xl transition-opacity duration-500 group-hover:opacity-100" />

                <div className="flex h-9 w-9 items-center justify-center rounded-lg border border-border bg-secondary transition-colors duration-300 group-hover:border-primary/25 group-hover:bg-primary/10">
                  <Icon className="h-4 w-4 text-muted-foreground transition-colors duration-300 group-hover:text-primary" />
                </div>

                <div>
                  <h3 className="text-sm font-semibold">{item.title}</h3>
                  <p className="mt-1.5 text-sm leading-relaxed text-muted-foreground">{item.desc}</p>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}