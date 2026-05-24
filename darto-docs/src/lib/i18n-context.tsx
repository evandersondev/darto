import { createContext, useContext, useEffect, useState, type ReactNode } from "react";
import { type Lang, translations, type Translations } from "@/lib/i18n";

interface Ctx {
  lang: Lang;
  setLang: (l: Lang) => void;
  t: Translations;
}

const I18nContext = createContext<Ctx | null>(null);

export function I18nProvider({ children }: { children: ReactNode }) {
  const [lang, setLangState] = useState<Lang>(() => {
    if (typeof window === "undefined") return "en";
    const saved = localStorage.getItem("darto-lang") as Lang | null;
    if (saved === "en" || saved === "pt") return saved;
    return navigator.language?.toLowerCase().startsWith("pt") ? "pt" : "en";
  });

  const setLang = (l: Lang) => {
    setLangState(l);
    localStorage.setItem("darto-lang", l);
    document.documentElement.lang = l === "pt" ? "pt-BR" : "en";
  };

  useEffect(() => {
    document.documentElement.lang = lang === "pt" ? "pt-BR" : "en";
  }, [lang]);

  return (
    <I18nContext.Provider value={{ lang, setLang, t: translations[lang] }}>
      {children}
    </I18nContext.Provider>
  );
}

export function useI18n() {
  const ctx = useContext(I18nContext);
  if (!ctx) throw new Error("useI18n must be used within I18nProvider");
  return ctx;
}