export const translations = {
  "en-us": {
    home: "Dessintey Documentation",
  },
  "fr-fr": {
    home: "Documentation Dessintey",
  },
  "es-es": {
    home: "Documentación Dessintey",
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
  "es-es": {
    code: "es-es",
    name: "Español",
    url: "/es-es/",
  },
} as const;

// Explicit array of supported language codes
export const languages = ["en-us", "fr-fr", "es-es"];

// Default language
export const defaultLanguage = "en-us" as const;

export function getTranslation(lang: string) {
  return (
    translations[lang as keyof typeof translations] ||
    translations[defaultLanguage]
  );
}
