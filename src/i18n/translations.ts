export const translations = {
  "en-us": {
    home: "Laura's Blog",
  },
  "fr-fr": {
    home: "Le blog de Laura",
  },
} as const;

export const languageMetadata = {
  "en-us": {
    code: "en-us",
    name: "English",
    url: "/en-us/",
  },
  "fr-fr": {
    code: "fr-fr",
    name: "Français",
    url: "/fr-fr/",
  },
} as const;

// Explicit array of supported language codes
export const languages = ["en-us", "fr-fr"];

// Default language
export const defaultLanguage = "en-us" as const;

export function getTranslation(lang: string) {
  return (
    translations[lang as keyof typeof translations] ||
    translations[defaultLanguage]
  );
}
