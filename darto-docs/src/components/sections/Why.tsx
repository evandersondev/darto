import { useI18n } from "@/lib/i18n-context";

export function Why() {
  const { t } = useI18n();
  return (
    <section className="border-b border-border bg-secondary/40 section-animate">
      <div className="container py-20 lg:py-28">
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="text-3xl font-semibold tracking-tight sm:text-4xl">{t.why.title}</h2>
          <p className="mt-3 text-muted-foreground">{t.why.subtitle}</p>
        </div>
        <div className="mx-auto mt-12 grid gap-px overflow-hidden rounded-lg border border-border bg-border md:grid-cols-3">
          {t.why.items.map((item, i) => (
            <div key={i} className="bg-card p-6">
              <div className="mb-3 font-mono text-xs text-muted-foreground">0{i + 1}</div>
              <h3 className="text-base font-semibold">{item.title}</h3>
              <p className="mt-2 text-sm leading-relaxed text-muted-foreground">{item.desc}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}