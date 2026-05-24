import { createFileRoute, useNavigate, useSearch } from "@tanstack/react-router";
import { useEffect, useMemo, useRef, useState } from "react";
import { Navbar } from "@/components/Navbar";
import { Footer } from "@/components/Footer";
import { CodeBlock } from "@/components/CodeBlock";
import { getDocSections, type DocSection, type Block } from "@/lib/docs-content";
import { useI18n } from "@/lib/i18n-context";
import { cn } from "@/lib/utils";
import {
  Sheet,
  SheetContent,
  SheetTrigger,
} from "@/components/ui/sheet";
import {
  Search,
  ArrowUp,
  Lightbulb,
  AlertTriangle,
  CheckCircle2,
  Menu,
  ChevronDown,
} from "lucide-react";

export const Route = createFileRoute("/docs")({
  head: () => ({
    meta: [
      { title: "Darto — Documentation" },
      { name: "description", content: "Routing, Context API, middleware, validation, WebSockets and more." },
    ],
  }),
  component: DocsPage,
});

function DocsPage() {
  const { t, lang } = useI18n();
  const navigate = useNavigate({ from: "/docs" });
  const searchParams = useSearch({ from: "/docs" }) as { q?: string };
  const query = searchParams.q ?? "";

  const sections = useMemo(() => getDocSections(lang), [lang]);
  const [activeSection, setActiveSection] = useState<string>(sections[2]?.id ?? sections[0]?.id ?? "");
  const [headingIds, setHeadingIds] = useState<string[]>([]);
  const [activeHeading, setActiveHeading] = useState<string>("");
  const contentRef = useRef<HTMLDivElement>(null);
  const [showSearch, setShowSearch] = useState(false);
  const [searchInput, setSearchInput] = useState(query);
  const [mobileSidebarOpen, setMobileSidebarOpen] = useState(false);

  // Scrollspy
  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        const visible = entries
          .filter((e) => e.isIntersecting)
          .sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top);
        if (visible.length > 0) {
          setActiveHeading(visible[0].target.id);
          const sid = visible[0].target.getAttribute("data-section");
          if (sid) setActiveSection(sid);
        }
      },
      { rootMargin: "-80px 0px -60% 0px", threshold: 1 }
    );

    const nodes = contentRef.current?.querySelectorAll("h3[id]") ?? [];
    nodes.forEach((n) => observer.observe(n));
    const ids: string[] = [];
    nodes.forEach((n) => ids.push(n.id));
    setHeadingIds(ids);

    return () => observer.disconnect();
  }, [sections, lang]);

  // Search keyboard shortcut
  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === "k") {
        e.preventDefault();
        setShowSearch(true);
      }
      if (e.key === "Escape") {
        setShowSearch(false);
        navigate({ search: (prev: { q?: string }) => ({ ...prev, q: undefined }) });
      }
    };
    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  }, [navigate]);

  useEffect(() => {
    if (showSearch) {
      setTimeout(() => document.getElementById("docs-search-input")?.focus(), 50);
    }
  }, [showSearch]);

  useEffect(() => {
    const handler = () => setShowSearch(true);
    window.addEventListener("darto:focus-search", handler);
    return () => window.removeEventListener("darto:focus-search", handler);
  }, []);

  const filteredSections = useMemo(() => {
    if (!searchInput.trim()) return sections;
    const q = searchInput.toLowerCase();
    return sections.filter((s) => {
      if (s.title.toLowerCase().includes(q)) return true;
      return s.blocks.some((b) => blockText(b).toLowerCase().includes(q));
    });
  }, [sections, searchInput]);

  const groupLabels: Record<string, string> = {
    start: t.docs.groups.start,
    core: t.docs.groups.core,
    validation: t.docs.groups.validation,
    advanced: t.docs.groups.advanced,
    reference: t.docs.groups.reference,
    migration: t.docs.groups.migration,
  };

  const grouped = useMemo(() => {
    const g: Record<string, DocSection[]> = {};
    for (const s of filteredSections) {
      if (!g[s.group]) g[s.group] = [];
      g[s.group].push(s);
    }
    return g;
  }, [filteredSections]);

  const allGroups = Object.keys(grouped);

  const activeTitle = sections.find((s) => s.id === activeSection)?.title ?? "";

  function navigateToSection(id: string) {
    setActiveSection(id);
    setMobileSidebarOpen(false);
    setTimeout(() => document.getElementById(id)?.scrollIntoView({ behavior: "smooth", block: "start" }), 50);
  }

  const [openGroup, setOpenGroup] = useState<string>("start");

  const SidebarContent = () => (
    <nav className="w-full">
      {allGroups.map((group) => {
        const isOpen = openGroup === group;
        return (
          <div key={group} className="mb-1">
            <button
              onClick={() => setOpenGroup(isOpen ? "" : group)}
              className="flex w-full items-center justify-between px-1 py-2 text-xs font-semibold uppercase tracking-wider text-muted-foreground transition-colors hover:text-foreground"
            >
              {groupLabels[group] ?? group}
              <ChevronDown className={cn("h-3.5 w-3.5 shrink-0 transition-transform duration-200", isOpen && "rotate-180")} />
            </button>
            {isOpen && (
              <ul className="mb-2 space-y-0.5">
                {grouped[group].map((s) => (
                  <li key={s.id}>
                    <button
                      onClick={() => navigateToSection(s.id)}
                      className={cn(
                        "w-full rounded-md px-3 py-1.5 text-left text-sm transition-colors",
                        activeSection === s.id
                          ? "bg-primary/10 font-medium text-primary"
                          : "text-muted-foreground hover:bg-secondary hover:text-foreground"
                      )}
                    >
                      {s.title}
                    </button>
                  </li>
                ))}
              </ul>
            )}
          </div>
        );
      })}
    </nav>
  );

  return (
    <>
      <Navbar />
      <div className="mx-auto w-full max-w-7xl">
        <div className="flex min-h-[calc(100vh-3.5rem)]">

          {/* Desktop sidebar */}
          <aside className="sticky top-14 hidden h-[calc(100vh-3.5rem)] w-64 shrink-0 overflow-y-auto border-r border-border bg-background px-4 py-6 lg:block">
            <SidebarContent />
          </aside>

          {/* Main content */}
          <main ref={contentRef} className="min-w-0 flex-1 px-4 py-8 sm:px-6 lg:px-12 lg:py-10">

            {/* Mobile top bar */}
            <div className="mb-6 flex items-center gap-3 lg:hidden">
              <Sheet open={mobileSidebarOpen} onOpenChange={setMobileSidebarOpen}>
                <SheetTrigger asChild>
                  <button
                    className="flex items-center gap-2 rounded-md border border-border bg-card px-3 py-1.5 text-sm text-muted-foreground transition-colors hover:bg-secondary"
                    aria-label="Open navigation"
                  >
                    <Menu className="h-4 w-4" />
                    <span className="max-w-45 truncate font-medium text-foreground">{activeTitle}</span>
                  </button>
                </SheetTrigger>
                <SheetContent side="left" className="w-72 overflow-y-auto px-4 py-6">
                  <SidebarContent />
                </SheetContent>
              </Sheet>

              <button
                onClick={() => setShowSearch(true)}
                className="flex items-center gap-2 rounded-md border border-border bg-card px-3 py-1.5 text-sm text-muted-foreground transition-colors hover:bg-secondary"
                aria-label="Search docs"
              >
                <Search className="h-4 w-4" />
              </button>
            </div>

            <div className="mx-auto max-w-3xl">
              <div className="mb-8">
                <span className="inline-flex items-center gap-2 rounded-full border border-border bg-card px-3 py-1 text-xs font-medium text-muted-foreground">
                  <span className="h-1.5 w-1.5 rounded-full bg-primary" />
                  {t.docs.badge}
                </span>
                <h1 className="mt-4 text-3xl font-semibold tracking-tight sm:text-4xl">{t.docs.title}</h1>
                <p className="mt-2 text-muted-foreground">{t.docs.subtitle}</p>
              </div>

              {filteredSections.length === 1 && searchInput.trim() ? (
                <p className="mb-4 text-sm text-muted-foreground">
                  {t.docs.results(filteredSections.length, searchInput)}
                </p>
              ) : null}

              {filteredSections.map((section) => (
                <section key={section.id} id={section.id} className="mb-14 scroll-mt-24">
                  <h2 className="text-xl font-semibold tracking-tight sm:text-2xl">{section.title}</h2>
                  <div className="mt-5 space-y-5">
                    {section.blocks.map((block, i) => (
                      <BlockRenderer key={`${section.id}-${i}`} block={block} sectionId={section.id} />
                    ))}
                  </div>
                </section>
              ))}

              {filteredSections.length === 1 && searchInput.trim() && filteredSections[0]!.id !== activeSection ? (
                <p className="mt-4 text-sm text-muted-foreground">{t.docs.noMatches}</p>
              ) : null}
            </div>
          </main>

          {/* On this page — desktop only */}
          <aside className="sticky top-14 hidden h-[calc(100vh-3.5rem)] w-56 shrink-0 overflow-y-auto border-l border-border px-5 py-10 xl:block">
            <p className="mb-3 text-xs font-semibold uppercase tracking-wider text-muted-foreground">
              {t.docs.onThisPage}
            </p>
            <ul className="space-y-1">
              {headingIds.map((id) => (
                <li key={id}>
                  <a
                    href={`#${id}`}
                    onClick={(e) => {
                      e.preventDefault();
                      document.getElementById(id)?.scrollIntoView({ behavior: "smooth", block: "start" });
                    }}
                    className={cn(
                      "block rounded-md px-2 py-1 text-sm transition-colors",
                      activeHeading === id
                        ? "font-medium text-primary"
                        : "text-muted-foreground hover:text-foreground"
                    )}
                  >
                    {headingTextFromId(id, sections)}
                  </a>
                </li>
              ))}
            </ul>
          </aside>
        </div>
      </div>

      {/* Search modal */}
      {showSearch && (
        <div
          className="fixed inset-0 z-50 flex items-start justify-center bg-black/40 pt-[15vh] backdrop-blur-sm"
          onClick={() => {
            setShowSearch(false);
            navigate({ search: (prev: { q?: string }) => ({ ...prev, q: undefined }) });
          }}
        >
          <div
            className="mx-4 w-full max-w-lg overflow-hidden rounded-xl border border-border bg-card shadow-2xl"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center gap-3 border-b border-border px-4 py-3">
              <Search className="h-4 w-4 text-muted-foreground" />
              <input
                id="docs-search-input"
                value={searchInput}
                onChange={(e) => {
                  setSearchInput(e.target.value);
                  navigate({ search: { q: e.target.value || undefined } });
                }}
                placeholder={t.docs.search}
                className="flex-1 bg-transparent text-sm text-foreground outline-none placeholder:text-muted-foreground"
              />
              <button
                onClick={() => {
                  setShowSearch(false);
                  navigate({ search: (prev: { q?: string }) => ({ ...prev, q: undefined }) });
                }}
                className="rounded-md border border-border px-1.5 py-0.5 text-xs text-muted-foreground"
              >
                Esc
              </button>
            </div>
            <div className="max-h-[50vh] overflow-y-auto px-2 py-2">
              {filteredSections.length === 1 ? (
                <div className="px-3 py-2 text-xs text-muted-foreground">
                  {t.docs.results(filteredSections.length, searchInput)}
                </div>
              ) : null}
              {filteredSections.map((s) => (
                <button
                  key={s.id}
                  onClick={() => {
                    setShowSearch(false);
                    setActiveSection(s.id);
                    setSearchInput("");
                    navigate({ search: (prev: { q?: string }) => ({ ...prev, q: undefined }) });
                    setTimeout(() => document.getElementById(s.id)?.scrollIntoView({ behavior: "smooth", block: "start" }), 50);
                  }}
                  className="flex w-full flex-col rounded-md px-3 py-2 text-left text-sm transition-colors hover:bg-secondary"
                >
                  <span className="font-medium text-foreground">{s.title}</span>
                  <span className="text-xs text-muted-foreground">{groupLabels[s.group] ?? s.group}</span>
                </button>
              ))}
              {filteredSections.length === 1 && searchInput.trim() ? (
                <div className="px-3 py-2 text-xs text-muted-foreground">{t.docs.noMatches}</div>
              ) : null}
            </div>
          </div>
        </div>
      )}

      <BackToTop />
      <Footer />
    </>
  );
}

