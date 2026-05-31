import { CodeBlock } from "@/components/CodeBlock";
import { Footer } from "@/components/Footer";
import { Navbar } from "@/components/Navbar";
import { Sheet, SheetContent, SheetTrigger } from "@/components/ui/sheet";
import { getDocSections, type Block, type DocSection } from "@/lib/docs-content";
import { useI18n } from "@/lib/i18n-context";
import { cn } from "@/lib/utils";
import { createFileRoute, Link, useNavigate, useSearch } from "@tanstack/react-router";
import {
  AlertTriangle,
  ArrowUp,
  CheckCircle2,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  ExternalLink,
  Lightbulb,
  Menu,
  Search,
} from "lucide-react";
import { useEffect, useMemo, useRef, useState, type RefObject } from "react";

type DocsSearch = { section?: string; q?: string };

export const Route = createFileRoute("/docs")({
  validateSearch: (search: Record<string, unknown>): DocsSearch => ({
    section: typeof search.section === "string" ? search.section : undefined,
    q: typeof search.q === "string" ? search.q : undefined,
  }),
  head: () => ({
    meta: [
      { title: "Darto — Documentation" },
      {
        name: "description",
        content: "Routing, Context API, middleware, validation, WebSockets and more.",
      },
    ],
  }),
  component: DocsPage,
});

