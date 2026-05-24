import { Link } from "@tanstack/react-router";
import { Logo } from "./Logo";
import { useI18n } from "@/lib/i18n-context";

export function Footer() {
  const { t } = useI18n();
  return (
    <footer className="border-t border-border bg-background">
      <div className="container py-12">
        <div className="grid gap-10 md:grid-cols-4">
          <div className="md:col-span-2">
            <Logo />
            <p className="mt-3 max-w-sm text-sm text-muted-foreground">
              {t.footer.made}.
            </p>
          </div>
          <div>
            <h4 className="mb-3 text-xs font-semibold uppercase tracking-wider text-muted-foreground">Resources</h4>
            <ul className="space-y-2 text-sm">
              <li><Link to="/docs" className="text-foreground/80 hover:text-foreground">{t.nav.docs}</Link></li>
              <li><a href="https://github.com/evandersondev/darto" target="_blank" rel="noreferrer" className="text-foreground/80 hover:text-foreground">GitHub</a></li>
              <li><a href="https://buymeacoffee.com/evandersondev" target="_blank" rel="noreferrer" className="text-foreground/80 hover:text-foreground">Buy me a coffee</a></li>
            </ul>
          </div>
          <div>
            <h4 className="mb-3 text-xs font-semibold uppercase tracking-wider text-muted-foreground">Community</h4>
            <ul className="space-y-2 text-sm">
              <li><a href="https://github.com/evandersondev/darto/issues" target="_blank" rel="noreferrer" className="text-foreground/80 hover:text-foreground">Issues</a></li>
              <li><a href="https://pub.dev/packages/darto" target="_blank" rel="noreferrer" className="text-foreground/80 hover:text-foreground">pub.dev</a></li>
              <li><a href="https://github.com/evandersondev/darto/blob/main/LICENSE" target="_blank" rel="noreferrer" className="text-foreground/80 hover:text-foreground">License (MIT)</a></li>
            </ul>
          </div>
        </div>
        <div className="mt-10 flex flex-col items-center justify-between gap-3 border-t border-border pt-6 text-xs text-muted-foreground sm:flex-row">
          <p>© {new Date().getFullYear()} Darto. {t.footer.rights}</p>
          <p>MIT licensed</p>
        </div>
      </div>
    </footer>
  );
}