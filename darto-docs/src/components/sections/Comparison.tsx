import { useI18n } from "@/lib/i18n-context";

export function Comparison() {
  const { t } = useI18n();
  return (
    <section className="border-b border-border section-animate">
      <div className="container py-20 lg:py-28">
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="text-3xl font-semibold tracking-tight sm:text-4xl">{t.compare.title}</h2>
          <p className="mt-3 text-muted-foreground">{t.compare.subtitle}</p>
        </div>

        <div className="mx-auto mt-10 max-w-3xl overflow-hidden rounded-lg border border-border">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-border bg-secondary/60">
                {t.compare.headers.map((h, i) => (
                  <th
                    key={i}
                    className={`px-4 py-3 text-xs font-semibold uppercase tracking-wider text-muted-foreground ${i === 0 ? "text-left" : "text-center"}`}
                  >
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {t.compare.rows.map((row, i) => (
                <tr key={i} className="border-b border-border last:border-0">
                  {row.map((c, j) => (
                    <td
                      key={j}
                      className={`px-4 py-3 ${
                        j === 0 ? "text-left font-medium text-foreground" : "text-center text-foreground/85"
                      }`}
                    >
                      {c}
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <p className="mx-auto mt-6 max-w-3xl text-sm leading-relaxed text-muted-foreground">
          {t.compare.note}
        </p>
      </div>
    </section>
  );
}