import { useState } from "react";
import { CodeBlock } from "@/components/CodeBlock";
import { useI18n } from "@/lib/i18n-context";
import { cn } from "@/lib/utils";

type Tab = "api" | "auth" | "upload";

export function RealWorld() {
  const { t } = useI18n();
  const [tab, setTab] = useState<Tab>("api");

  const tabs: { key: Tab; label: string }[] = [
    { key: "api", label: t.realWorld.tabs.api },
    { key: "auth", label: t.realWorld.tabs.auth },
    { key: "upload", label: t.realWorld.tabs.upload },
  ];

  return (
    <section className="border-b border-border bg-secondary/40 section-animate">
      <div className="container py-20 lg:py-28">
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="text-3xl font-semibold tracking-tight sm:text-4xl">{t.realWorld.title}</h2>
          <p className="mt-3 text-muted-foreground">{t.realWorld.subtitle}</p>
        </div>

        <div className="mx-auto mt-10 max-w-3xl">
          <div className="mb-4 flex flex-wrap items-center gap-1 border-b border-border">
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
          <CodeBlock code={t.realWorld.samples[tab]} filename={`${tab}.dart`} />
        </div>
      </div>
    </section>
  );
}