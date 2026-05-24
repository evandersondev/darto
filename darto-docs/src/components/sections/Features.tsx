import { Route, Layers, Shield, Blocks, CheckCircle2, Package, type LucideIcon } from "lucide-react";
import { useI18n } from "@/lib/i18n-context";

const ICONS: Record<string, LucideIcon> = {
  route: Route, layers: Layers, shield: Shield, blocks: Blocks, check: CheckCircle2, package: Package,
};

export function Features() {
  const { t } = useI18n();
  return (
    <section className="border-b border-border section-animate">
      <div className="container py-20 lg:py-28">
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="text-3xl font-semibold tracking-tight sm:text-4xl">{t.features.title}</h2>
          <p className="mt-3 text-muted-foreground">{t.features.subtitle}</p>
        </div>

        <div className="mt-12 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {t.features.items.map((item, i) => {
            const Icon = ICONS[item.icon] || Route;
            return (
              <div
                key={i}
                className="stagger-child group relative flex flex-col gap-4 overflow-hidden rounded-xl border border-border bg-card p-6 transition-all duration-300 hover:border-primary/40 hover:shadow-lg"
              >
                <div className="pointer-events-none absolute -right-6 -top-6 h-20 w-20 rounded-full bg-primary/5 opacity-0 blur-2xl transition-opacity duration-500 group-hover:opacity-100" />

                <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg border border-border bg-secondary transition-colors duration-300 group-hover:border-primary/30 group-hover:bg-primary/10">
                  <Icon className="h-4 w-4 text-muted-foreground transition-colors duration-300 group-hover:text-primary" />
                </div>

                <div>
                  <h3 className="text-base font-semibold">{item.title}</h3>
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