import { Link, useRouterState } from "@tanstack/react-router";
import { Moon, Sun, Menu, X, Search, Coffee } from "lucide-react";
import { useEffect, useState } from "react";
import { Logo } from "./Logo";
import { useTheme } from "@/hooks/use-theme";
import { useI18n } from "@/lib/i18n-context";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

export function Navbar() {
  const { theme, toggle } = useTheme();
  const { lang, setLang, t } = useI18n();
  const pathname = useRouterState({ select: (s) => s.location.pathname });
  const [open, setOpen] = useState(false);
  const isMac = typeof navigator !== "undefined" && /Mac|iPod|iPhone|iPad/.test(navigator.platform);

  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === "k") {
        e.preventDefault();
        window.dispatchEvent(new CustomEvent("darto:focus-search"));
      }
    };
    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  }, []);

  const inDocs = pathname.startsWith("/docs");

  return (
    <header className="sticky top-0 z-50 w-full border-b border-border bg-background/85 backdrop-blur">
      <div className="container flex h-14 items-center justify-between">
        <div className="flex items-center gap-7">
          <Link to="/" aria-label="Darto home"><Logo /></Link>
          <nav className="hidden items-center gap-5 md:flex">
            <Link
              to="/docs"
              className={cn(
                "text-sm transition-colors hover:text-foreground",
                inDocs ? "text-foreground" : "text-muted-foreground"
              )}
            >
              {t.nav.docs}
            </Link>
            <a
              href="https://www.buymeacoffee.com/evandersondev"
              target="_blank"
              rel="noreferrer"
              className="inline-flex items-center gap-1.5 rounded-full border border-amber-400/40 bg-amber-400/10 px-3 py-1 text-xs font-medium text-amber-600 transition-colors hover:bg-amber-400/20 hover:text-amber-500 dark:text-amber-400 dark:hover:text-amber-300"
            >
              <Coffee className="h-3.5 w-3.5" />
              Buy me a coffee
            </a>
          </nav>
        </div>

        <div className="flex items-center gap-1.5">
          {inDocs && (
            <button
              onClick={() => window.dispatchEvent(new CustomEvent("darto:focus-search"))}
              className="hidden items-center gap-2 rounded-md border border-border bg-card px-2.5 py-1.5 text-xs text-muted-foreground transition-colors hover:bg-secondary md:flex"
              aria-label="Search docs"
            >
              <Search className="h-3.5 w-3.5" />
              <span>{t.docs.search}</span>
              <kbd className="ml-2 rounded border border-border bg-background px-1.5 py-0.5 font-mono text-[10px]">
                {isMac ? "⌘" : "Ctrl"}K
              </kbd>
            </button>
          )}

          <div className="hidden items-center rounded-md border border-border bg-card p-0.5 sm:flex">
            <button
              onClick={() => setLang("en")}
              className={cn(
                "rounded px-2 py-0.5 text-xs font-medium transition-colors",
                lang === "en" ? "bg-secondary text-foreground" : "text-muted-foreground hover:text-foreground"
              )}
            >EN</button>
            <button
              onClick={() => setLang("pt")}
              className={cn(
                "rounded px-2 py-0.5 text-xs font-medium transition-colors",
                lang === "pt" ? "bg-secondary text-foreground" : "text-muted-foreground hover:text-foreground"
              )}
            >PT</button>
          </div>

          <Button variant="ghost" size="icon" onClick={toggle} aria-label="Toggle theme" className="h-8 w-8">
            {theme === "dark" ? <Sun className="h-4 w-4" /> : <Moon className="h-4 w-4" />}
          </Button>

          <Button
            variant="ghost"
            size="icon"
            className="h-8 w-8 md:hidden"
            onClick={() => setOpen((o) => !o)}
            aria-label="Menu"
          >
            {open ? <X className="h-4 w-4" /> : <Menu className="h-4 w-4" />}
          </Button>
        </div>
      </div>

      {open && (
        <div className="border-t border-border bg-background md:hidden">
          <nav className="container flex flex-col gap-1 py-3">
            <Link to="/docs" onClick={() => setOpen(false)} className="rounded-md px-3 py-2 text-sm hover:bg-secondary">{t.nav.docs}</Link>
            <a
              href="https://www.buymeacoffee.com/evandersondev"
              target="_blank"
              rel="noreferrer"
              className="inline-flex items-center gap-2 rounded-md px-3 py-2 text-sm text-amber-600 hover:bg-amber-400/10 dark:text-amber-400"
            >
              <Coffee className="h-4 w-4" />
              Buy me a coffee
            </a>
          </nav>
        </div>
      )}
    </header>
  );
}