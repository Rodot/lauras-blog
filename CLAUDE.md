# CONTRIBUTION RULES

## Markdown style rules

- NO html in markdown files
- Image: on their own line, NO alt text
- Heading capitalization: Only the first letter of the heading and proper nouns are capitalized
- A paragraph text should be on a single line with no line breaks within it
- Use bulleted lists `-` for list of information or succession of short sentences, do NOT use paragraphs or numbered lists `1.`
- Always refer to sections using the format `(§5.1)`
- Use `*` for italics and bold instead of `_`

## Glossary

- Dessintey: company name

## Content Files locations

- Document metadata (no content) `./src/content/documents/en-us/document-name.md`
- Chapters metadata and content `./src/content/chapters/en-us/document-name/chapter-name.md`
- Images (linked using `@/assets...`) `./src/assets/content/document-name/image-name.png`
- Languages list (unique source of truth) `./src/i18n/translations.ts`
