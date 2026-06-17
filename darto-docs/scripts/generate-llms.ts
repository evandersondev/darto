/**
 * Generates the llms.txt / llms-full.txt files from the structured docs content.
 *
 * - llms.txt      → a curated index: project summary + grouped links to every
 *                   doc section, each with a one-line description.
 * - llms-full.txt → the entire documentation concatenated as plain Markdown,
 *                   so a model can ingest everything in a single fetch.
 *
 * Both are written to public/ so Vite serves them at the site root
 * (e.g. https://darto-docs.vercel.app/llms.txt).
 *
 * Run with: bun run docs:llms   (also wired into the build script).
 */
import { writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { getDocSections, type Block, type DocSection } from "../src/lib/docs-content";

const __dirname = dirname(fileURLToPath(import.meta.url));
const PUBLIC_DIR = resolve(__dirname, "../public");

const SITE_URL = "https://darto-docs.vercel.app";

// llms.txt is conventionally English; we render the English variant of the docs.
const sections = getDocSections("en");

const GROUP_LABELS: Record<DocSection["group"], string> = {
  start: "Getting Started",
  api: "API",
  helpers: "Helpers",
  middlewares: "Middlewares",
  plugins: "Official Plugins",
  advanced: "Advanced",
  migration: "Migration Guide",
};

const GROUP_ORDER: DocSection["group"][] = [
  "start",
  "api",
  "helpers",
  "middlewares",
  "plugins",
  "advanced",
  "migration",
];

const sectionUrl = (id: string) => `${SITE_URL}/docs?section=${id}`;

/** Collapse whitespace and trim a string to a single clean line. */
const oneLine = (s: string) => s.replace(/\s+/g, " ").trim();

/** Derive a one-line description for a section from its first paragraph. */
function sectionSummary(section: DocSection): string {
  const firstParagraph = section.blocks.find((b): b is Extract<Block, { kind: "p" }> => b.kind === "p");
  const text = firstParagraph ? oneLine(firstParagraph.text) : section.title;
  // Keep it to the first sentence, capped, so the index stays scannable.
  const firstSentence = text.split(/(?<=[.!?])\s/)[0] ?? text;
  return firstSentence.length > 160 ? `${firstSentence.slice(0, 157)}…` : firstSentence;
}

/** Render a single content block to Markdown for llms-full.txt. */
function blockToMarkdown(block: Block): string {
  switch (block.kind) {
    case "p":
      return oneLine(block.text);
    case "h3":
      return `### ${block.text}`;
    case "code": {
      // Code blocks without an explicit lang are Dart (matches the UI default).
      const lang = block.lang ?? "dart";
      const commentChar = lang === "yaml" || lang === "sh" ? "#" : "//";
      const head = block.filename ? `${commentChar} ${block.filename}\n` : "";
      return `\`\`\`${lang}\n${head}${block.code}\n\`\`\``;
    }
    case "ul":
      return block.items.map((i) => `- ${oneLine(i)}`).join("\n");
    case "table": {
      const header = `| ${block.headers.join(" | ")} |`;
      const divider = `| ${block.headers.map(() => "---").join(" | ")} |`;
      const rows = block.rows.map((r) => `| ${r.map((c) => oneLine(c)).join(" | ")} |`);
      return [header, divider, ...rows].join("\n");
    }
    case "note":
      return `> **Note:** ${oneLine(block.text)}`;
    case "callout": {
      const label = { tip: "Tip", warning: "Warning", success: "Success" }[block.variant];
      return `> **${label}:** ${oneLine(block.text)}`;
    }
    case "links":
      return block.links.map((l) => `- [${l.label}](${l.href})`).join("\n");
    case "ref":
      return `See: [${block.label}](${sectionUrl(block.to)})`;
  }
}

// ── llms.txt: curated index ──────────────────────────────────────────────────
function buildIndex(): string {
  const out: string[] = [];
  out.push("# Darto");
  out.push("");
  out.push(
    "> A minimal, fast web framework for Dart. Define routes, compose middleware, " +
      "and ship APIs — everything flows through one concept: Context. Inspired by " +
      "Express and Hono, built for pure Dart with zero JS bridges.",
  );
  out.push("");
  out.push(
    "Darto centers on three typedefs — Handler, Middleware, and Next. Handlers receive a " +
      "Context and return a Response; middleware receives a Context and a Next callback. " +
      "The framework ships an official ecosystem of plugins (auth, cache, env, jobs, logger, " +
      "mailer, OpenAPI, rate limiting, static files, testing, validation, view engines, and " +
      "WebSockets). The docs below cover the core API, helpers, middleware, plugins, advanced " +
      "topics, and migration guides.",
  );
  out.push("");

  for (const group of GROUP_ORDER) {
    const groupSections = sections.filter((s) => s.group === group);
    if (groupSections.length === 0) continue;
    out.push(`## ${GROUP_LABELS[group]}`);
    out.push("");
    for (const s of groupSections) {
      const summary = sectionSummary(s);
      // The description is optional; skip it when it would just echo the title.
      out.push(
        summary === s.title
          ? `- [${s.title}](${sectionUrl(s.id)})`
          : `- [${s.title}](${sectionUrl(s.id)}): ${summary}`,
      );
    }
    out.push("");
  }

  out.push("## Optional");
  out.push("");
  out.push(
    `- [Full documentation](${SITE_URL}/llms-full.txt): the entire Darto documentation ` +
      "concatenated into a single file.",
  );
  out.push(`- [GitHub repository](https://github.com/evandersondev/darto): source code and issues.`);
  out.push(`- [pub.dev package](https://pub.dev/packages/darto): published package.`);
  out.push("");

  return out.join("\n");
}

// ── llms-full.txt: entire documentation ──────────────────────────────────────
function buildFull(): string {
  const out: string[] = [];
  out.push("# Darto — Full Documentation");
  out.push("");
  out.push(
    "> A minimal, fast web framework for Dart. This file concatenates the entire Darto " +
      "documentation for ingestion by language models.",
  );
  out.push("");
  out.push(`Source: ${SITE_URL}`);
  out.push("");

  let currentGroup: DocSection["group"] | null = null;
  const ordered = GROUP_ORDER.flatMap((g) => sections.filter((s) => s.group === g));

  for (const s of ordered) {
    if (s.group !== currentGroup) {
      currentGroup = s.group;
      out.push(`\n---\n`);
      out.push(`# ${GROUP_LABELS[s.group]}`);
      out.push("");
    }
    out.push(`## ${s.title}`);
    out.push(`<!-- ${sectionUrl(s.id)} -->`);
    out.push("");
    for (const block of s.blocks) {
      out.push(blockToMarkdown(block));
      out.push("");
    }
  }

  return out.join("\n");
}

const index = buildIndex();
const full = buildFull();

writeFileSync(resolve(PUBLIC_DIR, "llms.txt"), index.trimEnd() + "\n");
writeFileSync(resolve(PUBLIC_DIR, "llms-full.txt"), full.trimEnd() + "\n");

console.log(
  `Generated llms.txt (${index.length} chars) and llms-full.txt (${full.length} chars) ` +
    `from ${sections.length} doc sections.`,
);
