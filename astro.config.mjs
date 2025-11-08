// @ts-check
import { defineConfig } from "astro/config";

import tailwindcss from "@tailwindcss/vite";
import { languages, defaultLanguage } from "./src/i18n/translations.ts";

// https://astro.build/config
export default defineConfig({
  i18n: {
    defaultLocale: defaultLanguage,
    locales: languages,
  },
  vite: {
    plugins: [tailwindcss()],
  },
});
