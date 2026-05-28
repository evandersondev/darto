import { useEffect, useState } from "react";
import { Check, Copy } from "lucide-react";
import { highlightDart, highlightSh, highlightYaml } from "@/lib/highlight";
import { cn } from "@/lib/utils";

interface CodeBlockProps {
  code: string;
  language?: "dart" | "yaml" | "sh" | "html";
  filename?: string;
  className?: string;
  showCopy?: boolean;
}

export function CodeBlock({
  code,
  language = "dart",
  filename,
  className,
  showCopy = true,
}: CodeBlockProps) {
  const [copied, setCopied] = useState(false);
  const [html, setHtml] = useState("");

  useEffect(() => {
    if (language === "dart") setHtml(highlightDart(code));
    else if (language === "sh") setHtml(highlightSh(code));
    else if (language === "yaml") setHtml(highlightYaml(code));
    else setHtml(code.replace(/&/g, "&amp;").replace(/</g, "&lt;"));
  }, [code, language]);

  const handleCopy = async () => {
    await navigator.clipboard.writeText(code);
    setCopied(true);
    setTimeout(() => setCopied(false), 1800);
  };

  return (
    <div
      className={cn(
        "group relative overflow-hidden rounded-lg border border-code-border bg-code text-code-foreground",
        className,
      )}
    >
      {(filename || language) && (
        <div className="flex items-center justify-between border-b border-code-border px-4 py-2">
          <span className="font-mono text-xs text-muted-foreground">{filename ?? language}</span>
          {showCopy && (
            <button
              onClick={handleCopy}
              className="inline-flex items-center gap-1.5 rounded-md px-2 py-1 text-xs text-muted-foreground transition-colors hover:bg-secondary hover:text-foreground"
              aria-label="Copy code"
            >
              {copied ? (
                <Check className="h-3.5 w-3.5 text-primary" />
              ) : (
                <Copy className="h-3.5 w-3.5" />
              )}
              {copied ? "Copied" : "Copy"}
            </button>
          )}
        </div>
      )}
      <pre className="overflow-x-auto p-4 font-mono text-[13px] leading-[1.7]">
        <code dangerouslySetInnerHTML={{ __html: html }} />
      </pre>
    </div>
  );
}