function DocsPage() {
  const { t, lang } = useI18n();
  const navigate = useNavigate({ from: "/docs" });
  const searchParams = useSearch({ from: "/docs" }) as DocsSearch;
  const query = searchParams.q ?? "";

  const sections = useMemo(() => getDocSections(lang), [lang]);

  // The active section is derived from the URL (?section=…); falls back to the
  // first section. URL is the single source of truth → back/forward just work.
  const activeIndex = useMemo(() => {
    const i = sections.findIndex((s) => s.id === searchParams.section);
    return i === -1 ? 0 : i;
  }, [sections, searchParams.section]);
  const active = sections[activeIndex]!;
  const activeSection = active.id;
  const prevSection = activeIndex > 0 ? sections[activeIndex - 1] : null;
  const nextSection = activeIndex < sections.length - 1 ? sections[activeIndex + 1] : null;

  const headings = useMemo(
    () =>
      active.blocks
        .filter((b): b is Extract<Block, { kind: "h3" }> => b.kind === "h3" && !!b.id)
        .map((b) => ({ id: b.id!, text: b.text })),
    [active],
  );
  // "On this page" always shows at least the section title (so it never hides).
  const tocItems = headings.length > 0 ? headings : [{ id: active.id, text: active.title }];

  const [activeHeading, setActiveHeading] = useState<string>("");
  const contentRef = useRef<HTMLDivElement>(null);
  const scrollRef = useRef<HTMLDivElement>(null); // the content scroll container
  const [showSearch, setShowSearch] = useState(false);
  const [searchInput, setSearchInput] = useState(query);
  const [mobileSidebarOpen, setMobileSidebarOpen] = useState(false);

  // Reset the content scroll to the top on each section change.
  useEffect(() => {
    scrollRef.current?.scrollTo({ top: 0 });
    setActiveHeading("");
  }, [activeSection]);

  // Scrollspy over the active section's headings, within the content container.
  useEffect(() => {
    const root = scrollRef.current;
    const observer = new IntersectionObserver(
      (entries) => {
        const visible = entries
          .filter((e) => e.isIntersecting)
          .sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top);
        if (visible.length > 0) setActiveHeading(visible[0].target.id);
      },
      { root, rootMargin: "0px 0px -70% 0px", threshold: 1 },
    );
    const nodes = contentRef.current?.querySelectorAll("h3[id]") ?? [];
    nodes.forEach((n) => observer.observe(n));
    return () => observer.disconnect();
  }, [activeSection, lang]);

  // Search keyboard shortcut
  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === "k") {
        e.preventDefault();
        setShowSearch(true);
      }
      if (e.key === "Escape") setShowSearch(false);
    };
    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  }, []);

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

  const groupLabels: Record<string, string> = {
    start: t.docs.groups.start,
    api: t.docs.groups.api,
    helpers: t.docs.groups.helpers,
    middlewares: t.docs.groups.middlewares,
    plugins: t.docs.groups.plugins,
    advanced: t.docs.groups.advanced,
    migration: t.docs.groups.migration,
  };

  // Explicit sidebar order — independent of the section declaration order
  // in docs-content.ts.  Unknown groups (none expected) fall to the end.
  const GROUP_ORDER = [
    "start",
    "api",
    "helpers",
    "middlewares",
    "plugins",
    "advanced",
    "migration",
  ];

  const grouped = useMemo(() => {
    const g: Record<string, DocSection[]> = {};
    for (const s of sections) {
      (g[s.group] ??= []).push(s);
    }
    return g;
  }, [sections]);
  const allGroups = [
    ...GROUP_ORDER.filter((k) => grouped[k]),
    ...Object.keys(grouped).filter((k) => !GROUP_ORDER.includes(k)),
  ];

  // Search results (modal) — full-text across sections.
  const searchResults = useMemo(() => {
    const q = searchInput.trim().toLowerCase();
    if (!q) return sections;
    return sections.filter(
      (s) =>
        s.title.toLowerCase().includes(q) ||
        s.blocks.some((b) => blockText(b).toLowerCase().includes(q)),
    );
  }, [sections, searchInput]);

  function goToSection(id: string) {
    setMobileSidebarOpen(false);
    setShowSearch(false);
    navigate({ search: (prev: DocsSearch) => ({ ...prev, section: id, q: undefined }) });
  }

  // Keep the active section's group expanded.
  const [openGroup, setOpenGroup] = useState<string>(active.group);
  useEffect(() => setOpenGroup(active.group), [active.group]);

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
              <ChevronDown
                className={cn(
                  "h-3.5 w-3.5 shrink-0 transition-transform duration-200",
                  isOpen && "rotate-180",
                )}
              />
            </button>
            {isOpen && (
              <ul className="mb-2 space-y-0.5">
                {grouped[group].map((s) => (
                  <li key={s.id}>
                    <button
                      onClick={() => goToSection(s.id)}
                      className={cn(
                        "w-full rounded-md px-3 py-1.5 text-left text-sm transition-colors",
                        activeSection === s.id
                          ? "bg-primary/10 font-medium text-primary"
                          : "text-muted-foreground hover:bg-secondary hover:text-foreground",
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
      <div className="mx-auto flex h-[calc(100vh-3.5rem)] w-full max-w-7xl">
        {/* Desktop sidebar — independent scroll */}
        <aside className="hidden w-64 shrink-0 overflow-y-auto border-r border-border bg-background px-4 py-6 lg:block">
          <SidebarContent />
        </aside>

        {/* Main content — independent scroll */}
        <main ref={scrollRef} className="flex-1 p-0 overflow-y-auto">
          <div className=" py-8 lg:py-10">
            {/* Mobile top bar */}
            <div className="mb-6 px-4 sm:px-6 lg:px-12 flex items-center gap-3 lg:hidden">
              <Sheet open={mobileSidebarOpen} onOpenChange={setMobileSidebarOpen}>
                <SheetTrigger asChild>
                  <button
                    className="flex items-center gap-2 rounded-md border border-border bg-card px-3 py-1.5 text-sm text-muted-foreground transition-colors hover:bg-secondary"
                    aria-label="Open navigation"
                  >
                    <Menu className="h-4 w-4" />
                    <span className="max-w-45 truncate font-medium text-foreground">
                      {active.title}
                    </span>
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

            <div ref={contentRef} className="mx-auto max-w-3xl ">
              <div className="mb-8 px-4 sm:px-6 lg:px-12">
                <span className="text-xs font-semibold uppercase tracking-wider text-primary">
                  {groupLabels[active.group] ?? active.group}
                </span>
                <h1
                  id={active.id}
                  className="mt-2 scroll-mt-6 text-3xl font-semibold tracking-tight sm:text-4xl"
                >
                  {active.title}
                </h1>
              </div>

              <div className="space-y-5 px-4 sm:px-6 lg:px-12">
                {active.blocks.map((block, i) => (
                  <BlockRenderer key={`${active.id}-${i}`} block={block} sectionId={active.id} />
                ))}
              </div>

              {/* Prev / Next — equal-width links */}
              <nav className="mt-14 grid grid-cols-2 gap-4 px-4 sm:px-6 lg:px-12 border-t border-border pt-6">
                {prevSection ? (
                  <Link
                    to="/docs"
                    search={(prev) => ({ ...prev, section: prevSection.id, q: undefined })}
                    className="group flex h-full w-full flex-col items-start rounded-lg border border-border px-4 py-3 text-left transition-colors hover:border-primary/40 hover:bg-secondary"
                  >
                    <span className="text-xs text-muted-foreground">{t.docs.previous}</span>
                    <span className="mt-1 flex items-center gap-1 font-medium text-foreground">
                      <ChevronLeft className="h-4 w-4 shrink-0 text-muted-foreground transition-transform group-hover:-translate-x-0.5" />
                      {prevSection.title}
                    </span>
                  </Link>
                ) : (
                  <span />
                )}
                {nextSection ? (
                  <Link
                    to="/docs"
                    search={(prev) => ({ ...prev, section: nextSection.id, q: undefined })}
                    className="group flex h-full w-full flex-col items-end rounded-lg border border-border px-4 py-3 text-right transition-colors hover:border-primary/40 hover:bg-secondary"
                  >
                    <span className="text-xs text-muted-foreground">{t.docs.next}</span>
                    <span className="mt-1 flex items-center gap-1 font-medium text-foreground">
                      {nextSection.title}
                      <ChevronRight className="h-4 w-4 shrink-0 text-muted-foreground transition-transform group-hover:translate-x-0.5" />
                    </span>
                  </Link>
                ) : (
                  <span />
                )}
              </nav>
            </div>
          </div>
          <Footer />
        </main>

        {/* On this page — independent scroll, always visible */}
        <aside className="hidden w-56 shrink-0 overflow-y-auto border-l border-border px-5 py-10 xl:block">
          <p className="mb-3 text-xs font-semibold uppercase tracking-wider text-muted-foreground">
            {t.docs.onThisPage}
          </p>
          <ul className="space-y-1">
            {tocItems.map((h, i) => (
              <li key={h.id}>
                <a
                  href={`#${h.id}`}
                  onClick={(e) => {
                    e.preventDefault();
                    document
                      .getElementById(h.id)
                      ?.scrollIntoView({ behavior: "smooth", block: "start" });
                  }}
                  className={cn(
                    "block rounded-md px-2 py-1 text-sm transition-colors",
                    activeHeading === h.id || (activeHeading === "" && i === 0)
                      ? "font-medium text-primary"
                      : "text-muted-foreground hover:text-foreground",
                  )}
                >
                  {h.text}
                </a>
              </li>
            ))}
          </ul>
        </aside>
      </div>

      {/* Search modal */}
      {showSearch && (
        <div
          className="fixed inset-0 z-50 flex items-start justify-center bg-black/40 pt-[15vh] backdrop-blur-sm"
          onClick={() => setShowSearch(false)}
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
                onChange={(e) => setSearchInput(e.target.value)}
                placeholder={t.docs.search}
                className="flex-1 bg-transparent text-sm text-foreground outline-none placeholder:text-muted-foreground"
              />
              <button
                onClick={() => setShowSearch(false)}
                className="rounded-md border border-border px-1.5 py-0.5 text-xs text-muted-foreground"
              >
                Esc
              </button>
            </div>
            <div className="max-h-[50vh] overflow-y-auto px-2 py-2">
              {searchInput.trim() ? (
                <div className="px-3 py-2 text-xs text-muted-foreground">
                  {t.docs.results(searchResults.length, searchInput)}
                </div>
              ) : null}
              {searchResults.map((s) => (
                <button
                  key={s.id}
                  onClick={() => {
                    goToSection(s.id);
                    setSearchInput("");
                  }}
                  className="flex w-full flex-col rounded-md px-3 py-2 text-left text-sm transition-colors hover:bg-secondary"
                >
                  <span className="font-medium text-foreground">{s.title}</span>
                  <span className="text-xs text-muted-foreground">
                    {groupLabels[s.group] ?? s.group}
                  </span>
                </button>
              ))}
              {searchResults.length === 0 ? (
                <div className="px-3 py-2 text-xs text-muted-foreground">{t.docs.noMatches}</div>
              ) : null}
            </div>
          </div>
        </div>
      )}

      <BackToTop scrollRef={scrollRef} />
    </>
  );
}

function BlockRenderer({ block, sectionId }: { block: Block; sectionId: string }) {
  switch (block.kind) {
    case "p":
      return <p className="leading-relaxed text-foreground/90">{block.text}</p>;
    case "code":
      return (
        <CodeBlock code={block.code} language={block.lang ?? "dart"} filename={block.filename} />
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
    case "ref":
      return (
        <Link
          to="/docs"
          search={(prev) => ({ ...prev, section: block.to, q: undefined })}
          className="inline-flex items-center gap-1.5 rounded-lg border border-primary/30 bg-primary/5 px-4 py-2.5 text-sm font-medium text-primary transition-colors hover:bg-primary/10"
        >
          {block.label}
          <ChevronRight className="h-4 w-4" />
        </Link>
      );
    case "links":
      return (
        <div className="flex flex-wrap gap-2">
          {block.links.map((l, i) => (
            <a
              key={i}
              href={l.href}
              target="_blank"
              rel="noreferrer"
              className="inline-flex items-center gap-1.5 rounded-md border border-border bg-card px-3 py-1.5 text-sm font-medium text-foreground transition-colors hover:border-primary/40 hover:bg-secondary"
            >
              {l.label}
              <ExternalLink className="h-3.5 w-3.5 text-muted-foreground" />
            </a>
          ))}
        </div>
      );
    case "table":
      return (
        <div className="overflow-x-auto rounded-lg border border-border">
          <table className="w-full text-sm">
            <thead className="bg-secondary">
              <tr>
                {block.headers.map((h, i) => (
                  <th key={i} className="px-4 py-2 text-left font-semibold text-foreground">
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {block.rows.map((row, ri) => (
                <tr key={ri} className="border-t border-border">
                  {row.map((cell, ci) => (
                    <td key={ci} className="px-4 py-2 text-foreground/80">
                      {cell}
                    </td>
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
        <div
          className={cn(
            "flex items-start gap-3 rounded-lg border px-4 py-3 text-sm",
            borders[block.variant],
          )}
        >
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
    case "p":
      return b.text;
    case "code":
      return b.code;
    case "h3":
      return b.text;
    case "ul":
      return b.items.join(" ");
    case "table":
      return b.headers.join(" ") + " " + b.rows.flat().join(" ");
    case "note":
      return b.text;
    case "callout":
      return b.text;
    case "links":
      return b.links.map((l) => `${l.label} ${l.href}`).join(" ");
    case "ref":
      return b.label;
    default:
      return "";
  }
}

function BackToTop({ scrollRef }: { scrollRef: RefObject<HTMLDivElement | null> }) {
  const [visible, setVisible] = useState(false);
  useEffect(() => {
    const el = scrollRef.current;
    if (!el) return;
    const onScroll = () => setVisible(el.scrollTop > 600);
    el.addEventListener("scroll", onScroll);
    return () => el.removeEventListener("scroll", onScroll);
  }, [scrollRef]);

  return (
    <button
      onClick={() => scrollRef.current?.scrollTo({ top: 0, behavior: "smooth" })}
      className={cn(
        "fixed bottom-6 right-6 z-40 flex h-10 w-10 items-center justify-center rounded-full border border-border bg-card shadow-lg transition-all hover:bg-secondary",
        visible ? "translate-y-0 opacity-100" : "translate-y-6 opacity-0 pointer-events-none",
      )}
      aria-label="Back to top"
    >
      <ArrowUp className="h-4 w-4" />
    </button>
  );
}