function BlockRenderer({ block, sectionId }: { block: Block; sectionId: string }) {
  switch (block.kind) {
    case "p":
      return <p className="leading-relaxed text-foreground/90">{block.text}</p>;
    case "code":
      return (
        <CodeBlock
          code={block.code}
          language={block.lang ?? "dart"}
          filename={block.filename}
        />
      );
    case "h3":
      return (
        <h3
          id={block.id ?? ""}
          data-section={sectionId}
          className="mt-8 text-lg font-semibold tracking-tight scroll-mt-24"
        >
          {block.text}
        </h3>
      );
    case "ul":
      return (
        <ul className="ml-5 list-disc space-y-1.5 text-sm text-foreground/90">
          {block.items.map((item, i) => (
            <li key={i}>{item}</li>
          ))}
        </ul>
      );
    case "table":
      return (
        <div className="overflow-x-auto rounded-lg border border-border">
          <table className="w-full text-sm">
            <thead className="bg-secondary">
              <tr>
                {block.headers.map((h, i) => (
                  <th key={i} className="px-4 py-2 text-left font-semibold text-foreground">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {block.rows.map((row, ri) => (
                <tr key={ri} className="border-t border-border">
                  {row.map((cell, ci) => (
                    <td key={ci} className="px-4 py-2 text-foreground/80">{cell}</td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      );
    case "note":
      return (
        <div className="rounded-lg border border-border bg-secondary/60 px-4 py-3 text-sm text-foreground/80">
          {block.text}
        </div>
      );
    case "callout": {
      const icons = {
        tip: <Lightbulb className="h-4 w-4 text-primary" />,
        warning: <AlertTriangle className="h-4 w-4 text-amber-500" />,
        success: <CheckCircle2 className="h-4 w-4 text-emerald-500" />,
      };
      const borders = {
        tip: "border-primary/30 bg-primary/5",
        warning: "border-amber-500/30 bg-amber-500/5",
        success: "border-emerald-500/30 bg-emerald-500/5",
      };
      return (
        <div className={cn("flex items-start gap-3 rounded-lg border px-4 py-3 text-sm", borders[block.variant])}>
          {icons[block.variant]}
          <span className="text-foreground/90">{block.text}</span>
        </div>
      );
    }
    default:
      return null;
  }
}

function blockText(b: Block): string {
  switch (b.kind) {
    case "p": return b.text;
    case "code": return b.code;
    case "h3": return b.text;
    case "ul": return b.items.join(" ");
    case "table": return b.headers.join(" ") + " " + b.rows.flat().join(" ");
    case "note": return b.text;
    case "callout": return b.text;
    default: return "";
  }
}

function headingTextFromId(id: string, sections: DocSection[]): string {
  for (const s of sections) {
    for (const b of s.blocks) {
      if (b.kind === "h3" && b.id === id) return b.text;
    }
  }
  return id;
}

function BackToTop() {
  const [visible, setVisible] = useState(false);
  useEffect(() => {
    const onScroll = () => setVisible(window.scrollY > 600);
    window.addEventListener("scroll", onScroll);
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  return (
    <button
      onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}
      className={cn(
        "fixed bottom-6 right-6 z-40 flex h-10 w-10 items-center justify-center rounded-full border border-border bg-card shadow-lg transition-all hover:bg-secondary",
        visible ? "translate-y-0 opacity-100" : "translate-y-6 opacity-0 pointer-events-none"
      )}
      aria-label="Back to top"
    >
      <ArrowUp className="h-4 w-4" />
    </button>
  );
}
